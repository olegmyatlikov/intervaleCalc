import Foundation

/*
 // ----- Чтение файла и запись содержимого в массив строк
 
func readFile(path: String) -> Array<String> {
    
    do {
        let contents:NSString = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)    // пробуем записать содержимое файла в строку
        let lines: [String] =  NSString(string: contents).components(separatedBy: .newlines)    // строку contents записываем в массив строк разделяя \n
        return lines
    } catch {
        print("Файл \(path) не найден или у вас недостаточно прав для его чтения.");
        return [String]()
    }
    
}
 
 let lines = readFile(path: "/Users/oleg/Desktop/input.txt")
 
 

// ----- Преобразование строки математического выражения в массив для дальнейшего парсинга (потому что swift плохо работает со строками)

func stringToArray (str: String) -> [String] {
    
    let operations: Set = ["+", "-", "*", "/", "^", "(", ")", "sin", "cos", "tg"]
    var resultArray = [String]()
    var middleOfNumber = false
    
    for i in str.characters {
        
        switch (String(i), middleOfNumber) {
        case (" ", _): middleOfNumber = false   // игнорируем все пробелы
        case (let i, _) where operations.contains(i):   // если оператор (+ - / * ^)
            resultArray.append(String(i))
            middleOfNumber = false
        case (_, true) where operations.contains(resultArray[resultArray.endIndex - 1]):    // (если sin cos tg)
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

// работа со скобками
 
var array = ["(", "2", "+", "3", ")", "*", "4"]
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

//array.remove(at: bracket.start)
//array.remove(at: bracket.end)

print(resultArray)

*/

enum Operations {
    case Constants(Double, Int)
    case UnaryOperations(((Double) -> Double), Int)
    case BinaryOperations(((Double, Double) -> Double), Int)
}

let operationsWhithPrecedency : [String: Operations] = [
    "π" : Operations.Constants(M_PI, 4),
    "e" : Operations.Constants(M_PI, 4),
    "sin" : Operations.UnaryOperations(sin, 3),
    "cos" : Operations.UnaryOperations(cos, 3),
    "√" : Operations.UnaryOperations(sqrt, 2),
    "^" : Operations.BinaryOperations({pow($0, $1)}, 2),
    "×" : Operations.BinaryOperations({$0 * $1}, 1),
    "÷" : Operations.BinaryOperations({$0 / $1}, 1),
    "＋" : Operations.BinaryOperations({$0 + $1}, 0),
    "−" : Operations.BinaryOperations({$0 - $1}, 0)
]

var accumulator = 3.14159265358979


func performOperation (symbol: String) {
    if let operation = operationsWhithPrecedency[symbol] {
        switch operation {
        case .Constants(let value, _):
            accumulator = value
        case .UnaryOperations(let function, _):
            accumulator = function(accumulator)
        /*case .BinaryOperations(let (text, function)):
            executePendingBinaryOperation()
            pending = PendingBinaryOperation(binaryFunction: function, firstOperand: accumulator)
        default: break
        }
        
    }
    
}


var array = ["cos", "3,14", "+", "9", "-", "2", "*", "3"]

performOperation(symbol: "cos")
print(accumulator)







