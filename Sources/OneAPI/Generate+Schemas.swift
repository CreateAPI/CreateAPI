// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit
import Foundation

// TODO: Generate initializer
extension Generate {
    func generateSchemas(for spec: OpenAPI.Document) -> String {
        var output = """
        // Auto-generated
        
        import Foundation\n\n
        """
        for (key, schema) in spec.components.schemas {
            do {
                output += try makeSchema(for: key.rawValue, schema: schema)
                output += "\n"
            } catch {
                print("WARNING: \(error)")
            }
        }
        return output
    }

    private func makeSchema(for key: String, schema: JSONSchema) throws -> String {
        // TODO: Generate struct/classes based on how many fields or what?
        var fields = ""
        switch schema {
        case .boolean(let coreContext):
            return try makePrimitive(name: key, json: schema, context: coreContext)
        case .number(let coreContext, _):
            return try makePrimitive(name: key, json: schema, context: coreContext)
        case .integer(let coreContext, _):
            return try makePrimitive(name: key, json: schema, context: coreContext)
        case .string(let coreContext, _):
            return try makePrimitive(name: key, json: schema, context: coreContext)
        case .object(let coreContext, let objectContext):
            return try makeObject(key, coreContext, objectContext, level: 0)
        case .array(let coreContext, let arrayContext):
            return try makeArray(key, coreContext, arrayContext)
        case .all(let of, let core):
            fields = "    #warning(\"TODO:\")"
        case .one(let of, let core):
            fields = "    #warning(\"TODO:\")"
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
        \(access) struct \(makeType(key)) {
            \(fields)
        }
        """
        return output
    }
    
    private func makeObject(_ key: String, _ coreContext: JSONSchema.CoreContext<JSONTypeFormat.ObjectFormat>, _ objectContext: JSONSchema.ObjectContext, level: Int) throws -> String {
        let type = makeType(key)
        var output = ""
        var nested = ""
        
        if let description = coreContext.description, !description.isEmpty {
            output += "/// \(description)\n"
        }
        output += "\(access) struct \(type) {\n"
        let keys = objectContext.properties.keys.sorted()
        var skipped = Set<String>()
        // TODO: make sure we handle nullable/required properly
        for key in keys {
            let value = objectContext.properties[key]!
            let isRequired = objectContext.requiredProperties.contains(key)
            do {
                if case .object(let coreContext, let objectContext) = value {
                    // Special handling for nested objects
                    let object = try makeObject(sanitizedKey(key), coreContext, objectContext, level: level + 1)
                    let ref = JSONSchema.reference(.internal(.component(name: key)))
                    let property = try makeProperty(name: key, json: ref, context: coreContext, isRequired: isRequired)
                    output += property
                    nested += object
                } else {
                    output += try makeProperty(name: key, json: value, context: value.coreContext, isRequired: isRequired)
                }
                output += "\n"
            } catch {
                skipped.insert(key)
                print("WARNING: \(error)")
            }
        }
        let hasCustomCodingKeys = keys.contains { makeParameter(sanitizedKey($0)) != $0 }
        if !nested.isEmpty {
            output += "\n"
            output += nested
        }
        if hasCustomCodingKeys {
            output += "\n"
            output += "    private enum CodingKeys: String, CodingKey {\n"
            for key in keys where !skipped.contains(key) {
                let parameter = makeParameter(sanitizedKey(key))
                if parameter == key {
                    output += "        case \(parameter)\n"
                } else {
                    output += "        case \(parameter) = \"\(key)\"\n"
                }
            }
            output +=  "    }\n"
        }
        output += "}\n"
        return output.shiftedRight(count: level * 4)
    }
    
    private func makeArray(_ name: String, _ coreContext: JSONSchema.CoreContext<JSONTypeFormat.ArrayFormat>, _ arrayContext: JSONSchema.ArrayContext) throws -> String {
        var output = ""
        output += makeHeader(for: coreContext, isShort: true)
        guard let items = arrayContext.items else {
            throw GeneratorError("Missing array item type")
        }
        output += "typealias \(makeType(name)) = \(try getType(for: items))"
        return output
    }
    
    private func getType(for json: JSONSchema) throws -> String {
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
            return "[\(try getType(for: items))]"
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
    
    /// Renderes properties of an object.
    private func makeProperty(name: String, json: JSONSchema, context: JSONSchemaContext?, isRequired: Bool) throws -> String {
        guard let context = context else {
            throw GeneratorError("Context is missing")
        }
            
        var output = makeHeader(for: context, isShort: true)
        let type = try getType(for: json)
        let modifier = (isRequired && !context.nullable) ? "" : "?"
        let property = makeParameter(sanitizedKey(name))
        output += "\(access) var \(property): \(type)\(modifier)"
        return output.shiftedRight(count: 4)
    }
        
    private func makePrimitive<T>(name: String, json: JSONSchema, context: JSONSchema.CoreContext<T>) throws -> String {
        var output = ""
        output += makeHeader(for: context, isShort: false)
        output += "typealias \(makeType(name)) = \(try getType(for: json))"
        return output
    }
    
    private func makeHeader(for context: JSONSchemaContext, isShort: Bool) -> String {
        var output = ""
        if let description = context.description, !description.isEmpty {
            for line in description.split(separator: "\n") {
                output += "/// \(line)\n"
            }
        }
        if !isShort, let example = context.example?.value {
            if !output.isEmpty {
                output += "///\n"
            }
            output += "/// - example: \(example)\n"
        }
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
