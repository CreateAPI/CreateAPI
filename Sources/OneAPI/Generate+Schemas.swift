// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit
import Foundation

// TODO: Use SwiftFormat to align stuff?
// TODO: Generate initializer
// TODO: Allow to specify Codable/Decodable
// TODO: Add an option to skip comments

extension Generate {
    func generateSchemas(for spec: OpenAPI.Document) -> String {
        var output = """
        // Auto-generated
        
        import Foundation\n\n
        """
        for (key, schema) in spec.components.schemas {
            do {
                output += try makeSchema(for: key.rawValue, schema: schema, level: 0)
                output += "\n"
            } catch {
                print("WARNING: \(error)")
            }
        }
        return output
    }

    private func makeSchema(for key: String, schema: JSONSchema, level: Int) throws -> String {
        // TODO: Generate struct/classes based on how many fields or what?
        var fields = ""
        switch schema {
        case .boolean(let coreContext):
            return try makeTypealiasPrimitive(name: key, json: schema, context: coreContext)
        case .number(let coreContext, _):
            return try makeTypealiasPrimitive(name: key, json: schema, context: coreContext)
        case .integer(let coreContext, _):
            return try makeTypealiasPrimitive(name: key, json: schema, context: coreContext)
        case .string(let coreContext, _):
            return try makeTypealiasPrimitive(name: key, json: schema, context: coreContext)
        case .object(let coreContext, let objectContext):
            return try makeObject(key, coreContext, objectContext, level: level)
        case .array(let coreContext, let arrayContext):
            return try makeTypealiasArray(key, coreContext, arrayContext)
        case .all(let of, let core):
            fields = "    #warning(\"TODO:\")"
        case .one(let of, _):
            return try makeOneOf(name: key, of)
        case .any(let of, let core):
            fields = "    #warning(\"TODO:\")"
        case .not(let jSONSchema, let core):
            fields = "    #warning(\"TODO:\")"
        case .reference(let jSONReference):
            fields = "    #warning(\"TODO:\")"
        case .fragment(let coreContext):
            fields = "    #warning(\"TODO:\")"
        }
        
        var output = """
        \(access) struct \(makeType(key)): \(model) {
            \(fields)
        }
        """
        return output
    }
    
    // MARK: Object
    
    private func makeObject(_ key: String, _ coreContext: JSONSchema.CoreContext<JSONTypeFormat.ObjectFormat>, _ objectContext: JSONSchema.ObjectContext, level: Int) throws -> String {
        let type = makeType(key)
        var output = ""
        var nested: [String] = []
        
        if let description = coreContext.description, !description.isEmpty {
            output += "/// \(description)\n"
        }
        output += "\(access) struct \(type): \(model) {\n"
        let keys = objectContext.properties.keys.sorted()
        var skippedKeys = Set<String>()
        // TODO: find a better way to order keys
        for key in keys {
            let schema = objectContext.properties[key]!
            let isRequired = objectContext.requiredProperties.contains(key)
            do {
                let generated = try makeProperty(key: key, schema: schema, isRequired: isRequired, level: level)
                output += generated.property.shiftedRight(count: 4)
                if let object = generated.nested {
                    nested.append(object)
                }
                output += "\n"
            } catch {
                skippedKeys.insert(key)
                #warning("TEMP")
                output += "    #warning(\"Failed to generate property for \(key)\")\n"
                print("ERROR: Failed to generate property \(error)")
            }
        }

        for nested in nested {
            output += "\n"
            output += nested
            output += "\n"
        }

        let hasCustomCodingKeys = keys.contains { makeParameter(sanitizedKey($0)) != $0 }
        if hasCustomCodingKeys {
            output += "\n"
            output += "    private enum CodingKeys: String, CodingKey {\n"
            for key in keys where !skippedKeys.contains(key) {
                let parameter = makeParameter(sanitizedKey(key))
                if parameter == key {
                    output += "        case \(parameter)\n"
                } else {
                    output += "        case \(parameter) = \"\(key)\"\n"
                }
            }
            output +=  "    }\n"
        }
        
        output += "}"
        return output.shiftedRight(count: level * 4)
    }
    
    private struct GeneratedProperty {
        var property: String
        var nested: String?
    }
    
    /// Generates properties, including support for more complex constucts that might require generating
    /// nested objects.
    private func makeProperty(key: String, schema: JSONSchema, isRequired: Bool, level: Int) throws -> GeneratedProperty {
        let key = sanitizedKey(key)
        switch schema {
        case .object(let coreContext, _):
            let nested = try makeSchema(for: key, schema: schema, level: level + 1)
            let property = makeSimpleProperty(name: key, type: makeType(key), context: coreContext, isRequired: isRequired)
            return GeneratedProperty(property: property, nested: nested)
        case .array(let coreContext, let arrayContext):
            guard let item = arrayContext.items else {
                throw GeneratorError("Missing array item type")
            }
            if let type = try? getSimpleType(for: item) {
                let property = makeSimpleProperty(name: key, type: type, context: coreContext, isRequired: isRequired)
                return GeneratedProperty(property: property)
            }
            let name = key + "Item"
            let nested = try makeSchema(for: name, schema: item, level: level + 1)
            let property = makeSimpleProperty(name: name, type: "[\(makeType(name))]", context: coreContext, isRequired: isRequired)
            return GeneratedProperty(property: property, nested: nested)
        default:
            let type = try getSimpleType(for: schema)
            let property = makeSimpleProperty(name: key, type: type, context: schema.coreContext, isRequired: isRequired)
            return GeneratedProperty(property: property)
        }
    }
    
