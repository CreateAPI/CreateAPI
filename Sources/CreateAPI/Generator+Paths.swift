// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Disambiguate Scheme/Package (but only if necessary?)
// TODO: Add support for query parametrs (separate struct?) https://swagger.io/docs/specification/describing-parameters/
//    - allowReserved
//    - components.parameters
//    - inline parameters
//    - constant parameters
//    - style
//    - explode
//    - deprecated
//    - path-level parameters
//    - common parameters in components (inline?)
// TODO: Add root "/"
// TODO: Add summary and description
// TODO: Figure out what to do with operationId
// TODO: Add a link to external docs
// TODO: Parse in: path parameters and support types other than just String
// TODO: Remove Markdown from description (or keep if it it looks OK - test)
// TODO: Add an option to generate a plain list of APIs instead of using namespaces
// TODO: Test that this enum description works enum: [user, poweruser, admin]
// TODO: Add an option to use operationId as method name
// TODO: Add support for deprecated methods
// TODO: Support path parameters like this GET /report.{format}
// TODO: Group operations by tags https://swagger.io/docs/specification/2-0/grouping-operations-with-tags/?sbsearch=tags
// TODO: Add operationId

// TODO: - Apply overridden names based on spec, not output file
// TODO: - Generate phantom ID types
// TODO: - Allow to override types for specific properties
// TODO: - Add in documentation additional context, eg inlyvalues from 100 to 500
// TODO: - Automatically apply more specific rename rules first
extension Generator {
    
    #warning("refactor")
    var access: String { options.access.isEmpty ? "" :  options.access + " " }
    
    func paths() -> String {
        startMeasuring("generating paths (\(spec.paths.count))")
        
        var output = templates.fileHeader
        
        #warning("TODO: replace with Get")
        output += "\nimport APIClient"
        output += "\n\n"
        output += [options.access, "enum", options.paths.namespace, "{}"].compactMap { $0 }.joined(separator: " ")
        
        // TODO: Only generate for one path
        
        output += "\n\n"

        var generated = Set<OpenAPI.Path>()
        
        // TODO: Add description and everything
        
        for path in spec.paths {
            guard !path.key.components.isEmpty else {
                continue
            }
            
            var components: [String] = []
            for (index, component) in path.key.components.enumerated() {
                components.append(component)
                let subpath = OpenAPI.Path(components)
                guard !generated.contains(subpath) else { continue }
                generated.insert(subpath)
                
                let component = components.last!
                let isLast = index == path.key.components.endIndex - 1
                let isTopLevel = components.count == 1
                let type = makeType(component)
                let isParameter = component.starts(with: "{")
                let stat = isTopLevel ? "static " : ""
                
                let extensionOf = ([options.paths.namespace] + components.dropLast().map(makeType)).joined(separator: ".")

                // TODO: percent-encode path?
                
                // TODO: Reuse type generation code
                
                if !isLast && spec.paths.contains(key: subpath) {
                    continue // Will be generated when the path is encountered
                }
                
                // TODO: refactor and add remaining niceness
                var generatedType = """
                    \(access)struct \(type) {
                        // \(subpath.rawValue)
                        \(access)let path: String\n
                """
                
                if isLast {
                    generatedType += """
                    \n\(makeMethods(for: path.value))\n
                    """
                }
                
                generatedType += """
                    }
                """
                
                if isParameter {
                    let parameter = PropertyName(component, options: .init())
                    output += """
                    extension \(extensionOf) {
                        \(access)\(stat)func \(parameter)(_ \(parameter): String) -> \(type) {
                            \(type)(path: \(isTopLevel ? "\"/\(component)/\"" : "path + \"/\"") + \(parameter))
                        }
                    
                    \(generatedType)
                    }\n\n
                    """
                } else {
                    output += """
                    extension \(extensionOf) {
                        \(access)\(stat)var \(PropertyName(type, options: .init())): \(type) {
                            \(type)(path: \(isTopLevel ? "\"/\(component)\"" : ("path + \"/\(components.last!)\"")))
                        }
                    
                    \(generatedType)
                    }\n\n
                    """
                }
            }
        }
        
//        output += "\n\n"
//        output += """
//        extension Request {
//            func id(_ id: String) -> Request {
//                var copy = self
//                copy.id = id
//                return copy
//            }
//        }
//        """
//        output += "\n\n"
        
        stopMeasuring("generating paths (\(spec.paths.count))")
        
        return output.indent(using: options)
    }
    
    // TODO: Add remaining methods
    private func makeMethods(for item: OpenAPI.PathItem) -> String {
        [
            item.get.flatMap { makeMethod(for: $0, method: "get") },
            item.post.flatMap { makeMethod(for: $0, method: "post") },
//            item.put.flatMap { makeMethod(for: $0, method: "put") },
//            item.patch.flatMap { makeMethod(for: $0, method: "patch") },
//            item.delete.flatMap { makeMethod(for: $0, method: "delete") },
//            item.options.flatMap { makeMethod(for: $0, method: "options") },
//            item.head.flatMap { makeMethod(for: $0, method: "head") },
//            item.trace.flatMap { makeMethod(for: $0, method: "trace") },
        ]
            .compactMap { $0 }
            .map { $0.indented }
            .joined(separator: "\n\n")
    }
    
    private func hasBody(_ method: String) -> Bool {
        ["put", "post", "patch"].contains(method)
    }
    
