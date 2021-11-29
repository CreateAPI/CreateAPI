// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation

// TODO: Allow to specify Codable/Decodable
// TODO: Add mechanism to pass options (with --option to override)
// TODO: Add an option to skip comments
// TODO: Option to disable custom key generation
// TODO: Add support for deprecated fields
// TODO: Do something about NullableSimpleUser (best generic approach)
// TODO: Get rid of remainig typealiases
// TODO: Add verbose mode
// TODO: Add warnings for unsupported features
// TODO: Inline typealias for array
// TODO: Make inline-typealias an option
// TODO: Add an option to parallellize

extension Generate {
    func generateSchemas(for spec: OpenAPI.Document) -> String {
        currentSpec = spec
        
        var output = """
        // Auto-generated
        
        import Foundation\n\n
        """
        
        let startTime = CFAbsoluteTimeGetCurrent()
        if verbose {
            print("Start generating schemas (\(spec.components.schemas.count))")
        }
        
        let schemas = Array(spec.components.schemas)
        var generated = Array<String?>(repeating: nil, count: schemas.count)
        let lock = NSLock()
        concurrentPerform(on: schemas) { index, item in
            let (key, schema) = schemas[index]
            do {
                if let entry = try makeParent(name: TypeName(key), schema: schema, level: 0) {
                    lock.lock()
                    generated[index] = entry
                    lock.unlock()
                }
            } catch {
                print("ERROR: Failed to generate entity for \(key): \(error)")
            }
        }

        for entry in generated where entry != nil {
            output += entry!
            output += "\n\n"
        }
        
        if isAnyJSONUsed {
            output += "\n"
            output += anyJSON
            output += "\n"
        }
        
        output += "\n"
        output += stringCodingKey
        output += "\n"
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        if verbose {
            print("Generated schemas in \(timeElapsed) s.")
        }
        
        return output
    }

    // Recursively creates a type: `struct`, `class`, `enum` – depending on the
    // schema and the user options. Primitive types often used in specs to reuse
    // documentation are inlined.
    private func makeParent(name: TypeName, schema: JSONSchema, level: Int) throws -> String? {
        switch schema {
        case .boolean, .number, .integer:
            return nil // Inline
        case .string(let coreContext, _):
            if isEnum(schema) {
                return try makeEnum(name: name, coreContext: coreContext)
            }
            return nil // Inline 'String'
        case .object(let coreContext, let objectContext):
            return try makeObject(name: name, coreContext, objectContext, level: level)
        case .array(let coreContext, let arrayContext):
            return try makeTypealiasArray(name, coreContext, arrayContext)
        case .all(let of, _):
            return try makeAnyOf(name: name, of, level: level)
        case .one(let of, _):
            return try makeOneOf(name: name, of, level: level)
        case .any(let of, _):
            return try makeAnyOf(name: name, of, level: level)
        case .not:
            throw GeneratorError("`not` is not supported: \(name)")
        case .reference:
            return nil // Can't appear in this context
        case .fragment:
            return nil // Can't appear in this context
        }
    }
    
    private struct Property {
        // Example: "files"
        let name: PropertyName
        // Example: "[File]"
        let type: String
        let isOptional: Bool
        let context: JSONSchemaContext?
        var nested: String?
    }
        
    private func makeProperty(key: String, schema: JSONSchema, isRequired: Bool, level: Int) throws -> Property {
        func child(name: PropertyName, type: String, context: JSONSchemaContext?, nested: String? = nil) -> Property {
            assert(context != nil) // context is null for references, but the caller needs to dereference first
            let nullable = context?.nullable ?? true
            return Property(name: name, type: type, isOptional: !isRequired || nullable, context: context, nested: nested)
        }
        
        let propertyName = PropertyName(key)
        switch schema {
        case .object(let coreContext, let objectContext):
            if objectContext.properties.isEmpty, let additional = objectContext.additionalProperties {
                switch additional {
                case .a:
                    return child(name: propertyName, type: "[String: AnyJSON]", context: coreContext)
                case .b(let schema):
                    let nestedTypeName = TypeName(key).appending("Item")
                    let nested = try makeParent(name: nestedTypeName, schema: schema, level: level + 1)
                    return child(name: propertyName, type: "[String: \(nestedTypeName)]", context: coreContext, nested: nested)
                }
            }
            let type = TypeName(key)
            let nested = try makeParent(name: type, schema: schema, level: level + 1)
            return child(name: propertyName, type: type.rawValue, context: coreContext, nested: nested)
        case .array(let coreContext, let arrayContext):
            guard let item = arrayContext.items else {
                throw GeneratorError("Missing array item type")
            }
            if let type = try? getSimpleType(for: item) {
                return child(name: propertyName, type: "[\(type)]", context: coreContext)
            }
            let name = TypeName(key).appending("Item")
            let nested = try makeParent(name: name, schema: item, level: level + 1)
            return child(name: propertyName, type: "[\(name)]", context: coreContext, nested: nested)
        case .all, .one, .any:
            let name = TypeName(key)
            let nested = try makeParent(name: name, schema: schema, level: level + 1)
            return child(name: propertyName, type: name.rawValue, context: schema.coreContext, nested: nested)
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
            return child(name: propertyName, type: type, context: context)
        }
    }
    
