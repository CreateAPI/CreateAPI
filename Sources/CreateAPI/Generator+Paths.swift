// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Improve how Patch parameters are generated
// TODO: Add path parameter types support (e.g. Int)
// TODO: Add an option to generate a plain list of APIs instead of REST namespaces
// TODO: Support path parameters like this: GET /report.{format}
// TODO: Generate phantom ID types
// TODO: Add in documentation additional context, eg inlyvalues from 100 to 500
// TODO: Add a way to extend supported content types
// TODO: When the request body has only one parameter, inline it (required knowledge about nested types)
// TODO: When there is only one parameter, inline it (required knowledge about nested types)
extension Generator {
        
    func paths() -> String {
        startMeasuring("generating paths (\(spec.paths.count))")
                
        let jobs = makeJobs()
        var generated = Array<String?>(repeating: nil, count: jobs.count)
        let lock = NSLock()
        concurrentPerform(on: jobs, parallel: arguments.isVerbose) { index, job in
            let code = makeOperation(job: job)
            lock.lock()
            generated[index] = code
            lock.unlock()
        }

        let output = ([makeHeader()] + generated.compactMap { $0 } + makeExtensions())
            .joined(separator: "\n\n") + "\n"
        
        stopMeasuring("generating paths (\(spec.paths.count))")

        return output.indent(using: options)
    }
    
    // Generate code for the given (sub)path.
    private struct Job {
        let lastComponent: String
        let path: OpenAPI.Path // Can be sub-path too
        let components: [String]
        var isSubpath: Bool
        let item: OpenAPI.PathItem
        
        var isTopLevel: Bool { components.count == 1 }
    }
    
    // Make all jobs upfront so we could then parallelize code generation
    private func makeJobs() -> [Job] {
        var jobs: [Job] = []
        var generated = Set<OpenAPI.Path>()
        for path in spec.paths {
            let components = path.key.components.isEmpty ? [""] : path.key.components
            for index in components.indices {
                let subComponents = Array(components[...index])
                let subpath = OpenAPI.Path(Array(components[...index]))
                let isSubpath = index < components.endIndex - 1
                
                if isSubpath && spec.paths.contains(key: subpath) {
                    continue // Will be generated when the full path is encountered
                }
                
                guard !generated.contains(subpath) else { continue }
                generated.insert(subpath)

                let job = Job(lastComponent: components[index], path: subpath, components: subComponents, isSubpath: isSubpath, item: path.value)
                jobs.append(job)
            }
        }
        return jobs
    }
    
    private func makeHeader() -> String {
        var header = templates.fileHeader
        for value in makeImports() {
            header += "\nimport \(value)"
        }
        header += "\n\n"
        header += templates.namespace(options.paths.namespace)
        return header
    }
    
    private func makeImports() -> [String] {
        var imports = options.paths.imports
        if options.isRemovingUnneededImports && !isHTTPHeadersDependencyNeeded {
            imports.remove("HTTPHeaders")
        }
        return imports.sorted()
    }
    
    private func makeExtensions() -> [String] {
        var extensions: [String] = []
        if isRequestOperationIdExtensionNeeded {
            extensions.append(templates.requestOperationIdExtension)
        }
        if isQueryParameterEncoderNeeded {
            extensions.append(templates.queryParameterEncoders(options.paths.queryParameterEncoders))
        }
        return extensions
    }
    
    // MARK: - Operation
    
    private func makeOperation(job: Job) -> String {
        let component = job.lastComponent
        let type = component.isEmpty ? TypeName("Root") : makeType(component)
        let isParameter = component.starts(with: "{")

        let parents = Array(job.components.dropLast().map(makeType))
        let extensionOf = ([options.paths.namespace] + parents.map(\.rawValue)).joined(separator: ".")

        let context = Context(parents: parents + [type], namespace: arguments.module?.rawValue)
        let methods = job.isSubpath ? [] : makeMethods(for: job.item, context: context)
        let generatedType = templates.pathEntity(name: type.rawValue, subpath: job.path.rawValue, methods: methods)
        
        let parameter = isParameter ? makePropertyName(component) : nil
        return templates.pathExtension(of: extensionOf, component: component, type: type, isTopLevel: job.isTopLevel, parameter: parameter, contents: generatedType)
    }
    
    // MARK: - Methods

