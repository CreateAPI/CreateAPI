// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import OpenAPIKit30

// TODO: Move somewhere else, document, and remove unused stuff
struct Property {
    // Example: "files"
    var name: PropertyName
    // Example: "[File]"
    var type: TypeName
    var isOptional: Bool
    // Key in the JSON
    var key: String

#warning("TODO: Remove")
    var explode = true
    #warning("TODO: Remove")
    var schema: JSONSchema // TODO: Remove
    var metadata: DeclarationMetadata?
    
#warning("TODO: Should nested declaration be moved somewhere?")
    var nested: Declaration?
}

protocol Declaration {}

struct EnumOfStringsDeclaration: Declaration {
    let name: TypeName
    let cases: [Case]
    let metadata: DeclarationMetadata
    
    struct Case {
        let name: String
        let key: String
    }
}

struct EntityDeclaration: Declaration {
    let name: TypeName
    let properties: [Property]
    let protocols: Protocols
    let metadata: DeclarationMetadata
}

struct AnyDeclaration: Declaration {
    let contents: String
}

struct DeclarationMetadata {
    var title: String?
    var description: String?
    var externalDocsDescription: String?
    var externalDocsURL: URL?
    var example: AnyCodable?
    var isDeprecated: Bool
    
#warning("TODO: Remove")
    var isProperty: Bool
    
    init(_ schema: JSONSchemaContext?) {
        self.title = schema?.title
        self.description = schema?.description
        self.example = schema?.example
        self.externalDocsDescription = schema?.externalDocs?.description
        self.externalDocsURL = schema?.externalDocs?.url
        self.isDeprecated = schema?.deprecated ?? false
        self.isProperty = true
    }
    
    init(_ operation: OpenAPI.Operation) {
        self.title = operation.summary
        self.description = operation.description
        self.example = nil
        self.externalDocsDescription = operation.externalDocs?.description
        self.externalDocsURL = operation.externalDocs?.url
        self.isDeprecated = operation.deprecated
        self.isProperty = false
    }
}
