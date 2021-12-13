// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Add support for exploding query parameters (and disabling it); see edgecases
// TODO: Improve how Patch parameters are generated
// TODO: Add summary and description
// TODO: Figure out what to do with operationId
// TODO: Parse in: path parameters and support types other than just String
// TODO: Remove Markdown from description (or keep if it it looks OK - test)
// TODO: Add an option to generate a plain list of APIs instead of using namespaces
// TODO: Test that this enum description works enum: [user, poweruser, admin]
// TODO: Add support for deprecated methods
// TODO: Support path parameters like this GET /report.{format}
// TODO: Get path parameter type from the (first) operation

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
                
                let isLast = index == allComponents.endIndex - 1
                
                do {
                    if let value = try makeOperation(path: path.value, components: components, isLast: isLast) {
                        output += value
                    }
                } catch {
                    print("ERROR: Failed to generate code for operation at path: \(components.joined(separator: "/"))")
                }
            }
        }

        var extensions: [String] = []
        
        if isRequestOperationIdExtensionNeeded {
            extensions.append(templates.requestOperationIdExtension)
        }
        
        if isQueryParameterEncoderNeeded {
            extensions.append(templates.queryParameterEncoders(options.paths.queryParameterEncoders))
        }
        
        for value in extensions {
            output += "\n"
            output += value
        }
        
        var header = templates.fileHeader
        for value in makeImports() {
            header += "\nimport \(value)"
        }
        
        header += "\n\n"
        header += [options.access, "enum", options.paths.namespace, "{}"].compactMap { $0 }.joined(separator: " ")
        
        stopMeasuring("generating paths (\(spec.paths.count))")
        
        return (header + "\n\n" + output + "\n\n").indent(using: options)
    }
    
    private func makeImports() -> [String] {
        var imports = options.paths.imports
        if options.isRemovingUnneededImports && !isHTTPHeadersDependencyNeeded {
            imports.remove("APIClient")
        }
        return imports.sorted()
    }
    
    // MARK: - Operation
    
    private func makeOperation(path: OpenAPI.PathItem, components: [String], isLast: Bool) throws -> String? {
        let subpath = OpenAPI.Path(components)
        let component = components.last!
        let isTopLevel = components.count == 1
        let type = component.isEmpty ? TypeName("Root") : makeType(component)
        let isParameter = component.starts(with: "{")
        let stat = isTopLevel ? "static " : ""
        
        let parents = Array(components.dropLast().map(makeType))
        let extensionOf = ([options.paths.namespace] + parents.map(\.rawValue)).joined(separator: ".")

        // TODO: percent-encode path?
        
        // TODO: Reuse type generation code
        
        if !isLast && spec.paths.contains(key: subpath) {
            return nil // Will be generated when the path is encountered
        }
        
        // TODO: refactor and add remaining niceness
        var generatedType = """
            \(access)struct \(type) {
                /// Path: `\(subpath.rawValue)`
                \(access)let path: String\n
        """
        
        let context = Context(parents: parents + [type], namespace: arguments.module?.rawValue)
        if isLast {
            generatedType += """
            \n\(makeMethods(for: path, context: context))\n
            """
        }
        
        generatedType += """
            }
        """
        
        if isParameter {
            let parameter = PropertyName(processing: component, options: options)
            return """
            extension \(extensionOf) {
                \(access)\(stat)func \(parameter)(_ \(parameter): String) -> \(type) {
                    \(type)(path: \(isTopLevel ? "\"/\(component)/\"" : "path + \"/\"") + \(parameter))
                }
            
            \(generatedType)
            }\n\n
            """
        } else {
            return """
            extension \(extensionOf) {
                \(access)\(stat)var \(PropertyName(processing: type.rawValue, options: options)): \(type) {
                    \(type)(path: \(isTopLevel ? "\"/\(component)\"" : ("path + \"/\(components.last!)\"")))
                }
            
            \(generatedType)
            }\n\n
            """
        }
    }
    
    // MARK: - Methods
    
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
    
    // TODO: Add support for header parameters
    private func _makeMethod(for operation: OpenAPI.Operation, method: String, context: Context) throws -> String {
        let responseType: String
        var responseHeaders: String?
        var nested: [String] = []
        // TODO: refactor
        if let response = getSuccessfulResponse(for: operation) {
            let responseValue = try makeResponse(for: response, method: method, context: context)
            responseType = responseValue.type.rawValue
            if let value = responseValue.nested {
                nested.append(value)
            }
            responseHeaders = try? makeHeaders(for: response, method: method)
        } else {
            responseType = "Void"
        }
        
        var output = templates.comments(for: .init(operation), name: "")

        var parameters: [String] = []
        var call: [String] = ["path"]

        let query = operation.parameters.compactMap { makeQueryParameter(for: $0, context: context) }
        if !query.isEmpty {
            let type = TypeName("\(method.capitalizingFirstLetter())Parameters")
            let props = query.map(templates.property).joined(separator: "\n")
            let initializer = templates.initializer(properties: query)
            let toQuery = templates.toQueryParameters(properties: query)
            nested.append(templates.entity(name: type, contents: [props, initializer, toQuery], protocols: []))
            let isOptional = query.allSatisfy { $0.isOptional }
            parameters.append("parameters: \(type)\(isOptional ? "? = nil" : "")")
            call.append("query: parameters\(isOptional ? "?" : "").asQuery()")
        }
        
        if let requestBody = operation.requestBody, method != "get" {
            let requestBody = try makeRequestBodyType(for: requestBody, method: method, context: context)
            if !requestBody.type.isVoid {
                if let value = requestBody.nested {
                    nested.append(value)
                }
                parameters.append("_ body: \(requestBody.type)\(requestBody.isOptional ? "? = nil" : "")")
                call.append("body: body")
            }
        }
        // TODO: Align this and contents based on the line count (and add option)
        var contents = ".\(method)(\(call.joined(separator: ", ")))"
        if options.paths.isAddingOperationIds, let operationId = operation.operationId, !operationId.isEmpty {
            setNeedsRequestOperationIdExtension()
            contents += ".id(\"\(operationId)\")"
        }
        // TODO: use properties instead of function when there are not arguments? (and add an option)
        output += templates.methodOrProperty(name: method, parameters: parameters, returning: "Request<\(responseType)>", contents: contents)
        if let headers = responseHeaders {
            output += "\n\n"
            output += headers
            setNeedsHTTPHeadersDependency()
        }
        for value in nested {
            output += "\n\n"
            output += value
        }
        return output.indented
    }
    
    // MARK: - Query Parameters
    
    // TODO: use propertyCountThreshold
    private func makeQueryParameter(for input: Either<JSONReference<OpenAPI.Parameter>, OpenAPI.Parameter>, context: Context) -> Property? {
        do {
            guard let property = try _makeQueryParameter(for: input, context: context) else {
                return nil
            }
            guard options.paths.queryParameterEncoders.keys.contains(property.type.rawValue) else {
                throw GeneratorError("Unsupported parameter type: \(property.type)")
            }
            setNeedsQueryParameterEncoder()
            return property
        } catch {
            // TODO: Change to non-failing version
            print("ERROR: Fail to generate query parameter \(input.description)")
            return nil
        }
    }
    
    // TODO: Add support for other types (arrays, etc); currently only basic built-in structs will works (see `Order`)
    private func _makeQueryParameter(for input: Either<JSONReference<OpenAPI.Parameter>, OpenAPI.Parameter>, context: Context) throws -> Property? {
        let parameter: OpenAPI.Parameter
        switch input {
        case .a(let reference):
            parameter = try reference.dereferenced(in: spec.components).underlyingParameter
        case .b(let value):
            parameter = value
        }
        guard parameter.context.inQuery else {
            return nil
        }
        let schema: JSONSchema
        switch parameter.schemaOrContent {
        case .a(let schemaContext):
            switch schemaContext.schema {
            case .a(let reference):
                schema = JSONSchema.reference(reference)
            case .b(let value):
                schema = value
            }
        case .b:
            throw GeneratorError("Parameter content map not supported for parameter: \(parameter.name)")
        }
        return try makeProperty(key: parameter.name, schema: schema, isRequired: parameter.required, in: context)
    }
    
    // MARK: - Request Body
    
    private typealias RequestBody = Either<JSONReference<OpenAPI.Request>, OpenAPI.Request>

    // TODO: Add application/x-www-form-urlencoded support
    // TODO: Add text/plain support
    // TODO: Add binary support
    // TODO: Add "image*" support
    // TODO: Add anyOf, oneOf support
    // TODO: Add uploads support
    private func makeRequestBodyType(for requestBody: RequestBody, method: String, context: Context) throws -> GeneratedType {
        var context = context
        context.isDecodableNeeded = false
        
        let schema: JSONSchema
        
        // TODO: Refactor
        switch requestBody {
        case .a(let reference):
            guard let name = reference.name else {
                throw GeneratorError("Inalid reference")
            }
            guard let key = OpenAPI.ComponentKey(rawValue: name), let request = spec.components.requestBodies[key] else {
                throw GeneratorError("Failed to find a requesty body named \(name)")
            }
            guard let content = request.content[.json] else {
                throw GeneratorError("No supported content types: \(request.content.keys)")
            }
            switch content.schema {
            case .a(let reference):
                schema = JSONSchema.reference(reference)
            case .b(let value):
                schema = value
            default:
                throw GeneratorError("Response not handled")
            }
        case .b(let request):
            if request.content.values.isEmpty {
                return GeneratedType(type: TypeName("Void"))
            } else if let content = request.content.values.first {
                switch content.schema {
                case .a(let reference):
                    schema = JSONSchema.reference(reference)
                case .b(let value):
                    schema = value
                default:
                    throw GeneratorError("Response not handled")
                }
            } else {
                throw GeneratorError("More than one schema in content which is not currently supported")
            }
        }
        
        let property = try makeProperty(key: "\(method)Request", schema: schema, isRequired: true, in: context)
        setNeedsEncodable(for: property.type)
        return GeneratedType(type: property.type, nested: property.nested, isOptional: !(requestBody.requestValue?.required ?? true))
    }
    
    // MARK: - Response Body
        
    private typealias Response = Either<JSONReference<OpenAPI.Response>, OpenAPI.Response>

    // Only generate successfull responses.
    private func getSuccessfulResponse(for operation: OpenAPI.Operation) -> Response? {
        guard operation.responses.count > 1 else {
            return operation.responses.first { $0.key == .default || $0.key.isSuccess }?.value
        }
        return operation.responses.first { $0.key.isSuccess }?.value
    }

    private struct GeneratedType {
        var type: TypeName
        var nested: String?
        var isOptional = false
    }

    // TODO: application/pdf and other binary files
    private func makeResponse(for response: Response, method: String, context: Context) throws -> GeneratedType {
        var context = context
        context.isEncodableNeeded = false
        
        let schema: OpenAPI.Response
        switch response {
        case .a(let reference):
            switch reference {
            case .internal(let reference):
                guard let name = reference.name else {
                    throw GeneratorError("Response reference name is missing")
                }
                if let rename = options.paths.overrideResponses[name] {
                    return GeneratedType(type: TypeName(rename))
                }
                guard let key = OpenAPI.ComponentKey(rawValue: name), let value = spec.components.responses[key] else {
                    throw GeneratorError("Failed to find a response body")
                }
                schema = value
            case .external:
                throw GeneratorError("External references are not supported")
            }
        case .b(let value):
            schema = value
        }
        
        return try makeResponse(for: schema, method: method, context: context)
    }
    
    private func makeResponse(for response: OpenAPI.Response, method: String, context: Context) throws -> GeneratedType {
        if response.content.values.isEmpty {
            return GeneratedType(type: TypeName("Void"))
        } else if let content = response.content[.json] {
            // TODO: Parse example
            switch content.schema {
            case .a(let reference):
                // TODO: what about nested types?
                let type = try makeProperty(key: "response", schema: JSONSchema.reference(reference), isRequired: true, in: context).type
                return GeneratedType(type: type)
            case .b(let schema):
                switch schema {
                case .string:
                    return GeneratedType(type: TypeName("String"))
                case .integer, .boolean:
                    return GeneratedType(type: TypeName("Data"))
                default:
                    let property = try makeProperty(key: "\(method)Response", schema: schema, isRequired: true, in: context)
                    return GeneratedType(type: property.type, nested: property.nested)
                }
            default:
                throw GeneratorError("ERROR: response not handled")
            }
        } else if response.content[.anyText] != nil {
            return GeneratedType(type: TypeName("String")) // Assume UTF8 encoding
        } else {
            throw GeneratorError("More than one schema in content which is not currently supported")
        }
    }
    
    // MARK: - Response Headers

    private func makeHeaders(for response: Response, method: String) throws -> String? {
        guard options.paths.isAddingResponseHeaders, let headers = response.responseValue?.headers else {
            return nil
        }
        let contents: [String] = try headers.map { try makeHeader(key: $0, header: $1) }
        guard !contents.isEmpty else {
            return nil
        }
        let name = method.capitalizingFirstLetter() + "ResponseHeaders"
        return templates.headers(name: name, contents: contents.joined(separator: "\n"))
    }
    
    private func makeHeader(key: String, header input: Either<JSONReference<OpenAPI.Header>, OpenAPI.Header>) throws -> String {
        let header: OpenAPI.Header
        switch input {
        case .a(let reference):
            header = try reference.dereferenced(in: spec.components).underlyingHeader
        case .b(let value):
            header = value
        }
        switch header.schemaOrContent {
        case .a(let value):
            let schema: JSONSchema
            switch value.schema {
            case .a(let reference):
                schema = try reference.dereferenced(in: spec.components).jsonSchema
            case .b(let value):
                schema = value
            }
            let property = try makeProperty(key: key, schema: schema, isRequired: schema.required, in: Context(parents: []))
            return templates.header(for: property, header: header)
        case .b:
            throw GeneratorError("HTTP headers with content map are not supported")
        }
    }

    private func makeType(_ string: String) -> TypeName {
        let name = TypeName(processing: string, options: options)
        if string.starts(with: "{") {
            return name.prepending("With")
        }
        return name
    }
}
