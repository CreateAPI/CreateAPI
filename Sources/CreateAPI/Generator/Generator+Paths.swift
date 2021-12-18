// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Add an option to generate a plain list of APIs instead of REST namespaces
// TODO: Add in documentation additional context, eg inlyvalues from 100 to 500
// TODO: Add a way to extend supported content types
// TODO: When the request body has only one parameter, inline it (required knowledge about nested types)
// TODO: When there is only one parameter, inline it (required knowledge about nested types)
// TODO: Add an option to skip certain paths / entire operations

extension Generator {
    func paths() throws -> GeneratorOutput {
        let benchmark = Benchmark(name: "Generate paths")
        defer { benchmark.stop() }
        return try _paths()
    }
    
    private func _paths() throws -> GeneratorOutput {
        let jobs = makeJobs()
        var generated = Array<Result<GeneratedFile, Error>?>(repeating: nil, count: jobs.count)
        let lock = NSLock()
        concurrentPerform(on: jobs, parallel: arguments.isVerbose) { index, job in
            do {
                let entry = try makePath(job: job)
                let fileName = makeTypeName(job.path.rawValue).rawValue
                let file = GeneratedFile(name: fileName, contents: entry)
                lock.sync { generated[index] = .success(file) }
            } catch {
                if arguments.isStrict {
                    lock.sync { generated[index] = .failure(error) }
                } else {
                    print("ERROR: Failed to generate path for \(job.path): \(error)")
                }
            }
        }
        return GeneratorOutput(
            header: makeHeader(),
            files: try generated.compactMap { $0 }.map { try $0.get() },
            extensions: makeExtensions()
        )
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
        var encountered = Set<OpenAPI.Path>()
        for path in spec.paths {
            let components = path.key.components.isEmpty ? [""] : path.key.components
            for index in components.indices {
                let subComponents = Array(components[...index])
                let subpath = OpenAPI.Path(Array(components[...index]))
                let isSubpath = index < components.endIndex - 1
                if isSubpath && spec.paths.contains(key: subpath) {
                    continue // Will be generated when the full path is encountered
                }
                guard !encountered.contains(subpath) else { continue }
                encountered.insert(subpath)

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
        return header
    }
    
    private func makeImports() -> [String] {
        var imports = options.paths.imports
        if options.isRemovingUnneededImports && !isHTTPHeadersDependencyNeeded {
            imports.remove("HTTPHeaders")
        }
        return imports.sorted()
    }
    
    private func makeExtensions() -> GeneratedFile? {
        var contents: [String] = []
        contents.append(templates.namespace(options.paths.namespace))
        if isRequestOperationIdExtensionNeeded {
            contents.append(templates.requestOperationIdExtension)
        }
        if isQueryNeeded {
            contents.append(templates.queryParameterEncoders(options.paths.queryParameterEncoders))
        }
        return GeneratedFile(name: "Extensions", contents: contents.joined(separator: "\n\n"))
    }
    
    // MARK: - Path
    
    private func makePath(job: Job) throws -> String {
        let component = job.lastComponent
        let parameterName = getParameterName(from: component)
        let type = makePathName(for: component)
    
        let parents = Array(job.components.dropLast().map(makePathName))
        let extensionOf = ([options.paths.namespace] + parents.map(\.rawValue)).joined(separator: ".")

        let context = Context(parents: parents + [type], namespace: arguments.module?.rawValue)
        let operations = job.isSubpath ? [] : try makeOperations(for: job.item, context: context)
        let generatedType = templates.pathEntity(name: type.rawValue, subpath: job.path.rawValue, operations: operations)
        
        let parameter = try parameterName.map { try getParameter(item: job.item, name: $0) }
        return templates.pathExtension(of: extensionOf, component: component, type: type, isTopLevel: job.isTopLevel, parameter: parameter, contents: generatedType)
    }
    
    private func makePathName(for component: String) -> TypeName {
        if component.isEmpty {
            return TypeName("Root")
        }
        if let parameter = getParameterName(from: component) {
            return makeTypeName(parameter).prepending("With")
        }
        return makeTypeName(component)
    }
    
    private func getParameter(item: OpenAPI.PathItem, name: String) throws -> PathParameter {
        let parameters = item.parameters.isEmpty ? (item.allOperations.first?.1.parameters ?? []) : item.parameters
        let parameter = parameters
            .compactMap { try? $0.unwrapped(in: spec) }
            .first { $0.context.inPath && $0.name == name }
        let type: String
        if let parameter = parameter {
            let (schema, _ ) = try parameter.unwrapped(in: spec)
            switch schema {
            case .integer: type = "Int"
            default: type = "String"
            }
        } else {
            type = "String"
        }
        return PathParameter(key: name, name: makePropertyName(name), type: TypeName(type))
    }
    
    private func getParameterName(from component: String) -> String? {
        guard let from = component.firstIndex(of: "{"), let to = component.firstIndex(of: "}") else {
            return nil
        }
        return String(component[component.index(after: from)..<to])
    }
    
    // MARK: - Methods

    private func makeOperations(for item: OpenAPI.PathItem, context: Context) throws -> [String] {
        try item.allOperations.map { method, operation in
            try makeOperation(operation, method, context)
        }.compactMap { $0 }
    }

    private func makeOperation(_ operation: OpenAPI.Operation, _ method: String, _ context: Context) throws -> String? {
        do {
            return try _makeOperation(operation, method: method, context: context)
        } catch {
            if arguments.isStrict {
                throw error
            } else {
                print("ERROR: Failed to generate \(method) for \(operation.operationId ?? "\(operation)"): \(error)")
                return nil
            }
        }
    }
    
    private func _makeOperation(_ operation: OpenAPI.Operation, method: String, context: Context) throws -> String {
        var nested: [String] = []
        var parameters: [String] = []
        var call: [String] = ["path"]

        // Response type and headers
        let responseType: String
        var responseHeaders: String?
        if let response = getSuccessfulResponse(for: operation) {
            let responseValue = try makeResponse(for: response, method: method, context: context)
            responseType = responseValue.type.rawValue
            if let value = responseValue.nested {
                nested.append(render(value))
            }
            responseHeaders = try? makeHeaders(for: response, method: method)
        } else {
            responseType = "Void"
        }
        
        // Query parameters
        let query = operation.parameters.compactMap { makeQueryParameter(for: $0, context: context) }
        if !query.isEmpty {
            var contents: [String] = []
            contents += [query.map(templates.property).joined(separator: "\n")]
            contents += query.compactMap(\.nested).map(render)
            contents += [templates.initializer(properties: query)]
            contents += [templates.asQuery(properties: query)]
            let type = TypeName("\(method.capitalizingFirstLetter())Parameters")
            if options.paths.isInliningSimpleQueryParameters && query.count <= options.paths.simpleQueryParametersThreshold {
                for item in query {
                    parameters.append("\(item.name): \(item.type)\(item.isOptional ? "? = nil" : "")")
                }
                let initArgs = query.map { "\($0.name)" }.joined(separator: ", ")
                let initalizer = "make\(method.capitalizingFirstLetter())Query(\(initArgs))"
                call.append("query: \(initalizer)")
                nested.append(templates.asQueryInline(method: method, properties: query))
                nested += query.compactMap { $0.nested }.map(render)
            } else {
                let isOptional = query.allSatisfy { $0.isOptional }
                parameters.append("parameters: \(type)\(isOptional ? "? = nil" : "")")
                call.append("query: parameters\(isOptional ? "?" : "").asQuery()")
                nested.append(templates.entity(name: type, contents: contents, protocols: []))
            }
        }
        
        // Request body
        if let requestBody = operation.requestBody, method != "get" {
            let requestBody = try makeRequestBodyType(for: requestBody, method: method, context: context)
            if requestBody.type.rawValue != "Void" {
                if options.paths.isInliningSimpleRequestType,
                   let entity = (requestBody.nested as? EntityDeclaration),
                   entity.properties.count == 1 {
                    // Inline simple request types (types that only have N properties):
                    //
                    // public func post(body: PostRequest) -> Request<github.Reaction>
                    //   .post(path, body)
                    //
                    //   becomes
                    //
                    // public func post(accessToken: String) -> Request<github.Reaction>
                    //   .post(path, PostRequest(accessToken: accessToken)
                    //
                    // If the property is using a type nested inside the request type, add a "namespace".
                    let property = entity.properties[0]
                    if entity.isNested(property.type.elementType) {
                        parameters.append("\(property.name): \(property.type.identifier(namespace: entity.name.rawValue))\(property.isOptional ? "? = nil" : "")")
                        call.append("body: \(entity.name)(\(property.name): \(property.name))")
                        if let value = requestBody.nested {
                            nested.append(render(value))
                        }
                    } else {
                        parameters.append("\(property.name): \(property.type)\(property.isOptional ? "? = nil" : "")")
                        call.append("body: [\"\(property.key)\": \(property.name)]")
                        // Don't need to add a nested type
                    }
                } else {
                    parameters.append("_ body: \(requestBody.type)\(requestBody.isOptional ? "? = nil" : "")")
                    call.append("body: body")
                    if let value = requestBody.nested {
                        nested.append(render(value))
                    }
                }
            }
        }
        
        // Finally, generate the output
        var contents = ".\(method)(\(call.joined(separator: ", ")))"
        if options.paths.isAddingOperationIds, let operationId = operation.operationId, !operationId.isEmpty {
            setNeedsRequestOperationIdExtension()
            contents += ".id(\"\(operationId)\")"
        }

        var output = templates.comments(for: .init(operation), name: "")
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
            setNeedsQuery()
            return property
        } catch {
            print("ERROR: Fail to generate query parameter \(input.description)")
            return nil
        }
    }
    
    private func _makeQueryParameter(for input: Either<JSONReference<OpenAPI.Parameter>, OpenAPI.Parameter>, context: Context) throws -> Property? {
        let parameter = try input.unwrapped(in: spec)
        guard parameter.context.inQuery else {
            return nil
        }
        let (schema, explode) = try parameter.unwrapped(in: spec)
        
        struct QueryItemType {
            var type: MyType
            var nested: Declaration?
            
            init(type: MyType, nested: Declaration? = nil) {
                self.type = type
                self.nested = nested
            }
            
            init(_ name: String) {
                self.type = .builtin(name)
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
                    return QueryItemType(type: .userDefined(name: enumTypeName), nested: nested)
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
                    return QueryItemType(type: type.type.asArray(), nested: type.nested)
                }
                return nil
            case .all, .one, .any, .not: return nil
            case .reference(let ref, _):
                guard let name = ref.name.map(makeTypeName), supportedTypes.contains(name.rawValue) else {
                    return nil
                }
                return QueryItemType(type: .userDefined(name: name))
            case .fragment: return nil
            }
        }
        
        guard let type = try getQueryItemType(for: schema, isTopLevel: true) else {
            return nil
        }
        
        func getPropertyName(for name: PropertyName, type: MyType) -> PropertyName {
            if let name = options.rename.parameters[name.rawValue] {
                return PropertyName(name)
            }
            if options.isGeneratingSwiftyBooleanPropertyNames && type.isBool {
                return name.asBoolean
            }
            return name
        }

        let name = getPropertyName(for: makePropertyName(parameter.name), type: type.type)
        return Property(name: name, type: type.type, isOptional: !parameter.required, key: parameter.name, explode: explode, metadata: .init(schema.coreContext), nested: type.nested)
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
        context.isPatch = method == "patch"
        
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
        return GeneratedType(type: property.type.name, nested: property.nested, isOptional: !(requestBody.requestValue?.required ?? true))
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
        var nested: Declaration?
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
                return GeneratedType(type: type.name)
            case .b(let schema):
                switch schema {
                case .string:
                    return GeneratedType(type: TypeName("String"))
                case .integer, .boolean:
                    return GeneratedType(type: TypeName("Data"))
                default:
                    let property = try makeProperty(key: "\(method)Response", schema: schema, isRequired: true, in: context)
                    return GeneratedType(type: property.type.name, nested: property.nested)
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
}
