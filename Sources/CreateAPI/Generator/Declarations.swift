// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
import OpenAPIKit30
import Darwin
import AppKit

// - note: Currently doesn't contain namespaces or parents names. These are
// mananged separately.
indirect enum TypeIdentifier: CustomStringConvertible, Hashable {
    // One of the primitive types: `String`, `Bool`, `Int`, `Date`, `Void` etc
    case builtin(name: TypeName)
    // Custom type generated from the OpenAPI spec
    case userDefined(name: TypeName)
    // Array
    case array(element: TypeIdentifier)
    // Dictionary
    case dictionary(key: TypeIdentifier, value: TypeIdentifier)

    // MARK: Helpers
    
    var isBool: Bool { builtinTypeName == "Bool" }
    var isVoid: Bool { builtinTypeName == "Void" }
    var isString: Bool { builtinTypeName == "String" }
    
    static let allGeneratedBuiltinTypes = Set<TypeName>(["String", "Bool", "Double", "Int", "Int32", "Int64", "Date", "URL", "Data"].map(TypeName.init))
    
    var isArray: Bool {
        if case .array = self { return true } else { return false }
    }
    
    var builtinTypeName: String? {
        if case .builtin(let name) = self { return name.rawValue }
        return nil
    }
    
    var isBuiltin: Bool {
        builtinTypeName != nil
    }
    
    func asArray() -> TypeIdentifier {
        .array(element: self)
    }
    
    func asPatchParameter() -> TypeIdentifier {
        .userDefined(name: TypeName("\(self)?")) // TODO: Refactor
    }
    
    var name: TypeName {
        TypeName(description)
    }
    
    var elementType: TypeIdentifier {
        switch self {
        case .builtin, .userDefined: return self
        case .array(let element): return element.elementType
        case .dictionary(_, let value): return value.elementType
        }
    }
    
    // Generates a type identifier adding a namespace if needed.
    func identifier(namespace: String) -> TypeName {
        switch self {
        case .builtin(let name): return name
        case .userDefined(let name): return name.namespace(namespace)
        case .array(let element): return TypeName("[\(element.identifier(namespace: namespace))]")
        case .dictionary(let key, let value): return TypeName("[\(key): \(value.identifier(namespace: namespace))]")
        }
    }
    
    // MARK: Factory
    
    static func builtin(_ name: String) -> TypeIdentifier {
        .builtin(name: TypeName(name))
    }
    
    static func dictionary(value: TypeIdentifier) -> TypeIdentifier {
        .dictionary(key: .builtin("String"), value: value)
    }
    
    static var anyJSON: TypeIdentifier {
        .userDefined(name: TypeName("AnyJSON"))
    }
    
    // MARK: CustomStringConvertible
    
    var description: String {
        switch self {
        case .array(let element): return "[\(element)]"
        case .dictionary(let key, let value): return "[\(key): \(value)]"
        case .userDefined(let name), .builtin(let name): return name.rawValue
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

// TODO: Don't use this for QueryParameters?
struct Property {
    // Example: "files"
    var name: PropertyName
    // Example: "[File]"
    var type: TypeIdentifier
    var isOptional: Bool
    // Key in the JSON
    var key: String
    // warning: - This is currently only used for query parameters
    var explode = true
    // warning: - This is currently only used for query parameters
    var style: OpenAPI.Parameter.SchemaContext.Style?
    var defaultValue: String?
    var metadata: DeclarationMetadata?
    // A nested declaration required used as a property type
    var nested: Declaration?
    // If the schema is inlined by `allOf`. This is currently used only for the generation of decoders.
    var isInlined: Bool
}

protocol Declaration {
    var name: TypeName { get }
}

extension Declaration {
    // If it's a typealias, return an unwrapped type identifier
    func getTypeIdentifier() -> TypeIdentifier? {
        switch self {
        case let alias as TypealiasDeclaration:
            // TODO: What about nested typeliaes?
            return alias.nested == nil ? alias.type : nil
        default:
            return nil
        }
    }
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
final class EntityDeclaration: Declaration {
    var name: TypeName
    let type: EntityType
    let metadata: DeclarationMetadata
    let isForm: Bool
    
    var protocols = Protocols()
    var properties: [Property] = []
    var discriminator: Discriminator?

    var isRenderedAsStruct = false
    weak var parent: EntityDeclaration?
    
    var nested: [Declaration] {
        properties.compactMap { $0.nested }
    }
    
    init(name: TypeName, type: EntityType, metadata: DeclarationMetadata, isForm: Bool, discriminator: Discriminator? = nil, parent: EntityDeclaration? = nil) {
        self.name = name
        self.type = type
        self.metadata = metadata
        self.isForm = isForm
        self.discriminator = discriminator
        self.parent = parent
    }
    
    // Returns `true` if the type is nested inside the entity declaration.
    func isNested(_ type: TypeIdentifier) -> Bool {
        guard case .userDefined(let name) = type else { return false }
        return nested.contains { $0.name == name }
    }
}

struct AnyDeclaration: Declaration {
    let name: TypeName
    let rawValue: String
    
    static let empty = AnyDeclaration(name: TypeName("empty"), rawValue: "")
}

enum EntityType {
    case object
    case anyOf
    case allOf
    case oneOf
}

struct TypealiasDeclaration: Declaration {
    let name: TypeName
    var type: TypeIdentifier
    var nested: Declaration?
}

struct Discriminator {
    let propertyName: String
    let mapping: [String: TypeIdentifier]
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
