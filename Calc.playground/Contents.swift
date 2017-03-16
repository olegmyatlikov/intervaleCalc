import Foundation


// ----- Чтение файла и запись содержимого в массив строк

class File {
    
    var path: String
    var content: String {
        do {
            return try String(contentsOfFile: path, encoding: String.Encoding.utf8)
        } catch {
            print("Файл \(path) не найден или у вас недостаточно прав для его чтения!");
            return ""
        }
    }
    
    func filesContentInArray() -> Array<String> {
        let lines = content.components(separatedBy: "\n")  // строку contents записываем в массив строк разделяя \n
        return lines
    }
    
    init (path: String) {
        self.path = path
    }
    
}


// ----- Запись в файла результатов вычислений. Добавляем в String метод записи в файл, фактичеси просто добавили в него обработчик ошибок

extension String {
    
    func writeInFile(path: String) {
        do {
            try self.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            print("Запись в файл \(path) прошла успешно")
        } catch {
            print("Не достаточно прав для создания (записи) файла!");
        }
    }
    
}


// ----- Сами мозги калькулятора

class CalculatorBrains {
    
    var result = ""
    var taskWithResult = ""
    
    // ----- Объявление возможных операций c приоритетами
    
    enum Operations {
        case Brackets(Int)
        case Constants(Double, Int)
        case UnaryOperations(((Double) -> Double), Int)
        case BinaryOperations(((Double, Double) -> Double), Int)
    }
    
    private let operationsWhithPrecedency : [String: Operations] = [
        "(" : Operations.Brackets(5),
        ")" : Operations.Brackets(5),
        "π" : Operations.Constants(M_PI, 4),
        "e" : Operations.Constants(M_E, 4),
        "sin" : Operations.UnaryOperations({sin($0 * M_PI/180)}, 3), // умножаю на ПИ и делю на 180, чтобы считать в градусах
        "cos" : Operations.UnaryOperations({cos($0 * M_PI/180)}, 3),
        "√" : Operations.UnaryOperations(sqrt, 2),
        "^" : Operations.BinaryOperations({pow($0, $1)}, 2),
        "*" : Operations.BinaryOperations({$0 * $1}, 1),
        "/" : Operations.BinaryOperations({$0 / $1}, 1),
        "+" : Operations.BinaryOperations({$0 + $1}, 0),
        "-" : Operations.BinaryOperations({$0 - $1}, 0)
    ]
    
    
    // ----- Парсинг математического выражения из строки в массив для удобства работы
    
    private func stringToArray (str: String) -> [String] {
        
        var resultArray = [String]()
        var middleOfNumber = false
        
        for i in str.characters {
            
            switch (String(i), middleOfNumber) {
            case (" ", _): middleOfNumber = false   // игнорируем все пробелы
            case (let i, _) where (operationsWhithPrecedency.index(forKey: i) != nil):   // если оператор (+ - / * ^)
                resultArray.append(String(i))
                middleOfNumber = false
            case (_, true) where (operationsWhithPrecedency.index(forKey: resultArray[resultArray.endIndex - 1]) != nil):    // (если предыдуещее значение - sin или cos)
                resultArray.append(String(i))
                middleOfNumber = true
            case (_, true):     // если цифра еще не закончена
                resultArray[resultArray.endIndex - 1] =  resultArray[resultArray.endIndex - 1] + String(i)
            case (_, false):    // если цифра завершена
                resultArray.append(String(i))
                middleOfNumber = true
            }
            
        }
        
        return resultArray
    }
    
    
    // ----- Алгаритм избавления от скобок - записываем в масив выражения в скобках -> считаем -> возвращаем в массив резульат -> опять ищем скобки -> пока не избавимся от всех скобок
    
    private func openBrackets (array: Array<String>) -> Array<String> {
        
        var resultArray = array
        var accumArray = [String]()
        var arrayHaveBrackets: Bool
        var bracketPosition = (start: 0, end: 0)
        
        repeat {
            
            arrayHaveBrackets = false
            
            search: for i in 0..<resultArray.count {
                
                switch resultArray[i] {
                case "(":
                    arrayHaveBrackets = true
                    bracketPosition.start = i
                    accumArray = []
                case ")":
                    bracketPosition.end = i
                    accumArray.removeFirst()
                    break search
                default:
                    break
                }
                
                if arrayHaveBrackets { accumArray.append(resultArray[i]) }
                
            }
            
            if arrayHaveBrackets {
                if bracketPosition.end < bracketPosition.start { return ["Не верно расставлены скобки!"]}
                resultArray[bracketPosition.start...bracketPosition.end] = [mathArrayWhithPrecedency(array: accumArray)]
            }
            
        } while arrayHaveBrackets
        
        return resultArray
    }
    
    
    // ----- Расчет массива с учетом приоритета операций.
    
