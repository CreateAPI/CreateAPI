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
            output += makeSchema(for: key.rawValue, schema: schema)
            output += "\n"
        }
        return output
    }

    private func makeSchema(for key: String, schema: JSONSchema, isStandalone: Bool = true) -> String {
        // TODO: Generate struct/classes based on how many fields or what?
        var fields = ""
        switch schema {
        case .boolean(let coreContext):
            return makePrimitive(name: key, jsonType: schema.jsonType, context: coreContext, isStandalone: isStandalone)
        case .number(let coreContext, _):
            return makePrimitive(name: key, jsonType: schema.jsonType, context: coreContext, isStandalone: isStandalone)
        case .integer(let coreContext, _):
            return makePrimitive(name: key, jsonType: schema.jsonType, context: coreContext, isStandalone: isStandalone)
        case .string(let coreContext, _):
            return makePrimitive(name: key, jsonType: schema.jsonType, context: coreContext, isStandalone: isStandalone)
        case .object(let coreContext, let objectContext):
            return makeObject(key, coreContext, objectContext)
        case .array(let coreContext, let arrayContext):
            fields = "    #warning(\"TODO:\")"
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
        
        if isStandalone {
            return fields
        }

        var output = """
        \(access) struct \(makeType(key)) {
            \(fields)
        }
        """
        return output
    }
    
    private func makeObject(_ key: String, _ coreContext: JSONSchema.CoreContext<JSONTypeFormat.ObjectFormat>, _ objectContext: JSONSchema.ObjectContext) -> String {
        let type = makeType(key)
        var output = ""
        if let description = coreContext.description, !description.isEmpty {
            output += "/// \(description)\n"
        }
        output += "\(access) struct \(type) {\n"
        let keys = objectContext.properties.keys.sorted()
        for key in keys {
            let value = objectContext.properties[key]!
            output += makeSchema(for: sanitizedKey(key), schema: value, isStandalone: false)
                .shiftedRight(count: 4)
            output += "\n"
        }
        let hasCustomCodingKeys = keys.contains { makeParameter(sanitizedKey($0)) != $0 }
        if hasCustomCodingKeys {
            output += "\n"
            output += "    private enum CodingKeys: String, CodingKey {\n"
            for key in keys {
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
        return output
    }

    private func makePrimitive<T>(
        name: String,
        jsonType: JSONType?,
        context: JSONSchema.CoreContext<T>,
        isStandalone: Bool
    ) -> String {
        var type: String
        switch jsonType! {
        case .boolean: type = "Bool"
        case .object: fatalError()
        case .array: fatalError()
        case .number: type = "Double"
        case .integer: type = "Int"
        case .string:
            type = "String"
            switch (context as! JSONSchema.CoreContext<JSONTypeFormat.StringFormat>).format {
            case .dateTime:
                type = "Date"
            case .other(let other):
                if other == "uri" {
                    type = "URL"
                }
            default: break
            }
        }
        
        var output = ""
        output += makeHeader(for: context, isStandalone: isStandalone)

        if isStandalone {
            output += "typealias \(makeType(name)) = \(type)"
        } else {
            output += "\(access) var \(makeParameter(name)): \(type)\(context.nullable ? "?" : "")"
        }
        return output
    }
     
    
    private func makeHeader<T>(for context: JSONSchema.CoreContext<T>, isStandalone: Bool) -> String {
        var output = ""
        if let description = context.description, !description.isEmpty {
            for line in description.split(separator: "\n") {
                output += "/// \(line)\n"
            }
        }
        if isStandalone, let example = context.example?.value {
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
