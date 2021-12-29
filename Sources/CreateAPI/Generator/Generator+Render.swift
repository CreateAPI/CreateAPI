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
        case let decl as TypealiasDeclaration: return render(decl)
        case let decl as AnyDeclaration: return decl.rawValue
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
        let properties: [Property] = decl.properties
            .map {
                // This handles a scenario where a nested entity has a reference
                // to one of the top-level types with the same name as the entity.
                if $0.type.name == decl.name && $0.nested == nil, decl.parent != nil {
                    var property = $0
                    property.type = .builtin(name: $0.type.identifier(namespace: arguments.module.rawValue)) // TODO: Refactor
                    return property
                }
                return $0
            }
        
        var contents: [String] = []
        switch decl.type {
        case .object, .allOf, .anyOf:
            contents.append(templates.properties(properties))
            contents += decl.nested.map(render)
            if options.entities.isGeneratingInitializers {
                contents.append(templates.initializer(properties: properties))
            }
        case .oneOf:
            contents.append(properties.map(templates.case).joined(separator: "\n"))
            contents += decl.nested.map(render)
        }

        if decl.isForm {
            switch decl.type {
            case .object, .allOf, .anyOf:
                contents.append(templates.asQuery(properties: properties))
            case .oneOf:
                contents.append(templates.enumAsQuery(properties: properties))
            }
        } else {
            switch decl.type {
            case .object:
                if options.entities.isGeneratingCustomCodingKeys {
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
            case .anyOf:
                if decl.protocols.isDecodable {
                    contents.append(templates.initFromDecoderAnyOf(properties: properties))
                }
                if decl.protocols.isEncodable {
                    contents.append(templates.encodeAnyOf(properties: properties))
                }
            case .allOf:
                var needsValues = false
                let decoderContents = properties.map {
                    if case .userDefined = $0.type {
                        return templates.decodeFromDecoder(property: $0)
                    } else {
                        needsValues = true
                        return templates.decode(property: $0, isUsingCodingKeys: false)
                    }
                }.joined(separator: "\n")
                if decl.protocols.isDecodable {
                    contents.append(templates.initFromDecoder(contents: decoderContents, needsValues: needsValues, isUsingCodingKeys: false))
                }
                if decl.protocols.isEncodable {
                    contents.append(templates.encode(properties: properties))
                }
            case .oneOf:
                if decl.protocols.isDecodable {
                    contents.append(templates.initFromDecoderOneOf(properties: properties))
                }
                if decl.protocols.isEncodable {
                    contents.append(templates.encodeOneOf(properties: properties))
                }
            }
        }
        
        // TODO: Refactor
        var protocols = decl.protocols
        if decl.isForm {
            protocols.removeEncodable()
        }
        
        let entity: String
        if decl.type == .oneOf {
            entity = templates.enumOneOf(name: decl.name, contents: contents, protocols: decl.protocols)
        } else if decl.hasReferencesToItself {
            // Struct can't have references to itself
            entity = templates.class(name: decl.name, contents: contents, protocols: decl.protocols)
        } else {
            entity = templates.entity(name: decl.name, contents: contents, protocols: decl.protocols)
        }
        return templates.comments(for: decl.metadata, name: decl.name.rawValue) + entity
    }
    
    private func render(_ value: TypealiasDeclaration) -> String {
        [templates.typealias(name: value.name, type: value.type.name),
         value.nested.map(render)]
            .compactMap { $0 }
            .joined(separator: "\n\n")
    }
}

private extension EntityDeclaration {
    var hasReferencesToItself: Bool {
        properties.contains {
            // Check a simple case where a property references to the type itself
            // (not it's not a nested type with the same name)
            if $0.type.name == name && $0.nested == nil {
                return true
            }
            // Shallow check for typealiases
            if let alias = $0.nested as? TypealiasDeclaration, alias.type.name == name {
                return true
            }
            return false
        }
    }
}