    private func makeNested(for children: [Property]) -> String? {
        let nested = children.compactMap({ $0.nested })
        guard !nested.isEmpty else { return nil }
        return nested.joined(separator: "\n\n")
    }
    
    // MARK: Object
    
    private func makeObject(name: TypeName, _ coreContext: JSONSchema.CoreContext<JSONTypeFormat.ObjectFormat>, _ objectContext: JSONSchema.ObjectContext, level: Int) throws -> String {
        var output = ""
        var nested: [String] = []
        
        output += makeHeader(for: coreContext)
        output += "\(access) struct \(name): \(model) {\n"
        let keys = objectContext.properties.keys.sorted()
        var properties: [String: Property] = [:]
        var skippedKeys = Set<String>()
        for key in keys {
            let schema = objectContext.properties[key]!
            let isRequired = objectContext.requiredProperties.contains(key)
            do {
                properties[key] = try makeProperty(key: key, schema: schema, isRequired: isRequired, level: level)
            } catch {
                skippedKeys.insert(key)
                print("ERROR: Failed to generate property \(error)")
            }
        }
    
        // TODO: Find a way to preserve the order of keys
        for key in keys {
            guard let property = properties[key] else { continue }
            output += makeProperty(for: property).shiftedRight(count: 4)
            if let object = property.nested {
                nested.append(object)
            }
            output += "\n"
        }

        for nested in nested {
            output += "\n"
            output += nested
            output += "\n"
        }
        
        if !properties.isEmpty {
            output += "\n"
            output += "    \(access) init(from decoder: Decoder) throws {\n"
            output += "        let values = try decoder.container(keyedBy: StringCodingKey.self)\n"
            for key in keys {
                guard let property = properties[key] else { continue }
                let decode = property.isOptional ? "decodeIfPresent" : "decode"
                output += "        self.\(property.name) = try values.\(decode)(\(property.type).self, forKey: \"\(key)\")\n"
            }
            output += "    }\n"
        }
        
        
        // TODO: Add this an an options
//        let hasCustomCodingKeys = keys.contains { PropertyName($0).rawValue != $0 }
//        if hasCustomCodingKeys {
//            output += "\n"
//            output += "    private enum CodingKeys: String, CodingKey {\n"
//            for key in keys where !skippedKeys.contains(key) {
//                let parameter = PropertyName(key).rawValue
//                if parameter == key {
//                    output += "        case \(parameter)\n"
//                } else {
//                    output += "        case \(parameter) = \"\(key)\"\n"
//                }
//            }
//            output +=  "    }\n"
//        }
        
        output += "}"
        return output.shiftedRight(count: level > 0 ? 4 : 0)
    }
    
    /// Example: "public var files: [Files]?"
    private func makeProperty(for child: Property) -> String {
        var output = ""
        if let context = child.context {
            output += makeHeader(for: context)
        }
        output += "\(access) var \(child.name): \(child.type)\(child.isOptional ? "?" : "")"
        return output
    }
    
    /// Adds title, description, examples, etc.
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
            let value: String
            func format(dictionary: [String: Any]) -> String {
                let values = dictionary.keys.sorted().map { "  \"\($0)\": \"\(dictionary[$0]!)\"" }
                return "{\n\(values.joined(separator: ",\n"))\n}"
            }
            
            if JSONSerialization.isValidJSONObject(example) {
                let data = try? JSONSerialization.data(withJSONObject: example, options: [.prettyPrinted, .sortedKeys])
                value = String(data: data ?? Data(), encoding: .utf8) ?? ""
            } else {
                value = "\(example)"
            }
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
            
