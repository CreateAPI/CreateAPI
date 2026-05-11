import OpenAPIKit30
import Foundation
import CreateOptions

extension Generator {
    func render(_ decl: Declaration) throws -> String {
        switch decl {
        case let decl as EnumOfStringsDeclaration: return render(decl)
        case let decl as EntityDeclaration: return try render(decl)
        case let decl as TypealiasDeclaration: return try render(decl)
        case let decl as AnyDeclaration: return decl.rawValue
        default: fatalError()
        }
    }

    private func render(_ decl: EnumOfStringsDeclaration) -> String {
        let comments = templates.comments(for: decl.metadata, name: decl.name.rawValue)
        let cases = decl.cases.map {
            templates.case(name: $0.name, value: $0.key)
        }.joined(separator: "\n")
        return comments + templates.enumOfStrings(name: decl.name, contents: cases, protocols: decl.protocols)
    }

    private func render(_ decl: EntityDeclaration) throws -> String {
        var properties = decl.properties
        addNamespacesForConflictsWithNestedTypes(properties: &properties, decl: decl)
        addNamespacesForConflictsWithBuiltinTypes(properties: &properties, decl: decl)

        let type = try resolveGeneratedType(for: decl)
        let isReadOnly = !options.entities.mutableProperties.contains(type.isStruct ? .structs : .classes)

        var contents: [String] = []
        switch decl.type {
        case .object, .allOf, .anyOf:
            contents.append(templates.properties(properties, isReadonly: isReadOnly))
            contents += try decl.nested.map(render)
            if options.entities.includeInitializer {
                contents.append(templates.initializer(properties: properties))
            }
        case .oneOf:
            contents.append(properties.map(templates.case).joined(separator: "\n"))
            contents += try decl.nested.map(render)
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
                if !options.entities.optimizeCodingKeys {
                    if let keys = templates.codingKeys(for: properties) {
                        contents.append(keys)
                    }
                    if decl.protocols.isDecodable, properties.contains(where: { $0.defaultValue != nil }) {
                        contents.append(templates.initFromDecoder(properties: properties, isUsingCodingKeys: true))
                    }
                } else {
                    if decl.protocols.isDecodable, !properties.isEmpty, options.entities.alwaysIncludeDecodableImplementation {
                        contents.append(templates.initFromDecoder(properties: properties, isUsingCodingKeys: false))
                    }
                    if decl.protocols.isEncodable, !properties.isEmpty, options.entities.alwaysIncludeEncodableImplementation {
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
                    if case .userDefined = $0.type, $0.isInlined != true {
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
                    if let discriminator = decl.discriminator {
                        contents.append(templates.initFromDecoderOneOfWithDiscriminator(properties: properties, discriminator: discriminator))
                    } else {
                        contents.append(templates.initFromDecoderOneOf(properties: properties))
                    }
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
        switch type {
        case .enumOneOf:
            entity = templates.enumOneOf(name: decl.name, contents: contents, protocols: decl.protocols)
        case .struct:
            entity = templates.struct(name: decl.name, contents: contents, protocols: decl.protocols)
        case .class(let isFinal):
            entity = templates.class(name: decl.name, isFinal: isFinal, contents: contents, protocols: decl.protocols)
        }

        return templates.comments(for: decl.metadata, name: decl.name.rawValue) + entity
    }

    private func render(_ value: TypealiasDeclaration) throws -> String {
        [templates.typealias(name: value.name, type: value.type.name),
         try value.nested.map(render)]
            .compactMap { $0 }
            .joined(separator: "\n\n")
    }

    enum ResolvedType {
        case enumOneOf, `struct`, `class`(isFinal: Bool)

        var isStruct: Bool {
            guard case .struct = self else { return false }
            return true
        }
    }

    private func resolveGeneratedType(for decl: EntityDeclaration) throws -> ResolvedType {
        if decl.type == .oneOf {
            return .enumOneOf
        } else if decl.isRenderedAsStruct {
            return .struct
        }

        switch options.entities.preferredType(of: decl.name.rawValue) {
        case .struct where hasReferences(to: decl.name, decl):
            try handle(warning: """
                Entity '\(decl.name.rawValue)' cannot be generated as a struct because \
                it has a stored property that recursively contains itself. Explicitly \
                define an override using 'entities.typeOverrides' or ignore the \
                entity/property using 'entities.ignore' to fix this issue.
                """)
            return .class(isFinal: true)
        case .struct:
            return .struct
        case .class:
            return .class(isFinal: false)
        case .finalClass:
            return .class(isFinal: true)
        }
    }

    // TODO: This doesn't handle a scenario where a reference is detected in an
    // entity that itself has references to itself and thus always gets geenrated
    // as a class. So technically, struct is ok, but we err on the safe safe.
    private func hasReferences(to type: TypeName, _ entity: EntityDeclaration) -> Bool {
        var encountered = Set<TypeName>()
        var properties = entity.properties
        while let property = properties.popLast() {
            guard case .userDefined(let propertyType) = property.type else {
                // Skip built-in types and collections (they are OK for the purposes
                // or generating structs)
                continue
            }
            guard !encountered.contains(propertyType) else {
                continue // Found a cycle (but not in entity)
            }
            encountered.insert(propertyType)
            // Check a simple case where a property references to the type itself
            // (not it's not a nested type with the same name)
            if property.type.elementType.name == type && property.nested == nil {
                return true
            }
            // Deep check in nested objects or other top-level declarations.
            if let nested = property.nested {
                switch nested {
                case let decl as EntityDeclaration:
                    properties += decl.properties
                case let alias as TypealiasDeclaration:
                    if alias.type.name == type {
                        return true
                    }
                default:
                    break
                }
            } else if let entity = generatedSchemas[property.type.elementType.name] {
                properties += entity.properties
            }
        }
        return false
    }

    // MARK: Preprocessing

    // Handles a scenario where a nested entity has a reference to one of the
    // top-level types with the same name as the entity.
    private func addNamespacesForConflictsWithNestedTypes(properties: inout [Property], decl: EntityDeclaration) {
        for index in properties.indices {
            let property = properties[index]
            if property.type.name == decl.name && property.nested == nil, decl.parent != nil {
                properties[index].type = .builtin(name: property.type.identifier(namespace: options.module.name)) // TODO: Refactor
            }
        }
    }

    // Handles a scenario where one of the generated entites (top-level or nested)
    // overrides one of the built-in types.
    private func addNamespacesForConflictsWithBuiltinTypes(properties: inout [Property], decl: EntityDeclaration) {
        for index in properties.indices {
            guard case .builtin(let type) = properties[index].type.elementType else {
                continue
            }
            guard TypeIdentifier.allGeneratedBuiltinTypes.contains(type) else {
                continue
            }
            if generatedSchemas[type] != nil || decl.isOverriding(type: type) {
                properties[index].type = .builtin("\(namespace(for: type)).\(type)")
            }
        }
    }
}

private extension EntityDeclaration {
    func isOverriding(type: TypeName) -> Bool {
        if name == type {
            return true
        }
        if nested.contains(where: { $0.name == type }) {
            return true
        }
        guard let parent = self.parent else {
            return false
        }
        return parent.isOverriding(type: type)
    }
}

private func namespace(for builtinType: TypeName) -> String {
    switch builtinType.rawValue {
    case "Date", "URL", "Data": return "Foundation"
    default: return "Swift"
    }
}
