// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import OpenAPIKit30

extension String {
    func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }

    func lowercasedFirstLetter() -> String {
        prefix(1).lowercased() + dropFirst()
    }
    
    func indent(using options: GenerateOptions) -> String {
        let indetation: String
        switch options.indentation {
        case .tabs: indetation = "\t"
        case .spaces: indetation = String(repeating: " ", count: options.spaceWidth)
        }
        guard indetation != "    " else {
            return self
        }
        return replacingOccurrences(of: "    ", with: indetation)
    }
    
    func namespace(_ namespace: String?) -> String {
        guard let namespace = namespace, !namespace.isEmpty else {
            return self
        }
        return "\(namespace).\(self)"
    }
    
    var nextLetter: String? {
        // Check if string is build from exactly one Unicode scalar:
        guard let uniCode = UnicodeScalar(self) else {
            return nil
        }
        switch uniCode {
        case "a" ..< "z":
            return String(UnicodeScalar(uniCode.value + 1)!)
        default:
            return nil
        }
    }
    
    var isEscapingNeeded: Bool {
        contains("\\")
    }
}

func concurrentPerform<T>(on array: [T], parallel: Bool, _ work: (Int, T) -> Void) {
    let coreCount = suggestedCoreCount
    let iterations = !parallel ? 1 : (array.count > (coreCount * 2) ? coreCount : 1)
    
    DispatchQueue.concurrentPerform(iterations: iterations) { index in
        let start = index * array.indices.count / iterations
        let end = (index + 1) * array.indices.count / iterations
        for index in start..<end {
            work(index, array[index])
        }
    }
}

// TODO: Find a better way to do concurrent perform.
var suggestedCoreCount: Int {
    ProcessInfo.processInfo.processorCount
}

extension NSLock {
    func sync(_ closure: () -> Void) {
        lock()
        closure()
        unlock()
    }
}

struct Benchmark {
    let name: String
    let startTime = CFAbsoluteTimeGetCurrent()
    static var isEnabled = false
    
    func stop() {
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        guard Benchmark.isEnabled else { return }
        print("\(name) completed (\(String(format: "%.3f", timeElapsed)) s)")
    }
}

// Supports simple templates like "Get%0".
struct Template {
    let rawValue: String

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    func substitute(_ parameter: String...) -> String {
        var output = rawValue
        for index in parameter.indices {
            output = output.replacingOccurrences(of: "%\(index)", with: parameter[index])
        }
        return output
    }
}

extension Array {
    func removingDuplicates<U: Hashable>(by closure: (Element) -> U) -> [Element] {
        var buffer = [Element]()
        var encountered = Set<U>()
        for element in self {
            let key = closure(element)
            if !encountered.contains(key) {
                buffer.append(element)
                encountered.insert(key)
            }
        }
        return buffer
    }
}

extension Array where Element == String {
    func disambiguateDuplicateNames() -> [String] {
        var encountered: [String: Int] = [:]
        return self.map { name in
            if let count = encountered[name] {
                encountered[name] = count + 1
                return name + "\(count + 1)"
            } else {
                encountered[name] = 1
                return name
            }
        }
    }
}

struct NameDeduplicator {
    private var encountered: [String: Int] = [:]
    
    mutating func add(name: String) -> String {
        let count = encountered[name] ?? 0
        encountered[name] = count + 1
        if count == 0 {
            return name
        }
        let name = name + "\(count + 1)"
        return add(name: name)
    }
}

final class Cache<Key: Hashable, Value> {
    private var values: [Key: Value] = [:]
    private let lock = NSLock()
    
    subscript(key: Key) -> Value? {
        get {
            lock.lock()
            let value = values[key]
            lock.unlock()
            return value
        }
        set {
            lock.lock()
            values[key] = newValue
            lock.unlock()
        }
    }
}
