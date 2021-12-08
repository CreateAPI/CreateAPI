// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

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
        
        stopMeasuring("generating paths (\(spec.paths.count))")
        
        return output.indent(using: options)
    }
    
    // TODO: Add remaining methods
    private func makeMethods(for item: OpenAPI.PathItem) -> String {
        [
            item.get.flatMap { makeMethod(for: $0, method: "get") },
//            item.put.map { makeMethod(for: $0, method: "put") },
//            item.post.map { makeMethod(for: $0, method: "post") },
//            item.delete.map { makeMethod(for: $0, method: "delete") },
//            item.options.map { makeMethod(for: $0, method: "options") },
//            item.head.map { makeMethod(for: $0, method: "head") },
//            item.patch.map { makeMethod(for: $0, method: "patch") },
//            item.trace.map { makeMethod(for: $0, method: "trace") },
        ]
            .compactMap { $0 }
            .joined(separator: "\n\n")
    }
    
    // TODO: Add namespace to schems (package?)
    // TODO: Inject offset as a parameter
    // TODO: Add support for operationId
    // TODO: Add a way to disamiguate if responses have oneOf
    private func makeMethod(for operation: OpenAPI.Operation, method: String) -> String? {
        do {
        let response = try makeResponse(for: operation)
        return """
                \(access)func \(method)() -> Request<\(response)> {
                    .\(method)(path)
                }
        """
        } catch {
            print("ERROR: Failed to generate path \(method) for \(operation): \(error)")
            return nil
        }
    }
    
    // TODO: Add text/plain schema: type String support
    // TODO: Add inline array/dictionary responses
    // TODO: Generate proper nested response types (<PathComponent>Response)
    // TODO: application/pdf and other binary files
    // TODO: 204 (empty response body)
    // TODO: Add response headers (TODO: where??), e.g. `X-RateLimit-Limit`
    private func makeResponse(for operation: OpenAPI.Operation) throws -> String {
        // TODO: What if there is more than one? (find only successful)
        guard let response = operation.responses.first?.value else {
            return "Void"
        }
        switch response {
        case .a(let reference):
            // TODO: Use code from GenerateSchemes
            return reference.name ?? "Void"
        case .b(let scheme):
            if let content = scheme.content.values.first {
                // TODO: Parse example
                switch content.schema {
                case .a(let reference):
                    // TODO: what about nested types?
                    return try makeProperty(key: "response", schema: JSONSchema.reference(reference), isRequired: true, in: Context(parents: [])).type
                case .b(let schema):
                    print("ERROR: response inline scheme not handled \(operation.description ?? "")")
                default:
                    print("ERROR: response not handled \(operation.description ?? "")")
                }
            } else {
                print("ERROR: (???) more than one response type \(operation.description ?? "")")
            }
            return "Void"
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