    /// Renderes simple properties on an object that are using built-in types or existing references.
    ///
    /// - warning: Doesn't handle nested object or `oneOf` and similar constructs.
    private func makeSimpleProperty(name: String, type: String, context: JSONSchemaContext?, isRequired: Bool) -> String {
        var output = ""
        if let context = context {
            output += makeHeader(for: context, isShort: true)
        }
        let nullable = context?.nullable ?? false // `context` is null for references
        let modifier = (isRequired && nullable) ? "" : "?"
        let property = makeParameter(name)
        output += "\(access) var \(property): \(type)\(modifier)"
        return output
    }
    
    // TODO: Add support for deprecated fields
    private func makeHeader(for context: JSONSchemaContext, isShort: Bool) -> String {
        var output = ""
        if let description = context.description, !description.isEmpty {
            for line in description.split(separator: "\n") {
                output += "/// \(line)\n"
            }
        }
        if let example = context.example?.value {
            let value = "\(example)"
            if value.count > 1 { // Only display if it's something substantial
                if !output.isEmpty {
                    output += "///\n"
                }
                output += "/// Example: \(example)\n"
            }
        }
        return output
    }
    
    // MARK: Typealiases
            
    private func makeTypealiasArray(_ name: String, _ coreContext: JSONSchema.CoreContext<JSONTypeFormat.ArrayFormat>, _ arrayContext: JSONSchema.ArrayContext) throws -> String {
        var output = ""
        output += makeHeader(for: coreContext, isShort: true)
        guard let items = arrayContext.items else {
            throw GeneratorError("Missing array item type")
        }
        output += "typealias \(makeType(name)) = \(try getSimpleType(for: items))"
        return output
    }
        
    private func makeTypealiasPrimitive<T>(name: String, json: JSONSchema, context: JSONSchema.CoreContext<T>) throws -> String {
        var output = ""
        output += makeHeader(for: context, isShort: false)
        output += "\(access) typealias \(makeType(name)) = \(try getSimpleType(for: json))\n"
        return output
    }
    
    // MARK: Misc
    
    private func getSimpleType(for json: JSONSchema) throws -> String {
        switch json {
        case .boolean: return "Bool"
        case .number: return "Double"
        case .integer: return "Int"
        case .string(let coreContext, _):
            switch coreContext.format {
            case .dateTime:
                return "Date"
            case .other(let other):
                if other == "uri" {
                    return "URL"
                }
            default: break
            }
            return "String"
        case .object(let coreContext, let objectContext):
            throw GeneratorError("`object` is not supported: \(coreContext)")
        case .array(let coreContext, let arrayContext):
            guard let items = arrayContext.items else {
                throw GeneratorError("Missing array item type")
            }
            return "[\(try getSimpleType(for: items))]"
        case .all(let of, _):
            throw GeneratorError("`allOf` is not supported: \(of)")
        case .one(let of, _):
            throw GeneratorError("`oneOf` is not supported: \(of)")
        case .any(let of, _):
            throw GeneratorError("`anyOf` is not supported: \(of)")
        case .not(let scheme, _):
            throw GeneratorError("`not` is not supported: \(scheme)")
        case .reference(let reference):
            switch reference {
            case .internal(let ref):
                guard let name = ref.name else {
                    throw GeneratorError("Internal reference name is missing: \(ref)")
                }
                return makeType(name)
            case .external(let url):
                throw GeneratorError("External references are not supported: \(url)")
            }
        case .fragment(let coreContext):
            throw GeneratorError("Fragments are not supported")
        }
    }
    
    // MARK: oneOf
    
    private func makeOneOf(name: String, _ schemas: [JSONSchema]) throws -> String {
        var output = "\(access) enum \(makeType(name)): \(model) {\n"
        for schema in schemas {
            let type = try getSimpleType(for: schema)
            output += "    case \(makeParameter(type))(\(type))\n"
        }
        output += "\n"
        
        func makeInitFromDecoder() throws -> String {
            var output = """
            \(access) init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()\n
            """
            output += "    "
            
            for schema in schemas {
                let type = try getSimpleType(for: schema)
                output += """
                if let value = try? container.decode(\(type).self) {
                        self = .\(makeParameter(type))(value)
                    } else
                """
                output += " "
            }
            output += """
            {
                    throw URLError(.unknown) // Should never happen
                }
            }
            """
            return output
        }
        
        output += try makeInitFromDecoder().shiftedRight(count: 4)
        output += "\n}\n"
        return output
    }
}

private func sanitizedKey(_ key: String) -> String {
    if key.first == "+" {
        return "plus\(key.dropFirst())"
    }
    if key.first == "-" {
        return "minus\(key.dropFirst())"
    }
    return key
}

struct GeneratorError: Error, LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }
    
    var errorDescription: String? {
        message
    }
}