    private func makeTypealiasArray(_ name: TypeName, _ coreContext: JSONSchema.CoreContext<JSONTypeFormat.ArrayFormat>, _ arrayContext: JSONSchema.ArrayContext) throws -> String {
        guard let item = arrayContext.items else {
            throw GeneratorError("Missing array item type")
        }
        if let type = try? getSimpleType(for: item) {
            return "\(access) typealias \(name) = \(type)"
        }
        // Requres generation of a separate type
        var output = ""
        let itemName = name.appending("Item")
        output += "\(access) typealias \(name) = [\(itemName)]\n\n"
        output += (try makeParent(name: itemName, schema: item, level: 0)) ?? ""
        return output
    }
    
    // MARK: Enums
    
    private func makeEnum(name: TypeName, coreContext: JSONSchemaContext) throws -> String {
        let values = (coreContext.allowedValues ?? [])
            .compactMap { $0.value as? String }
        guard !values.isEmpty else {
            throw GeneratorError("Enum \(name) has no values")
        }
        
        var output = ""
        output += makeHeader(for: coreContext)
        output += "\(access) enum \(name): String, Codable, CaseIterable {\n"
        for value in values {
            output += "    case \(PropertyName(value)) = \"\(value)\"\n"
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
                return TypeName(name).rawValue
            case .external(let url):
                throw GeneratorError("External references are not supported: \(url)")
            }
        case .fragment:
            setAnyJsonNeeded()
            return "AnyJSON"
        }
    }
    
    // MARK: oneOf/anyOf/allOf
    
    // TODO: Special-case double/string?
    private func makeOneOf(name: TypeName, _ schemas: [JSONSchema], level: Int) throws -> String {
        let types = makeTypeNames(for: schemas)
        let children: [Property] = try zip(types, schemas).map { type, schema in
            try makeProperty(key: type, schema: schema, isRequired: true, level: level)
        }
        
        var output = "\(access) enum \(name): \(model) {\n"
        for child in children {
            output += "    case \(child.name)(\(child.type))\n"
        }
        output += "\n"
        
        func makeInitFromDecoder() throws -> String {
            var output = """
            \(access) init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()\n
            """
            output += "    "
            
            for child in children {
                output += """
                if let value = try? container.decode(\(child.type).self) {
                        self = .\(child.name)(value)
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
        
        if let nested = makeNested(for: children) {
            output += "\n\n"
            output += nested
        }

        output += "\n}"
        output = output.shiftedRight(count: level > 0 ? 4 : 0)
        return output
    }
        
    private func makeAnyOf(name: TypeName, _ schemas: [JSONSchema], level: Int) throws -> String {
        let types = makeTypeNames(for: schemas)
        let children: [Property] = try zip(types, schemas).map { type, schema in
            try makeProperty(key: type, schema: schema, isRequired: true, level: level)
        }
        
        var output = "\(access) struct \(name): \(model) {\n"
        
        for child in children {
            output += "    \(access) var \(child.name): \(child.type)?\n"
        }
        output += "\n"
    
        func makeInitFromDecoder() throws -> String {
            var output = """
            \(access) init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()\n
            """
            
            for child in children {
                output += "    self.\(child.name) = try? container.decode(\(child.type).self)\n"
            }
            output += "}"
            return output
        }
        
        output += try makeInitFromDecoder().shiftedRight(count: 4)
        
        
        if let nested = makeNested(for: children) {
            output += "\n\n"
            output += nested
        }
        
        output += "\n}"
        output = output.shiftedRight(count: level > 0 ? 4 : 0)
        return output
    }
    
    private func makeTypeNames(for schemas: [JSONSchema]) -> [String] {
        var types = Array<String?>(repeating: nil, count: schemas.count)
        
        // Assign known types (references, primitive)
        for (index, schema) in schemas.enumerated() {
            types[index] = try? getSimpleType(for: schema)
        }
        
        // Generate names for anonymous nested objects
        let unnamedCount = types.filter { $0 == nil }.count
        var genericCount = 1
        func makeNextGenericName() -> String {
            defer { genericCount += 1 }
            return "Object\((unnamedCount == 1 && genericCount == 1) ? "" : "\(genericCount)")"
        }
        for (index, _) in schemas.enumerated() {
            if types[index] == nil {
                types[index] = makeNextGenericName()
            }
        }
        
        // Disambiguate arrays
        func parameter(for type: String) -> String {
            let isArray = type.starts(with: "[") // TODO: Refactor
            return "\(PropertyName(type))\(isArray ? "s" : "")"
        }
        return types.map { parameter(for: $0!) }
    }
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
