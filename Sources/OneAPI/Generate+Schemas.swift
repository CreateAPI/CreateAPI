// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation

// TODO: Use SwiftFormat to align stuff?
// TODO: Generate initializer
// TODO: Allow to specify Codable/Decodable
// TODO: Add an option to skip comments
// TODO: Option to disable custom key generation

extension Generate {
    func generateSchemas(for spec: OpenAPI.Document) -> String {
        currentSpec = spec
        
        var output = """
        // Auto-generated
        
        import Foundation\n\n
        """
        
        for (key, schema) in spec.components.schemas {
            do {
                let entry = try makeParent(for: key.rawValue, schema: schema, level: 0)
                if !entry.isEmpty {
                    output += entry
                    output += "\n\n"
                }
            } catch {
                print("WARNING: \(error)")
            }
        }
        
        if isAnyJSONUsed {
            output += "\n"
            output += anyJSON
            output += "\n"
        }
        
        return output
    }

    private func makeParent(for key: String, schema: JSONSchema, level: Int) throws -> String {
        // TODO: Generate struct/classes based on how many fields or what?
        var fields = ""
        switch schema {
        case .boolean, .number, .integer:
            return "" // Inline them
        case .string(let coreContext, _):
            return try makeTypealiasPrimitive(name: key, json: schema, context: coreContext)
        case .object(let coreContext, let objectContext):
            return try makeObject(key, coreContext, objectContext, level: level)
        case .array(let coreContext, let arrayContext):
            return try makeTypealiasArray(key, coreContext, arrayContext)
        case .all(let of, _):
            return try makeAnyOf(name: key, of, level: level)
        case .one(let of, _):
            return try makeOneOf(name: key, of, level: level)
        case .any(let of, _):
            return try makeAnyOf(name: key, of, level: level)
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
    
    private struct Child {
        // "files"
        let name: String
        // "[File]"
        let type: String
        let isOptional: Bool
        let context: JSONSchemaContext?
        var nested: String?
    }
    
    private func makeChild(key: String, schema: JSONSchema, isRequired: Bool, level: Int) throws -> Child {
        func child(named name: String, type: String, context: JSONSchemaContext?, nested: String? = nil) -> Child {
            assert(context != nil) // context is null for references, but the caller needs to dereference
            let nullable = context?.nullable ?? true
            return Child(name: makeParameter(name), type: type, isOptional: !isRequired || nullable, context: context, nested: nested)
        }
        
        let key = sanitizedKey(key)
        switch schema {
        case .object(let coreContext, let objectContext):
            if objectContext.properties.isEmpty, let additional = objectContext.additionalProperties {
                switch additional {
                case .a:
                    return child(named: key, type: "[String: AnyJSON]", context: coreContext)
                case .b(let schema):
                    let name = key + "Item"
                    let nested = try makeParent(for: name, schema: schema, level: level + 1)
                    return child(named: key, type: "[String: \(makeType(name))]", context: coreContext, nested: nested)
                }
            }
            let nested = try makeParent(for: key, schema: schema, level: level + 1)
            return child(named: key, type: makeType(key), context: coreContext, nested: nested)
        case .array(let coreContext, let arrayContext):
            guard let item = arrayContext.items else {
                throw GeneratorError("Missing array item type")
            }
            if let type = try? getSimpleType(for: item) {
                return child(named: key, type: "[\(type)]", context: coreContext)
            }
            let name = key + "Item"
            let nested = try makeParent(for: name, schema: item, level: level + 1)
            return child(named: key, type: "[\(makeType(name))]", context: coreContext, nested: nested)
        case .all, .one, .any:
            let name = key
            let nested = try makeParent(for: name, schema: schema, level: level + 1)
            return child(named: key, type: makeType(name), context: schema.coreContext, nested: nested)
        case .not(let jSONSchema, let core):
            throw GeneratorError("`not` properties are not supported")
        default:
            var context: JSONSchemaContext?
            switch schema {
            case .reference(let ref, _):
                guard let spec = currentSpec else {
                    throw GeneratorError("Current spec is missing (internal error)")
                }
                let deref = try ref.dereferenced(in: spec.components)
                context = deref.coreContext
            default:
                context = schema.coreContext
            }
            let type = try getSimpleType(for: schema)
            return child(named: key, type: type, context: context)
        }
    }
    
    // MARK: Object
    
    private func makeObject(_ key: String, _ coreContext: JSONSchema.CoreContext<JSONTypeFormat.ObjectFormat>, _ objectContext: JSONSchema.ObjectContext, level: Int) throws -> String {
        let type = makeType(key)
        var output = ""
        var nested: [String] = []
        
        output += makeHeader(for: coreContext)
        output += "\(access) struct \(type): \(model) {\n"
        let keys = objectContext.properties.keys.sorted()
        var skippedKeys = Set<String>()
    
        // TODO: Find a way to preserve the order of keys
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
                output += "    #warning(\"Failed to generate property '\(key)'\")\n"
                print("ERROR: Failed to generate property \(error)")
            }
        }

        for nested in nested {
            output += "\n"
            output += nested
            output += "\n"
        }
        
        // TODO: Is generating init/deinit faster for compilation?
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
        return output.shiftedRight(count: level > 0 ? 4 : 0)
    }
    
