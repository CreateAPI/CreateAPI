// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation

extension Generator {
    func render(_ decl: Declaration) -> String {
        switch decl {
        case let decl as EnumOfStringsDeclaration: return render(decl)
        case let decl as EntityDeclaration: return render(decl)
        case let decl as AnyDeclaration: return decl.contents
        default: fatalError()
        }
    }
    
    private func render(_ decl: EnumOfStringsDeclaration) -> String {
        let comments = templates.comments(for: decl.metadata, name: decl.name.rawValue)
        let cases = decl.cases.map {
            templates.case(name: $0.name, value: $0.key)
        }.joined(separator: "\n")
        return comments + templates.enumOfStrings(name: decl.name, contents: cases)
    }
    
    private func render(_ decl: EntityDeclaration) -> String {
        let properties = decl.properties
        
        var contents: [String] = []
        contents.append(templates.properties(properties))
        contents += decl.nested.map(render)
        if options.entities.isGeneratingInitializers {
            contents.append(templates.initializer(properties: properties))
        }
        if decl.isForm {
            contents.append(templates.asQueryString(properties: properties))
        } else {
            if options.entities.isUsingCustomCodingKeys {
                if let keys = templates.codingKeys(for: properties) {
                    contents.append(keys)
                }
                if decl.protocols.isDecodable, properties.contains(where: { $0.defaultValue != nil }) {
                    contents.append(templates.initFromDecoder(properties: properties, isUsingCodingKeys: true))
                }
            } else {
                if decl.protocols.isDecodable, !properties.isEmpty, options.entities.isGeneratingInitWithDecoder {
                    contents.append(templates.initFromDecoder(properties: properties, isUsingCodingKeys: false))
                }
                if decl.protocols.isEncodable, !properties.isEmpty, options.entities.isGeneratingEncodeWithEncoder {
                    contents.append(templates.encode(properties: properties))
                }
            }
        }
        let hasReferencesToItself = properties.contains(where: { $0.type.name == decl.name && $0.nested == nil })
        let entity: String
        if hasReferencesToItself {
            // Struct can't have references to itself
            entity = templates.class(name: decl.name, contents: contents, protocols: decl.protocols)
        } else {
            entity = templates.entity(name: decl.name, contents: contents, protocols: decl.protocols)
        }
        return templates.comments(for: decl.metadata, name: decl.name.rawValue)
        + entity
    }
}
