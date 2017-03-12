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
 
//let stringToArray = readFile(path: "/Users/oleg/Desktop/IntervaleCalc/input.txt")


// ----- Запись в файла результатов вычислений

func writeResultInFile(path: String, result: String) {

    do {
        try result.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
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
    "sin" : Operations.UnaryOperations(sin, 3),
    "cos" : Operations.UnaryOperations(cos, 3),
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
        case (_, true) where (operationsWhithPrecedency.index(forKey: resultArray[resultArray.endIndex - 1]) != nil):    // (если предыдуещее значение - sin cos tg)
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

let stringA = "sin 0.12 +23.3*((2+3)/cos35.5)"

var array = stringToArray(str: stringA)
var smallArray = [String]()



// var arrayOne = ["cos", "π", "+", "9", "-", "4", "^", "2"] ТЕСТ МАССИВ - УДАЛИТЬ



 
// ----- Расчет массива с учетом приоритета операций

func mathArray (array: inout Array<String>) -> String {
    
    for i in 0...4 {
        
        let precedency = 4 - i
        var forDelete = [Int]() // это будет массив номеров значений, которые нужно удалить перед следующей итерацией
        
        for j in 0..<array.count {
            
            if let operation = operationsWhithPrecedency[array[j]] {
                switch operation {
                case .Constants(let value, precedency):
                    array[j] = String(value)
                case .UnaryOperations(let function, precedency):
                    if let value = Double(array[j+1]) {
                        array[j+1] = String(function(value))
                        forDelete.append(j)
                    } else {return "Ошибка расчета"}
                case .BinaryOperations(let function, precedency):
                    if let firstValue = Double(array[j-1]), let secondValue = Double(array[j+1]) {
                        array[j+1] = String(function(firstValue, secondValue))
                        forDelete.append(j)
                        forDelete.append(j-1)
                    } else {return "Ошибка расчета"}
                default: break
                }
            }

        }
        
        // удаляем уже просчитаные элементы массива
        for i in forDelete.sorted(by: {$0 > $1}) {  // сортируем для того, что бы не попытаться удалить элемент под номером, которого уже нет в массиве
            array.remove(at: i)
        }
        forDelete.removeAll()
        
    }

    return array.count == 1 ? array[0] : "Ошибка расчета"
    
}

//var result = mathArray(array: &arrayOne)
//print(result)






// ----- Алгаритм избавления от скобок - записываем в масив выражения в скобках -> считаем -> возвращаем в массив резульат -> опять ищем скобки -> и т.д.

//var arrayTest3 = ["(", "2", "+", "3", ")", "*", "4"]
var resultArray = [String]()

var bracket = (start: 0, end: 0)
var result = 0

for i in 0..<array.count {
    
    resultArray.append(array[i])
    
    if array[i] == "(" {
        bracket.start = i
        resultArray = []
    }
    
    if array[i] == ")" {
        bracket.end = i
        resultArray.removeLast()
        break
    }
    
}

print(resultArray)
array.insert(mathArray(array: &resultArray), at: bracket.end + 1)
array.removeSubrange(bracket.start...bracket.end)
print(array)
//array.remove(at: bracket.start)
//array.remove(at: bracket.end)





