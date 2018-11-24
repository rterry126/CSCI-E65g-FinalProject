import Foundation

// MARK: Utilities class -- for the cases where extensions would be possible, the class names are too long to be convenient.
class Util {
    static var debug = true
    static var maxStack: Int?
    
    
    static func log(_ message: String, path: String = #file, line: Int = #line, function: String = #function) {
        if debug {
            if message == "exit" {
                // disable these by default; it gets too verbose unless we want to find slow functions
                return
            }
            
            if let max = maxStack {
                var stackDump = Thread.callStackSymbols
                stackDump.removeSubrange(0...2)
                stackDump.removeSubrange(max...(stackDump.count - 1))
                print(stackDump.reduce("") { "\($0)\n\($1)" })
            }
            
            let threadType = Thread.current.isMainThread ? "main" : "other"
            
            let baseName = (URL(fileURLWithPath: path).lastPathComponent as NSString).deletingPathExtension
            
            NSLog("%@", "\(threadType) \(baseName) \(function)[\(line)]: \(message)")
        }
    }
    
    
    static func setDebug(_ newVal: Bool) {
        debug = newVal
    }
}
