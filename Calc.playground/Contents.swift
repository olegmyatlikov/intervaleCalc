import Foundation


// ----- Чтение файла и запись содержимого в массив строк

func readFile(path: String) -> Array<String> {
    
    do {
        let contents:NSString = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)    // пробуем записать содержимое файла в строку
        let lines: [String] =  NSString(string: contents).components(separatedBy: .newlines)    // строку contents записываем в массив строк разделяя \n
        return lines
    } catch {
        print("Файл \(path) не найден или у вас недостаточно прав для его чтения!");
        return [String]()
    }
    
}

var arrayOfStringInput = readFile(path: "/Users/oleg/Desktop/IntervaleCalc/input.txt")


// ----- Запись в файла результатов вычислений

func writeResultInFile(path: String, result: String) {
    
    do {
        try result.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
        print("Запись в файл \(path) прошла успешно")
    } catch {
        print("Не достаточно прав для создания (записи) файла!");
    }
    
}

//writeResultInFile(path: "/Users/oleg2/Desktop/IntervaleCalc/output.txt", result: "Hello, world")


// ----- Объявление возможных операций c приоритетами

enum Operations {
    case Brackets(Int)
    case Constants(Double, Int)
    case UnaryOperations(((Double) -> Double), Int)
    case BinaryOperations(((Double, Double) -> Double), Int)
}

let operationsWhithPrecedency : [String: Operations] = [
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


// ----- Преобразование строки математического выражения в массив для дальнейшего парсинга (потому что swift плохо работает со строками)

func stringToArray (str: String) -> [String] {
    
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


// ----- Алгаритм избавления от скобок - записываем в масив выражения в скобках -> считаем -> возвращаем в массив резульат -> опять ищем скобки -> и т.д.

func openBrackets (array: Array<String>) -> Array<String> {
    
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


// ----- Расчет массива с учетом приоритета операций

func mathArrayWhithPrecedency (array: Array<String>) -> String {
    
    var calcArray = array
    
    for i in 0...4 {
        
        let precedency = 4 - i
        var forDelete = [Int]() // это будет массив номеров значений, которые нужно удалить перед следующей итерацией
        
        stop: for j in 0..<calcArray.count {
            
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
                        calcArray[j+1] = String(function(value))
                        forDelete.append(j)
                    } else {return "Ошибка расчета"}
                case .BinaryOperations(let function, precedency):
                    //if (calcArray.count < 1) || (j+1 <= calcArray.count) { return "Ошибка расчета" }
                    if let firstValue = Double(calcArray[j-1]), let secondValue = Double(calcArray[j+1]) {
                        calcArray[j+1] = String(function(firstValue, secondValue))
                        forDelete.append(j)
                        forDelete.append(j-1)
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
    
    //  если в массиве остался один элемент округляем и выводим его
    if calcArray.count == 1 {
        if let result = Double(calcArray[0]) {
            return String(round(100000*result)/100000) // округление до 5 знаков после запятой
        }
    }
    
    return "Ошибка расчета"
    
}

// Основной рассчет

func math (array: inout Array<String>) {
    
    var stringForOutputFile = ""
    
    for i in array {
        
        array = stringToArray(str: i)
        stringForOutputFile = stringForOutputFile + "\(i) = \(mathArrayWhithPrecedency(array: array)) \n"
        
    }
    
    writeResultInFile(path: "/Users/oleg/Desktop/IntervaleCalc/output.txt", result: stringForOutputFile)
    
    
}


math(array: &arrayOfStringInput)




