    // TODO: Add namespace to schems (package?)
    // TODO: Inject offset as a parameter
    // TODO: Add support for operationId
    // TODO: Add a way to disamiguate if responses have oneOf
    private func makeMethod(for operation: OpenAPI.Operation, method: String) -> String? {
        do {
            return try _makeMethod(for: operation, method: method)
        } catch {
            print("ERROR: Failed to generate path \(method) for \(operation.operationId ?? "\(operation)"): \(error)")
            return nil
        }
    }
    
    private func _makeMethod(for operation: OpenAPI.Operation, method: String) throws -> String {
        let response = try makeResponse(for: operation)
        var output = ""
        if options.comments.addSummary, let summary = operation.summary, !summary.isEmpty {
            for line in summary.split(separator: "\n") {
                output += "/// \(line)\n"
            }
        }
        var parameters: [String] = []
        if hasBody(method) {
            parameters.append("_ body: \(try makeRequestBody(for: operation))")
        }
        var call: [String] = ["path"]
        if hasBody(method) {
            call.append("body: body")
        }
        output += templates.method(name: method, parameters: parameters, returning: "Request<\(response)>", contents: ".\(method)(\(call.joined(separator: ", ")))")
        return output.indented
    }
    
    // TODO: Generate -parameter documentation
    // TODO: Automatically pick application/json
    // TODO: Add application/x-www-form-urlencoded support
    // TODO: Add text/plain support
    // TODO: Add binary support
    // TODO: Add "optional" support
    // TODO: Add "image*" support
    // TODO: Add anyOf, oneOf support
    // TODO: Add uploads support
    private func makeRequestBody(for operation: OpenAPI.Operation) throws -> String {
        guard let requestBody = operation.requestBody else {
            // TODO: Is is the correct handling?
            throw GeneratorError("ERROR: Request body is missing")
        }
        
        switch requestBody {
        case .a(let reference):
            guard let name = reference.name else {
                throw GeneratorError("Inalid reference")
            }
            guard let key = OpenAPI.ComponentKey(rawValue: name), let request = spec.components.requestBodies[key] else {
                throw GeneratorError("Failed to find a requesty body named \(name)")
            }
        
            if let content = request.content[.json] {
                // TODO: Add description
                // TODO: Parse example
                // TODO: Make sure this is correct
                switch content.schema {
                case .a(let reference):
                    // TODO: what about nested types?
                    return try makeProperty(key: "response", schema: JSONSchema.reference(reference), isRequired: true, in: Context(parents: [])).type
                case .b(let schema):
                    // TODO: what about nested types?
                    return try makeProperty(key: "response", schema: schema, isRequired: true, in: Context(parents: [])).type
                default:
                    throw GeneratorError("ERROR: response not handled \(operation.description ?? "")")
                }
            } else {
                throw GeneratorError("No supported content types: \(request.content.keys)")
            }
            
            #warning("TEMP")
            switch reference {
            case .internal(let reference):
                return reference.name ?? "Void"
            case .external(_):
                throw GeneratorError("External references are not supported")
            }
        case .b(let scheme):
            if scheme.content.values.isEmpty {
                return "Void"
            } else if let content = scheme.content.values.first {
                // TODO: Parse example
                switch content.schema {
                case .a(let reference):
                    // TODO: what about nested types?
                    return try makeProperty(key: "response", schema: JSONSchema.reference(reference), isRequired: true, in: Context(parents: [])).type
                case .b(let schema):
                    throw GeneratorError("ERROR: response inline scheme not handled \(operation.description ?? "")")
                default:
                    throw GeneratorError("ERROR: response not handled \(operation.description ?? "")")
                }
            } else {
                throw GeneratorError("More than one schema in content which is not currently supported")
            }
        }
    }
        
    // TODO: Add text/plain schema: type String support
    // TODO: Add inline array/dictionary responses
    // TODO: Generate proper nested response types (<PathComponent>Response)
    // TODO: application/pdf and other binary files
    // TODO: 204 (empty response body)
    // TODO: Add response headers (TODO: where??), e.g. `X-RateLimit-Limit`
    private func makeResponse(for operation: OpenAPI.Operation) throws -> String {
        // Only generate successfull responses.
        func findPreferredResponse() -> Either<JSONReference<OpenAPI.Response>, OpenAPI.Response>? {
            guard operation.responses.count > 1 else {
                return operation.responses.first { $0.key == .default || $0.key.isSuccess }?.value
            }
            return operation.responses.first { $0.key.isSuccess }?.value
        }

        guard let response = findPreferredResponse() else {
            return "Void"
        }
  
        switch response {
        case .a(let reference):
            switch reference {
            case .internal(let reference):
                return reference.name ?? "Void"
            case .external(_):
                throw GeneratorError("External references are not supported")
            }
        case .b(let scheme):
            if scheme.content.values.isEmpty {
                return "Void"
            } else if let content = scheme.content[.json] {
                // TODO: Parse example
                switch content.schema {
                case .a(let reference):
                    // TODO: what about nested types?
                    return try makeProperty(key: "response", schema: JSONSchema.reference(reference), isRequired: true, in: Context(parents: [])).type
                case .b(let schema):
                    throw GeneratorError("ERROR: response inline scheme not handled \(operation.description ?? "")")
                default:
                    throw GeneratorError("ERROR: response not handled \(operation.description ?? "")")
                }
            } else {
                throw GeneratorError("More than one schema in content which is not currently supported")
            }
        }
    }
}

private func makeType(_ string: String) -> String {
    let name = TypeName(string, options: .init())
    if string.starts(with: "{") {
        return "With\(name.rawValue)"
    }
    return name.rawValue
}