    private struct GeneratedProperty {
        var property: String
        var nested: String?
    }
    
    /// Generates properties, including support for more complex constucts that might require generating
    /// nested objects.
    private func makeProperty(key: String, schema: JSONSchema, isRequired: Bool, level: Int) throws -> GeneratedProperty {
        let child = try makeChild(key: key, schema: schema, isRequired: isRequired, level: level)
        let property = makeSimpleProperty(for: child)
        return GeneratedProperty(property: property, nested: child.nested)
    }
    
    /// Renderes simple properties on an object that are using built-in types or existing references.
    ///
    /// - warning: Doesn't handle nested object or `oneOf` and similar constructs.
    private func makeSimpleProperty(name: String, type: String, context: JSONSchemaContext?, isRequired: Bool) -> String {
        var output = ""
        if let context = context {
            output += makeHeader(for: context)
        }
        assert(context != nil) // context is null for references, but the caller needs to dereference
        let nullable = context?.nullable ?? true
        let modifier = (isRequired && !nullable) ? "" : "?"
        let property = makeParameter(name)
        output += "\(access) var \(property): \(type)\(modifier)"
        return output
    }
    
    private func makeSimpleProperty(for child: Child) -> String {
        var output = ""
        if let context = child.context {
            output += makeHeader(for: context)
        }
        output += "\(access) var \(child.name): \(child.type)\(child.isOptional ? "?" : "")"
        return output
    }
    