    private func mathArrayWhithPrecedency (array: Array<String>) -> String {
        
        var calcArray = array
        
        for i in 0...5 { // ?5
            
            var j = 0
            let precedency = 5 - i
            var forDelete = [Int]() // это будет массив номеров позиций, которые мы уже посчитали
            
            stop: for value in 0..<calcArray.count {
                
                j = (calcArray.count - 1)  - value // делаю правую ассоциативность, т.е. выражение будет считать справа налево (это для того, чтобы правильно считать степень в степени)
                
                if let operation = operationsWhithPrecedency[calcArray[j]] {
                    switch operation {
                    case .Brackets(5):
                        calcArray = openBrackets(array: calcArray)
                        break stop
                    case .Constants(let value, precedency):
                        calcArray[j] = String(value)
                    case .UnaryOperations(let function, precedency):
                        //if j+1 <= calcArray.count { return "Ошибка расчета" }
                        if let value = Double(calcArray[j+1]) {
                            calcArray[j] = String(function(value))
                            forDelete.append(j+1)
                        } else {return "Ошибка расчета"}
                    case .BinaryOperations(let function, precedency):
                        //if (calcArray.count < 1) || (j+1 <= calcArray.count) { return "Ошибка расчета" }
                        if let firstValue = Double(calcArray[j-1]), let secondValue = Double(calcArray[j+1]) {
                            calcArray[j-1] = String(function(firstValue, secondValue))
                            forDelete.append(j)
                            forDelete.append(j+1)
                        } else {return "Ошибка расчета"}
                    default: break
                    }
                }
                
            }
            
            // удаляем уже просчитаные элементы массива
            for i in forDelete.sorted(by: {$0 > $1}) {  // сортируем для того, что бы не попытаться удалить элемент под номером, которого уже нет в массиве
                calcArray.remove(at: i)
            }
            forDelete.removeAll()
            
        }
        
        //  если в массиве остался один элемент значит ответ получен
        
        return calcArray.count == 1 ? calcArray[0] : "Ошибка расчета"
        
    }
    
    
    // ----- Основной рассчет. Строку в массив и считаем с помощью метода mathArrayWhithPrecedency. + Форматируем результат и обрабатываем некоторые ошибки
    
    func math (task: String) {
        
        let taskArray = stringToArray(str: task)
        if task != "" {
            result = mathArrayWhithPrecedency(array: taskArray)
            
            switch result {
            case "inf", "-inf":
                result = "На ноль делить нельзя"
            case "nan":
                result = "Нарушены правила математики"
            case _ where Double(result) != nil:
                let number = Double(result)!
                // Не знаю, как округление красивее записать. Работает, как надо, но выглядит награмажденно
                result = String(number.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", number) : String(round(100000*number)/100000))
            default:
                break
            }
            
            taskWithResult = task + " = " + result + "\n"
        } else {
            result = ""
            taskWithResult = "\n"
        }
        
    }
    
    
}



// ----- Тут собственно мы читаем, считаем и записываем :)

var answer = ""
 
let file1 = File(path: "/Users/imac501/Desktop/IntervaleCalc/input_1.txt")
let file2 = File(path: "/Users/imac501/Desktop/IntervaleCalc/input_2.txt")
let file3 = File(path: "/Users/imac501/Desktop/IntervaleCalc/input_3.txt")

 
let calculator = CalculatorBrains()
 
let arrayOfFiles = [file1, file2, file3]

    var filesNumber = 0

 for file in arrayOfFiles {
    
    filesNumber += 1
    answer = ""
 
    var filesLines = file.filesContentInArray()
 
    for line in filesLines {
        calculator.math(task: line)
        answer = answer + calculator.taskWithResult
    }

    answer.writeInFile(path: "/Users/imac501/Desktop/IntervaleCalc/output_\(filesNumber).txt")
    
 }






















