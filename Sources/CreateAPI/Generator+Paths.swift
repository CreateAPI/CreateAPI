// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: (+Get) How to access response headers, e.g. `x-next` in Petstore/pets.get
    // maybe add Response<T> that provides URLResponse and use it only if headers: are specified
    // + add headers in comments (or add keys?)
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
// TODO: Add summary and description
// TODO: Figure out what to do with operationId
// TODO: Parse in: path parameters and support types other than just String
// TODO: Remove Markdown from description (or keep if it it looks OK - test)
// TODO: Add an option to generate a plain list of APIs instead of using namespaces
// TODO: Test that this enum description works enum: [user, poweruser, admin]
// TODO: Add support for deprecated methods
// TODO: Support path parameters like this GET /report.{format}
// TODO: Group operations by tags https://swagger.io/docs/specification/2-0/grouping-operations-with-tags/?sbsearch=tags

// TODO: Apply overridden names based on spec, not output file
// TODO: Generate phantom ID types
// TODO: Allow to override types for specific properties
// TODO: Add in documentation additional context, eg inlyvalues from 100 to 500
// TODO: Automatically apply more specific rename rules first

// TODO: Run everything throught SwiftLint again
extension Generator {
    
    #warning("refactor")
    var access: String { options.access.isEmpty ? "" :  options.access + " " }
    
