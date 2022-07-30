// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import CreateOptions
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
    var isQueryEncoderNeeded = false
    var isNaiveDateNeeded = false
    var needsEncodable = Set<TypeName>()
    var topLevelTypes = Set<TypeName>()
    var generatedSchemas: [TypeName: EntityDeclaration] = [:]
    var pathsContainingRequestType: [String] = []
    let lock = NSLock()
    
    init(spec: OpenAPI.Document, options: GenerateOptions, arguments: GenerateArguments) {
        self.spec = spec
        self.options = options
        self.arguments = arguments
        self.templates = Templates(options: options)
    }
    
    // MARK: Misc
    
    func makePropertyName(_ rawValue: String) -> PropertyName {
        PropertyName(processing: rawValue, options: options)
    }
    
    func makeTypeName(_ rawValue: String) -> TypeName {
        TypeName(processing: rawValue, options: options)
    }
    
    func makeHeader(imports: Set<String>) -> String {
        var header = fileHeader
        for value in imports.sorted() {
            header += "\nimport \(value)"
        }
        return header
    }
    
    // MARK: State
    
    func setNeedsAnyJson() {
        lock.sync { isAnyJSONUsed = true }
    }
    
    func setNeedsHTTPHeadersDependency() {
        lock.sync { isHTTPHeadersDependencyNeeded = true }
    }
    
    func setNeedsEncodable(for type: TypeIdentifier) {
        guard case .userDefined(let name) = type else { return }
        lock.sync { needsEncodable.insert(name) }
    }
    
    func setNeedsRequestOperationIdExtension() {
        lock.sync { isRequestOperationIdExtensionNeeded = true }
    }
    
    func setNaiveDateNeeded() {
        lock.sync { isNaiveDateNeeded = true }
    }
    
    func setNeedsQuery() {
        lock.sync { isQueryEncoderNeeded = true }
    }
    
    // MARK: Misc
    
    func verbose(_ message: @autoclosure () -> String) {
        guard arguments.isVerbose else { return }
        print(message())
    }
    
    var fileHeader: String {
        var output = options.fileHeaderComment
        
        if options.isSwiftLintDisabled {
            output += "\n"
            output += """
            //
            // swiftlint:disable all
            """
        }

        let imports = [
            "Foundation",
            isNaiveDateNeeded ? "NaiveDate" : nil
        ].compactMap { $0 }
        
        output += "\n\n"
        output += imports.map { "import \($0)" }.joined(separator: "\n")

        return output
    }
    
    // MARK: Errors and Warnings

    func handle(warning message: String) throws {
        let error = GeneratorError(message)
        if arguments.isStrict {
            throw error
        } else {
            print("WARNING: \(error)")
        }
    }
    
    func handle<T>(error message: String) throws -> T? {
        let error = GeneratorError(message)
        if arguments.isIgnoringErrors {
            print("ERROR: \(error)")
            return nil
        } else {
            throw error
        }
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

// TODO: Move props to bit array
// TODO: Make a reference type or CoW
struct Context {
    var parents: [EntityDeclaration] = []
    var encountered: Set<OpenAPI.ComponentKey> = []
    var objectSchema: JSONSchema.ObjectContext? // TODO: Refactor
    var namespace: String? // TODO: Refactor how namespaces are added
    var isDecodableNeeded = true
    var isEncodableNeeded = true
    var isPatch = false
    var isFormEncoding = false
    /// A special mode where declaration need to exit early if they detect
    /// that that are not resolvable to primitive type identifiers.
    var isInlinableTypeCheck = false

    func map(_ closure: (inout Context) -> Void) -> Context {
        var copy = self
        closure(&copy)
        return copy
    }
}

struct GeneratorOutput {
    let header: String
    let files: [GeneratedFile]
    let extensions: GeneratedFile?
}

struct GeneratedFile {
    let name: String
    let contents: String
}
