// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Generate Encodable/Decodable only when needed

final class Generator {
    let spec: OpenAPI.Document
    let options: GenerateOptions
    let arguments: GenerateArguments
    let templates: Templates
    
    // State collected during generation
    var isAnyJSONUsed = false
    var isHTTPHeadersDependencyNeeded = false
    var isRequestOperationIdExtensionNeeded = false
    var isEmptyObjectNeeded = false
    var isQueryParameterEncoderNeeded = false
    var needsEncodable = Set<TypeName>()
    let lock = NSLock()
    
    private var startTime: CFAbsoluteTime?
    
    init(spec: OpenAPI.Document, options: GenerateOptions, arguments: GenerateArguments) {
        self.spec = spec
        self.options = options
        self.arguments = arguments
        self.templates = Templates(options: options)
    }
    
    // MARK: Performance Measurement
    
    func startMeasuring(_ operation: String) {
        startTime = CFAbsoluteTimeGetCurrent()
        if arguments.isVerbose {
            print("Started \(operation)")
        }
    }
    
    func stopMeasuring(_ operation: String) {
        guard let startTime = startTime else {
            return
        }
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        if arguments.isVerbose {
            print("Finished \(operation) in \(timeElapsed) s.")
        }
    }

    // MARK: Misc
    
    func makePropertyName(_ rawValue: String) -> PropertyName {
        PropertyName(processing: rawValue, options: options)
    }
    
    func makeTypeName(_ rawValue: String) -> TypeName {
        TypeName(processing: rawValue, options: options)
    }
    
    // MARK: State
    
    func setNeedsAnyJson() {
        lock.sync { isAnyJSONUsed = true }
    }
    
    func setNeedsHTTPHeadersDependency() {
        lock.sync { isHTTPHeadersDependencyNeeded = true }
    }
    
    func setNeedsEncodable(for type: TypeName) {
        lock.sync { needsEncodable.insert(type) }
    }
    
    func setNeedsRequestOperationIdExtension() {
        lock.sync { isRequestOperationIdExtensionNeeded = true }
    }
    
    func setNeedsQueryParameterEncoder() {
        lock.sync { isQueryParameterEncoderNeeded = true }
    }
}

struct GeneratorError: Error, CustomStringConvertible, LocalizedError {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var description: String { message }
    var errorDescription: String? { message }
}

#warning("TODO: See if we can simplify this")
struct Context {
    var parents: [TypeName]
    var namespace: String?
    var isDecodableNeeded = true
    var isEncodableNeeded = true
    
    func adding(_ parent: TypeName) -> Context {
        map { $0.parents = $0.parents + [parent] }
    }
    
    private func map(_ closure: (inout Context) -> Void) -> Context {
        var copy = self
        closure(&copy)
        return copy
    }
}