    func paths() -> String {
        startMeasuring("generating paths (\(spec.paths.count))")
                
        // TODO: Only generate for one path
        var output = ""

        var generated = Set<OpenAPI.Path>()
                
        for path in spec.paths {
            var components: [String] = []
            let allComponents = path.key.components.isEmpty ? [""] : path.key.components
            for (index, component) in allComponents.enumerated() {
                components.append(component)
                let subpath = OpenAPI.Path(components)
                guard !generated.contains(subpath) else { continue }
                generated.insert(subpath)
                
                let component = components.last!
                let isLast = index == allComponents.endIndex - 1
                let isTopLevel = components.count == 1
                let type = component.isEmpty ? TypeName(processedRawValue: "Root") : makeType(component)
                let isParameter = component.starts(with: "{")
                let stat = isTopLevel ? "static " : ""
                
                let parents = Array(components.dropLast().map(makeType))
                let extensionOf = ([options.paths.namespace] + parents.map(\.rawValue)).joined(separator: ".")

                // TODO: percent-encode path?
                
                // TODO: Reuse type generation code
                
                if !isLast && spec.paths.contains(key: subpath) {
                    continue // Will be generated when the path is encountered
                }
                
                // TODO: refactor and add remaining niceness
                var generatedType = """
                    \(access)struct \(type) {
                        /// Path: `\(subpath.rawValue)`
                        \(access)let path: String\n
                """
                
                let context = Context(parents: parents + [type])
                if isLast {
                    generatedType += """
                    \n\(makeMethods(for: path.value, context: context))\n
                    """
                }
                
                generatedType += """
                    }
                """
                
                if isParameter {
                    let parameter = PropertyName(component, options: options)
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
                        \(access)\(stat)var \(PropertyName(type.rawValue, options: options)): \(type) {
                            \(type)(path: \(isTopLevel ? "\"/\(component)\"" : ("path + \"/\(components.last!)\"")))
                        }
                    
                    \(generatedType)
                    }\n\n
                    """
                }
            }
        }

        if isRequestOperationIdExtensionNeeded {
            output += "\n\n"
            output += templates.requestOperationIdExtension
            output += "\n\n"
        }
        
        var header = templates.fileHeader
        for value in makeImports() {
            header += "\nimport \(value)"
        }
        
        header += "\n\n"
        header += [options.access, "enum", options.paths.namespace, "{}"].compactMap { $0 }.joined(separator: " ")
        
        stopMeasuring("generating paths (\(spec.paths.count))")
        
        return (header + "\n\n" + output).indent(using: options)
    }
    
    private func makeImports() -> [String] {
        var imports = options.paths.imports
        if options.isRemovingUnneededImports && !isHTTPHeadersDependencyNeeded {
            imports.remove("APIClient")
        }
        return imports.sorted()
    }
    
    // TODO: Add remaining methods
    private func makeMethods(for item: OpenAPI.PathItem, context: Context) -> String {
        [
            item.get.flatMap { makeMethod($0, "get", context) },
            item.post.flatMap { makeMethod($0, "post", context) },
            item.put.flatMap { makeMethod($0, "put", context) },
            item.patch.flatMap { makeMethod($0, "patch", context) },
            item.delete.flatMap { makeMethod($0, "delete", context) },
            item.options.flatMap { makeMethod($0, "options", context) },
            item.head.flatMap { makeMethod($0, "head", context) },
            item.trace.flatMap { makeMethod($0, "trace", context) },
        ]
            .compactMap { $0 }
            .map { $0.indented }
            .joined(separator: "\n\n")
    }
    
    private func hasBody(_ method: String) -> Bool {
        ["put", "post", "patch"].contains(method)
    }
    
    // TODO: Inject offset as a parameter
    // TODO: Add a way to disamiguate if responses have oneOf
    private func makeMethod(_ operation: OpenAPI.Operation, _ method: String, _ context: Context) -> String? {
        do {
            return try _makeMethod(for: operation, method: method, context: context)
        } catch {
            print("ERROR: Failed to generate path \(method) for \(operation.operationId ?? "\(operation)"): \(error)")
            return nil
        }
    }
    
    private func _makeMethod(for operation: OpenAPI.Operation, method: String, context: Context) throws -> String {
        let responseType: String
        var responseHeaders: String?
        var nested: [String] = []
        // TODO: refactor
        if let response = getSuccessfulResponse(for: operation) {
            let responseValue = try makeResponse(for: response, method: method, context: context)
            responseType = responseValue.type
            if let value = responseValue.nested {
                nested.append(value)
            }
            responseHeaders = try? makeHeaders(for: response, method: method)
        } else {
            responseType = "Void"
        }
        
        var output = ""
        if options.comments.isEnabled {
            if options.comments.addSummary, let summary = operation.summary, !summary.isEmpty {
                for line in summary.lines {
                    output += "/// \(line)\n"
                }
            }
            // TODO: Reuse this code (move to Templates)
            if options.comments.addDescription, let description = operation.description, !description.isEmpty {
                if !output.isEmpty {
                    output += "///\n"
                }
                let description = options.comments.capitilizeDescription ? description.capitalizingFirstLetter() : description
                for line in description.lines {
                    output += "/// \(line)\n"
                }
            }
            if options.comments.isAddingExternalDocumentation, let docs = operation.externalDocs {
                if !output.isEmpty {
                    output += "///\n"
                }
                // I tried to use `seealso`, but Xcode doesn't render it
                output += "/// [\(docs.description ?? "External Documentation")](\(docs.url.absoluteString))\n"
            }
        }
        if options.isAddingDeprecations, operation.deprecated {
            output += templates.deprecated
        }
        var parameters: [String] = []
        if hasBody(method) {
            let request = try makeRequestBodyType(for: operation, method: method, context: context)
            if let value = request.nested {
                nested.append(value)
            }
            parameters.append("_ body: \(request.type)")
        }
        var call: [String] = ["path"]
        if hasBody(method) {
            call.append("body: body")
        }
        // TODO: Align this and contents based on the line count (and add option)
        var contents = ".\(method)(\(call.joined(separator: ", ")))"
        if options.paths.isAddingOperationIds, let operationId = operation.operationId, !operationId.isEmpty {
            setRequestOperationIdExtensionNeeded()
            contents += ".id(\"\(operationId)\")"
        }
        output += templates.method(name: method, parameters: parameters, returning: "Request<\(responseType)>", contents: contents)
        if let headers = responseHeaders {
            output += "\n\n"
            output += headers
            setHTTPHeadersDependencyNeeded()
        }
        for value in nested {
            output += "\n\n"
            output += value
        }
        return output.indented
    }
    
    // TODO: Generate -parameter documentation
    // TODO: Automatically pick application/json (See Paths.Pet.WithPetID.PostRequest)
    // TODO: Add application/x-www-form-urlencoded support
    // TODO: Add text/plain support
    // TODO: Add binary support
    // TODO: Add "optional" support
    // TODO: Add "image*" support
    // TODO: Add anyOf, oneOf support
    // TODO: Add uploads support
    private func makeRequestBodyType(for operation: OpenAPI.Operation, method: String, context: Context) throws -> TypeWrapper {
        guard let requestBody = operation.requestBody else {
            // TODO: Is is the correct handling?
            throw GeneratorError("ERROR: Request body is missing")
        }
        
        // TODO: Refactor
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
                let schema: JSONSchema
                switch content.schema {
                case .a(let reference):
                    schema = JSONSchema.reference(reference)
                case .b(let value):
                    schema = value
                default:
                    throw GeneratorError("ERROR: response not handled \(operation.description ?? "")")
                }
                // TODO: This should be resused
                let type = try makeProperty(key: "\(method)Request", schema: schema, isRequired: true, in: context)
                setNeedsEncodable(for: TypeName(processedRawValue: type.type))
                return TypeWrapper(type: addNamespaceIfNeeded(for: type.type, context: context), nested: type.nested)
            } else {
                throw GeneratorError("No supported content types: \(request.content.keys)")
            }
            
            #warning("TEMP")
            switch reference {
            case .internal(let reference):
                return TypeWrapper(type: reference.name ?? "Void")
            case .external(_):
                throw GeneratorError("External references are not supported")
            }
        case .b(let scheme):
            if scheme.content.values.isEmpty {
                return TypeWrapper(type: "Void")
            } else if let content = scheme.content.values.first {
                // TODO: Parse example
                switch content.schema {
                case .a(let reference):
                    let type = try makeProperty(key: "\(method)Request", schema: JSONSchema.reference(reference), isRequired: true, in: context)
                    setNeedsEncodable(for: TypeName(processedRawValue: type.type))
                    return TypeWrapper(type: addNamespaceIfNeeded(for: type.type, context: context), nested: type.nested)
                case .b(let schema):
                    let type = try makeProperty(key: "\(method)Request", schema: schema, isRequired: true, in: context)
                    setNeedsEncodable(for: TypeName(processedRawValue: type.type))
                    return TypeWrapper(type: addNamespaceIfNeeded(for: type.type, context: context), nested: type.nested)
                default:
                    throw GeneratorError("ERROR: response not handled \(operation.description ?? "")")
                }
            } else {
                throw GeneratorError("More than one schema in content which is not currently supported")
            }
        }
    }
    
    private typealias Response = Either<JSONReference<OpenAPI.Response>, OpenAPI.Response>

    // Only generate successfull responses.
    private func getSuccessfulResponse(for operation: OpenAPI.Operation) -> Response? {
        guard operation.responses.count > 1 else {
            return operation.responses.first { $0.key == .default || $0.key.isSuccess }?.value
        }
        return operation.responses.first { $0.key.isSuccess }?.value
    }
    
    // TODO: Refactor
    private struct TypeWrapper {
        var type: String
        var nested: String?
    }

    // TODO: application/pdf and other binary files
    // TODO: 204 (empty response body)
    // TODO: Add response headers (TODO: where??), e.g. `X-RateLimit-Limit`
    // TODO: Add "descripton" to "- returns" comments
    // TODO: Add "$ref": "#/components/responses/accepted" support (GitHub spec)
    private func makeResponse(for response: Response, method: String, context: Context) throws -> TypeWrapper {
        var context = context
        context.namespace = arguments.module?.rawValue
        context.isEncodableNeeded = false
        
        switch response {
        case .a(let reference):
            switch reference {
            case .internal(let reference):
                throw GeneratorError("Responses references are not supported")
            case .external(_):
                throw GeneratorError("External references are not supported")
            }
        case .b(let schema):
            if schema.content.values.isEmpty {
                return TypeWrapper(type: "Void")
            } else if let content = schema.content[.json] {
                // TODO: Parse example
                switch content.schema {
                case .a(let reference):
                    // TODO: what about nested types?
                    let type = try makeProperty(key: "response", schema: JSONSchema.reference(reference), isRequired: true, in: context).type
                    return TypeWrapper(type: addNamespaceIfNeeded(for: type, context: context))
                case .b(let schema):
                    switch schema {
                    case .string:
                        return TypeWrapper(type: "String")
                    case .integer, .boolean:
                        return TypeWrapper(type: "Data")
                    default:
                        // TODO: Add a way to cutomize which namespace to use
                        let property = try makeProperty(key: "\(method)Response", schema: schema, isRequired: true, in: context)
                        return TypeWrapper(type: property.type, nested: property.nested)
                    }
                default:
                    throw GeneratorError("ERROR: response not handled")
                }
            } else if schema.content[.anyText] != nil {
                return TypeWrapper(type: "String") // Assume UTF8 encoding
            } else {
                throw GeneratorError("More than one schema in content which is not currently supported")
            }
        }
    }
    
    // TODO: refactor (do it on the Generator level)
    private func addNamespaceIfNeeded(for type: String, context: Context) -> String {
        // TODO: Add an option to disable disambiguation if it's not needed
        if context.parents.contains(where: { $0.rawValue == type }), let module = arguments.module {
            return "\(module).\(type)"
        }
        return type
    }
    
    // TODO: Add support for schema references
    private func makeHeaders(for response: Response, method: String) throws -> String? {
        guard options.paths.isAddingResponseHeaders, let headers = response.responseValue?.headers else {
            return nil
        }
        
        let contents: [String] = try headers.map { key, value in
            let header: OpenAPI.Header
            switch value {
            case .a(let reference):
                header = try reference.dereferenced(in: spec.components).underlyingHeader
            case .b(let value):
                header = value
            }
            switch header.schemaOrContent {
            case .a(let schema):
                switch schema.schema {
                case .a:
                    throw GeneratorError("HTTP header schema references not supported")
                case .b(let schema):
                    let property = try makeProperty(key: key, schema: schema, isRequired: true, in: Context(parents: []))
                    return templates.header(for: property, header: header)
                }
            case .b:
                throw GeneratorError("HTTP headers with content map are not supported")
            }
        }

        guard !contents.isEmpty else {
            return nil
        }

        return templates.headers(name: method.capitalizingFirstLetter() + "ResponseHeaders", contents: contents.joined(separator: "\n"))
    }

    private func makeType(_ string: String) -> TypeName {
        let name = TypeName(string, options: options)
        if string.starts(with: "{") {
            return name.prepending("With")
        }
        return name
    }
}