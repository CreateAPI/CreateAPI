// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import OpenAPIKit30

extension JSONSchema {
    var isOptional: Bool {
        !self.required || self.nullable
    }
}

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