    // TODO: Add support for deprecated fields
    private func makeHeader(for context: JSONSchemaContext) -> String {
        var output = ""
        if let title = context.title, !title.isEmpty {
            output += "/// \(title)\n"
        }
        if let description = context.description, !description.isEmpty, description != context.title {
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
                let lines = value.split(separator: "\n")
                if lines.count == 1 {
                    output += "/// Example: \(value)\n"
                } else {
                    output += "/// Example:\n\n"
                    for line in lines {
                        output += "/// \(line)\n"
                    }
                }
            }
        }
        return output
    }
    
    // MARK: Typealiases
            
    private func makeTypealiasArray(_ key: String, _ coreContext: JSONSchema.CoreContext<JSONTypeFormat.ArrayFormat>, _ arrayContext: JSONSchema.ArrayContext) throws -> String {
        guard let item = arrayContext.items else {
            throw GeneratorError("Missing array item type")
        }
        if let type = try? getSimpleType(for: item) {
            return "\(access) typealias \(makeType(key)) = \(type)"
        }
        // Requres generation of a separate type
        var output = ""
        let name = makeType(key) + "Item"
        output += "\(access) typealias \(makeType(key)) = [\(name)]\n\n"
        output += try makeParent(for: name, schema: item, level: 0)
        return output
    }
        
    private func makeTypealiasPrimitive<T>(name: String, json: JSONSchema, context: JSONSchema.CoreContext<T>) throws -> String {
        if isEnum(json) {
            return try makeEnum(name: name, coreContext: context)
        }
        
        return ""
                
        // Starting with the new version, we just inline these
//        var output = ""
//        output += makeHeader(for: context)
//        output += "\(access) typealias \(makeType(name)) = \(try getSimpleType(for: json))"
//        return output
    }
    
    private func makeEnum(name: String, coreContext: JSONSchemaContext) throws -> String {
        let values = (coreContext.allowedValues ?? [])
            .compactMap { $0.value as? String }
        guard !values.isEmpty else {
            throw GeneratorError("Enum \(name) has no values")
        }
        
        var output = ""
        output += makeHeader(for: coreContext)
        output += "\(access) enum \(makeType(name)): String, Codable, CaseIterable {\n"
        for value in values {
            output += "    case \(makeParameter(value)) = \"\(value)\"\n"
        }
        output += "}"
        return output
    }
    
    private func isInlinable(_ schema: JSONSchema) -> Bool {
        !isEnum(schema)
    }
    
    private func isEnum(_ schema: JSONSchema) -> Bool {
        if case .string(let coreContext, _) = schema, coreContext.allowedValues != nil {
            return true
        }
        return false
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
        case .object(let coreContext, _):
            throw GeneratorError("`object` is not supported: \(coreContext)")
        case .array(_, let arrayContext):
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
        case .reference(let reference, _):
            switch reference {
            case .internal(let ref):
                if let deref = try? reference.dereferenced(in: currentSpec!.components),
                   let type = try? getSimpleType(for: deref.jsonSchema),
                   isInlinable(deref.jsonSchema) {
                    return type // Inline simple types
                }
                guard let name = ref.name else {
                    throw GeneratorError("Internal reference name is missing: \(ref)")
                }
                return makeType(name)
            case .external(let url):
                throw GeneratorError("External references are not supported: \(url)")
            }
        case .fragment:
            setAnyJsonNeeded()
            return "AnyJSON"
        }
    }
    
    // MARK: oneOf
    
    // TODO: Add support for discs
    // TODO: Add support for nesting
    // TODO: Special-case double/string?
    private func makeOneOf(name: String, _ schemas: [JSONSchema], level: Int) throws -> String {
        func parameter(for type: String) -> String {
            let isArray = type.starts(with: "[") // TODO: Refactor
            return "\(makeParameter(type))\(isArray ? "s" : "")"
        }
        
        var output = "\(access) enum \(makeType(name)): \(model) {\n"
        for schema in schemas {
            let type = try getSimpleType(for: schema)
            output += "    case \(parameter(for: type))(\(type))\n"
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
                        self = .\(parameter(for: type))(value)
                    } else
                """
                output += " "
            }
            output += """
            {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Failed to intialize \(name)")
                }
            }
            """
            return output
        }
        
        output += try makeInitFromDecoder().shiftedRight(count: 4)
        output += "\n}"
        output = output.shiftedRight(count: level > 0 ? 4 : 0)
        return output
    }
    
    private func makeAnyOf(name: String, _ schemas: [JSONSchema], level: Int) throws -> String {
        func parameter(for type: String) -> String {
            let isArray = type.starts(with: "[") // TODO: Refactor
            return "\(makeParameter(type))\(isArray ? "s" : "")"
        }
        
        var output = "\(access) struct \(makeType(name)): \(model) {\n"
        
        for schema in schemas {
            let type = try getSimpleType(for: schema)
            output += "    \(access) var \(parameter(for: type)): \(type)?\n"
        }
        output += "\n"
    
        func makeInitFromDecoder() throws -> String {
            var output = """
            \(access) init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()\n
            """
            
            for schema in schemas {
                let type = try getSimpleType(for: schema)
                output += "    self.\(parameter(for: type)) = try? container.decode(\(type).self)\n"
            }
            output += "}"
            return output
        }
        
        output += try makeInitFromDecoder().shiftedRight(count: 4)
        output += "\n}"
        output = output.shiftedRight(count: level > 0 ? 4 : 0)
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

private var currentSpec: OpenAPI.Document? // TODO: Refactor
private var isAnyJSONUsed = false
private let lock = NSLock()

func setAnyJsonNeeded() {
    lock.lock()
    isAnyJSONUsed = true
    lock.unlock()
}
