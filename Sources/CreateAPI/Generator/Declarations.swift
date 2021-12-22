// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import OpenAPIKit30

indirect enum MyType: CustomStringConvertible, Hashable {
    // One of the primitive types: `String`, `Bool`, `Int`, `Date`, `Void` etc
    case builtin(name: TypeName)
    // Custom type generated from the OpenAPI spec
    case userDefined(name: TypeName)
    // Array
    case array(element: MyType)
    // Dictionary
    case dictionary(key: MyType, value: MyType)
    
    // MARK: Helpers
    
    var isBool: Bool { builtinTypeName == "Bool" }
    var isVoid: Bool { builtinTypeName == "Void" }
    var isString: Bool { builtinTypeName == "String" }
    
    var isArray: Bool {
        if case .array = self { return true } else { return false }
    }
    
    var builtinTypeName: String? {
        if case .builtin(let name) = self { return name.rawValue }
        return nil
    }
    
    func asArray() -> MyType {
        .array(element: self)
    }
    
    func asPatchParameter() -> MyType {
        .userDefined(name: TypeName("\(self)?")) // TODO: Refactor
    }
    
    var name: TypeName {
        TypeName(description)
    }
    
    var elementType: MyType {
        switch self {
        case .builtin, .userDefined: return self
        case .array(let element): return element.elementType
        case .dictionary(_, let value): return value.elementType
        }
    }
    
    // Generates a type identifier adding a namespace if needed.
    func identifier(namespace: String?) -> TypeName {
        switch self {
        case .builtin(let name): return name
        case .userDefined(let name): return name.namespace(namespace)
        case .array(let element): return TypeName("[\(element.identifier(namespace: namespace))]")
        case .dictionary(let key, let value): return TypeName("[\(key): \(value.identifier(namespace: namespace))]")
        }
    }

    // MARK: Factory
    
    static func builtin(_ name: String) -> MyType {
        .builtin(name: TypeName(name))
    }
    
    static func dictionary(value: MyType) -> MyType {
        .dictionary(key: .builtin("String"), value: value)
    }
    
    static var anyJSON: MyType {
        .userDefined(name: TypeName("AnyJSON"))
    }
    
    // MARK: CustomStringConvertible
    
    var description: String {
        switch self {
        case .array(let element): return "[\(element)]"
        case .dictionary(let key, let value): return "[\(key): \(value)]"
        case .userDefined(let name): return name.rawValue
        case .builtin(let name): return name.rawValue
        }
    }
}

struct Protocols: ExpressibleByArrayLiteral {
    var rawValue: Set<String>
    
    init(_ rawValue: Set<String>) {
        self.rawValue = rawValue
    }
    
    init(arrayLiteral elements: String...) {
        self.rawValue = Set(elements)
    }
    
    var isDecodable: Bool {
        rawValue.contains("Decodable") || rawValue.contains( "Codable")
    }
    
    var isEncodable: Bool {
        rawValue.contains("Encodable") || rawValue.contains( "Codable")
    }
    
    mutating func removeDecodable() {
        if rawValue.contains("Codable") {
            rawValue.remove("Codable")
            rawValue.insert("Encodable")
        } else {
            rawValue.remove("Decodable")
        }
    }
    
    mutating func removeEncodable() {
        if rawValue.contains("Codable") {
            rawValue.remove("Codable")
            rawValue.insert("Decodable")
        } else {
            rawValue.remove("Encodable")
        }
    }
    
    mutating func insert(_ protocol: String) {
        rawValue.insert(`protocol`)
    }
    
    func sorted() -> [String] {
        rawValue.sorted()
    }
}

struct Property {
    // Example: "files"
    var name: PropertyName
    // Example: "[File]"
    var type: MyType
    var isOptional: Bool
    // Key in the JSON
    var key: String
    // This is currently only used for query parameters
    var explode = true
    var defaultValue: String?
    var metadata: DeclarationMetadata?
    // A nested declaration required used as a property type
    var nested: Declaration?
}

protocol Declaration {
    var name: TypeName { get }
}

struct EnumOfStringsDeclaration: Declaration {
    let name: TypeName
    let cases: [Case]
    let metadata: DeclarationMetadata
    
    struct Case {
        let name: String
        let key: String
    }
}

// Gets rendered as either a struct or a class depending on the options.
struct EntityDeclaration: Declaration {
    let name: TypeName
    var type: EntityType
    let properties: [Property]
    let protocols: Protocols
    let metadata: DeclarationMetadata
    var isForm: Bool
    
    var nested: [Declaration] {
        properties.compactMap { $0.nested }
    }
    
    // Returns `true` if the type is nested inside the entity declaration.
    func isNested(_ type: MyType) -> Bool {
        guard case .userDefined(let name) = type else { return false }
        return nested.contains { $0.name == name }
    }
}

enum EntityType {
    case object
    case anyOf
    case allOf
    case oneOf
}

struct TypealiasDeclaration: Declaration {
    let name: TypeName
    var type: MyType
    var nested: Declaration?
}

struct DeclarationMetadata {
    var title: String?
    var description: String?
    var externalDocsDescription: String?
    var externalDocsURL: URL?
    var example: AnyCodable?
    var isDeprecated: Bool

    init(_ schema: JSONSchemaContext?) {
        self.title = schema?.title
        self.description = schema?.description
        self.example = schema?.example
        self.externalDocsDescription = schema?.externalDocs?.description
        self.externalDocsURL = schema?.externalDocs?.url
        self.isDeprecated = schema?.deprecated ?? false
    }
    
    init(_ operation: OpenAPI.Operation) {
        self.title = operation.summary
        self.description = operation.description
        self.example = nil
        self.externalDocsDescription = operation.externalDocs?.description
        self.externalDocsURL = operation.externalDocs?.url
        self.isDeprecated = operation.deprecated
    }
}

struct PathParameter {
    let key: String // Unprocessed key
    let name: PropertyName
    let type: TypeName
}