    private func makeMethods(for item: OpenAPI.PathItem, context: Context) -> [String] {
        [
            item.get.flatMap { makeMethod($0, "get", context) },
            item.post.flatMap { makeMethod($0, "post", context) },
            item.put.flatMap { makeMethod($0, "put", context) },
            item.patch.flatMap { makeMethod($0, "patch", context) },
            item.delete.flatMap { makeMethod($0, "delete", context) },
            item.options.flatMap { makeMethod($0, "options", context) },
            item.head.flatMap { makeMethod($0, "head", context) },
            item.trace.flatMap { makeMethod($0, "trace", context) },
        ].compactMap { $0 }
    }

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
            var contents: [String] = []
            contents += [query.map(templates.property).joined(separator: "\n")]
            contents += query.compactMap(\.nested)
            contents += [templates.initializer(properties: query)]
            contents += [templates.toQueryParameters(properties: query)]
            nested.append(templates.entity(name: type, contents: contents, protocols: []))
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
        var contents = ".\(method)(\(call.joined(separator: ", ")))"
        if options.paths.isAddingOperationIds, let operationId = operation.operationId, !operationId.isEmpty {
            setNeedsRequestOperationIdExtension()
            contents += ".id(\"\(operationId)\")"
        }
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
        return output
    }
    
    // MARK: - Query Parameters
    
    private func makeQueryParameter(for input: Either<JSONReference<OpenAPI.Parameter>, OpenAPI.Parameter>, context: Context) -> Property? {
        do {
            guard let property = try _makeQueryParameter(for: input, context: context) else {
                return nil
            }
            setNeedsQueryParameterEncoder()
            return property
        } catch {
            print("ERROR: Fail to generate query parameter \(input.description)")
            return nil
        }
    }
    
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
        var explode = true
        switch parameter.schemaOrContent {
        case .a(let schemaContext):
            explode = schemaContext.explode
            switch schemaContext.schema {
            case .a(let reference):
                schema = JSONSchema.reference(reference)
            case .b(let value):
                schema = value
            }
        case .b:
            throw GeneratorError("Parameter content map not supported for parameter: \(parameter.name)")
        }
                
        func property(type: TypeName, info: JSONSchemaContext?, nested: String? = nil) -> Property {
            assert(info != nil) // context is null for references, but the caller needs to dereference first
            let name = getPropertyName(for: makePropertyName(parameter.name), type: type)
            return Property(name: name, type: type, isOptional: !parameter.required, key: parameter.name, explode: explode, schema: schema, metadata: .init(info), nested: nested)
        }
        
        struct QueryItemType {
            var type: TypeName
            var nested: String?
            
            init(type: TypeName, nested: String? = nil) {
                self.type = type
                self.nested = nested
            }
            
            init(_ name: String) {
                self.type = TypeName(name)
            }
        }
        
        let supportedTypes = Set(options.paths.queryParameterEncoders.keys)
        
        func getQueryItemType(for schema: JSONSchema, isTopLevel: Bool) throws -> QueryItemType? {
            switch schema {
            case .boolean: return QueryItemType("Bool")
            case .number: return QueryItemType("Double")
            case .integer: return QueryItemType("Int")
            case .string(let info, _):
                switch info.format {
                case .dateTime: return QueryItemType("Date")
                case .other(let other): if other == "uri" { return QueryItemType("URL") }
                default: break
                }
                if info.allowedValues != nil {
                    let enumTypeName = makeTypeName(parameter.name)
                    let nested = try makeStringEnum(name: enumTypeName, info: info)
                    return QueryItemType(type: enumTypeName, nested: nested)
                }
                return QueryItemType("String")
            case .object: return nil
            case .array(_, let details):
                guard isTopLevel else {
                    return nil
                }
                guard let item = details.items else {
                    throw GeneratorError("Missing array item type")
                }
                if let type = try getQueryItemType(for: item, isTopLevel: false) {
                    return QueryItemType(type: type.type.asArray, nested: type.nested)
                }
                return nil
            case .all, .one, .any, .not: return nil
            case .reference(let ref, _):
                guard let name = ref.name.map(makeTypeName), supportedTypes.contains(name.rawValue) else {
                    return nil
                }
                return QueryItemType(type: name)
            case .fragment: return nil
            }
        }
        
        guard let type = try getQueryItemType(for: schema, isTopLevel: true) else {
            return nil
        }
        
        func getPropertyName(for name: PropertyName, type: TypeName) -> PropertyName {
            if let name = options.rename.parameters[name.rawValue] {
                return PropertyName(name)
            }
            if options.isGeneratingSwiftyBooleanPropertyNames && type.rawValue == "Bool" {
                return name.asBoolean
            }
            return name
        }

        let name = getPropertyName(for: makePropertyName(parameter.name), type: type.type)
        return Property(name: name, type: type.type, isOptional: !parameter.required, key: parameter.name, explode: explode, schema: schema, metadata: .init(schema.coreContext), nested: type.nested)
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
        func firstContent(for keys: Set<OpenAPI.ContentType>) -> OpenAPI.Content? {
            for key in keys {
                if let content = response.content[key] {
                    return content
                }
            }
            return nil
        }
        if response.content.isEmpty {
            return GeneratedType(type: TypeName("Void"))
        }
        if let content = firstContent(for: [.json, .jsonapi, .other("application/scim+json")]) {
            switch content.schema {
            case .a(let reference):
                let type = try makeProperty(key: "response", schema: JSONSchema.reference(reference), isRequired: true, in: context).type
                return GeneratedType(type: type)
            case .b(let schema):
                // TODO: Revisit this
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
        }
        if arguments.vendor == "github", firstContent(for: [.other("application/octocat-stream")]) != nil {
            return GeneratedType(type: TypeName("String"))
        }
        if firstContent(for: [.css, .csv, .form, .html, .javascript, .txt, .xml, .yaml, .anyText]) != nil {
            return GeneratedType(type: TypeName("String"))
        }
        return GeneratedType(type: TypeName("Data"))
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
