// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit
import Foundation

extension Generate {
    func generateSchemas(for spec: OpenAPI.Document) -> String {
        var output = """
        // Auto-generated
        
        import Foundation\n\n
        """
        for (key, schema) in spec.components.schemas {
            output += makeSchema(for: key, schema: schema)
            output += "\n\n"
        }
        return output
    }
    
    private func makeSchema(for key: OpenAPI.ComponentKey, schema: JSONSchema) -> String {
        
        
        // TODO: Generate struct/classes based on how many fields or what?
        var fields = ""
        switch schema {
        case .boolean(let coreContext):
            fields = "    #warning(\"TODO:\")"
        case .number(let coreContext, let numericContext):
            fields = "    #warning(\"TODO:\")"
        case .integer(let coreContext, let integerContext):
            fields = "    #warning(\"TODO:\")"
        case .string(let coreContext, _):
            return makeString(key, coreContext)
        case .object(let coreContext, let objectContext):
            fields = "    #warning(\"TODO:\")"
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
        
        var output = """
        \(access) struct \(makeType(key.rawValue)) {
        \(fields)
        }
        """
        return output
    }
    
    private func makeString(_ key: OpenAPI.ComponentKey, _ coreContext: JSONSchema.CoreContext<JSONTypeFormat.StringFormat>) -> String {
        let type = makeType(key.rawValue)
        var output = ""
        if let description = coreContext.description, !description.isEmpty {
            output += "/// \(description)\n"
        }
        if let example = coreContext.example?.value as? String, !example.isEmpty {
            if !output.isEmpty {
                output += "///\n"
            }
            output += "/// - example: \(example)\n"
        }
        
        switch coreContext.format {
        case .dateTime:
            output += "typealias \(type) = Date"
        case .other(let other):
            if other == "uri" {
                output += "typealias \(type) = URL"
            }
        default:
            output += "typealias \(type) = String"
        }
        return output
    }
}
