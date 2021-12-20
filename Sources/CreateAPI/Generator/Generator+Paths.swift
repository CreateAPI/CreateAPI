// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Support parameter reuse
// TODO: Support responses reuse
// TODO: Improve how paths are generated (do it based on keys)
// TODO: Add support for common parameters and HTTP header parameteres
// TODO: Add an option to generate a plain list of APIs instead of REST namespaces
// TODO: Add in documentation additional context, e.g. "only values from 100 to 500"
// TODO: Add a way to extend supported content types
// TODO: Add proper support for multipart form data
// TODO: Add support for inlining body with `x-www-form-urlencoded` encoding
// TODO: Split operations in separate files
// TODO: Add support for application/json-patch+json

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
                let entry = try makeEntry(for: job)
                let file = GeneratedFile(name: makeTypeName(job.filename).rawValue, contents: entry)
                lock.sync { generated[index] = .success(file) }
            } catch {
                if arguments.isStrict {
                    lock.sync { generated[index] = .failure(error) }
                } else {
                    print("ERROR: Failed to generate path for \(job.filename): \(error)")
                }
            }
        }
        return GeneratorOutput(
            header: makeHeader(),
            files: try generated.compactMap { $0 }.map { try $0.get() },
            extensions: makeExtensions()
        )
    }
    
    private func makeJobs() -> [Job] {
        switch options.paths.style {
        case .rest: return makeJobsRest()
        case .operations: return makeJobsOperations()
        }
    }
    
    private func makeEntry(for job: Job) throws -> String {
        switch job {
        case let job as JobRest: return try makePath(job: job)
        case let job as JobOperation: return try makePath(job: job)
        default: fatalError("Unsupporeted job")
        }
    }

    // MARK: - Jobs (Rest)
    
    // Generate code for the given (sub)path.
    private struct JobRest: Job {
        let lastComponent: String
        let path: OpenAPI.Path // Can be sub-path too
        let components: [String]
        var isSubpath: Bool
        let item: OpenAPI.PathItem
        let commonIndices: Int
        
        var isTopLevel: Bool { components.count == 1 }
        var filename: String { path.rawValue }
    }
    
    // Make all jobs upfront so we could then parallelize code generation
    private func makeJobsRest() -> [JobRest] {
        guard !spec.paths.isEmpty else { return [] }
        
        let commonIndices = findCommonIndiciesCount()
    
        // Generate jobs
        var jobs: [JobRest] = []
        var encountered = Set<OpenAPI.Path>()
        for path in spec.paths {
            guard !options.paths.skip.contains(path.key.rawValue) else {
                continue
            }
            let components = path.key.components.isEmpty ? [""] : path.key.components
            for index in components.indices {
                guard index >= commonIndices else {
                    continue // Skip
                }
                let subpath = OpenAPI.Path(Array(components[...index]))
                let isSubpath = index < components.endIndex - 1
                if isSubpath && spec.paths.contains(key: subpath) {
                    continue // Will be generated when the full path is encountered
                }
                guard !encountered.contains(subpath) else { continue }
                encountered.insert(subpath)

                let job = JobRest(lastComponent: components[index], path: subpath, components: Array(components[commonIndices...index]), isSubpath: isSubpath, item: path.value, commonIndices: commonIndices)
                jobs.append(job)
            }
        }
        return jobs
    }
    
    // TODO: Improve this logic
    private func findCommonIndiciesCount() -> Int {
        guard options.paths.isRemovingRedundantPaths else {
            return 0
        }
        var commonIndices = 0
        for index in spec.paths.keys[0].components.indices {
            let component = spec.paths.keys[0].components[index]
            for key in spec.paths.keys {
                guard key.components.indices.contains(index),
                      key.components[index] == component else {
                    return commonIndices
                }
                if key.components.indices.contains(index + 1),
                   key.components[(index + 1)].contains("{") {
                    return commonIndices
                }
                if let item = spec.paths[OpenAPI.Path(rawValue: key.components[...index].joined(separator: "/"))],
                   !item.allOperations.isEmpty {
                    return commonIndices
                }
            }
            commonIndices += 1
        }
        return commonIndices
    }
    
    // MARK: - Jobs (Operation)
    
    private struct JobOperation: Job {
        let path: OpenAPI.Path
        let item: OpenAPI.PathItem
        let method: String
        let operation: OpenAPI.Operation
        var filename: String
    }
    
    private func getOperationId(for operation: OpenAPI.Operation) -> String {
        if !options.rename.operations.isEmpty, let name = options.rename.operations[operation.operationId ?? ""] {
            return name
        }
        return operation.operationId ?? ""
    }
 
    private func makeJobsOperations() -> [JobOperation] {
        spec.paths.flatMap { path, item -> [JobOperation] in
            item.allOperations.map { method, operation in
                JobOperation(path: path, item: item, method: method, operation: operation, filename: getOperationId(for: operation))
            }
        }
    }
    
    // MARK: - Misc
    
    private func makeHeader() -> String {
        var header = fileHeader
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
            let skipped = !isNaiveDateNeeded ? Set(["NaiveDate"]) : Set()
            contents.append(templates.queryParameterEncoders(options.paths.queryParameterEncoders, skipped: skipped))
        }
        return GeneratedFile(name: "Extensions", contents: contents.joined(separator: "\n\n"))
    }
    
    // MARK: - Paths (Rest)
    
    private func makePath(job: JobRest) throws -> String {
        let component = job.lastComponent
        let parameterName = getPathParameterName(from: component)
        let type = makePathName(for: component)
    
        let parents = Array(job.components.dropLast().map(makePathName))
        let extensionOf = ([options.paths.namespace] + parents.map(\.rawValue)).joined(separator: ".")

        let context = Context(parents: parents + [type], namespace: arguments.module?.rawValue)
        let operations = job.isSubpath ? [] : try makeOperations(for: job.path, item: job.item, style: .rest, context: context)
        let generatedType = templates.pathEntity(name: type.rawValue, subpath: job.path.rawValue, operations: operations)
        
        let parameter = try parameterName.map { try getPathParameter(item: job.item, name: $0) }
        let path = job.isTopLevel ? job.path.rawValue : "/\(component)"
        return templates.pathExtension(of: extensionOf, component: component.isEmpty ? "root" : component, type: type, isTopLevel: job.isTopLevel, path: path, parameter: parameter, contents: generatedType)
    }
    
    private func makePathName(for component: String) -> TypeName {
        if component.isEmpty {
            return TypeName("Root")
        }
        if let parameter = getPathParameterName(from: component) {
            if parameter.count == component.count - 2 {
                return makeTypeName(parameter).prepending("With")
            } else {
                return makeTypeName(component.replacingOccurrences(of: "{\(parameter)}", with: "")).prepending("With")
            }
        }
        return makeTypeName(component)
    }
    
    // MARK: - Path Parameters
    
    // TODO: Refactor
    private func getPathParameter(item: OpenAPI.PathItem, name: String) throws -> PathParameter {
        let parameters = item.parameters.isEmpty ? (item.allOperations.first?.1.parameters ?? []) : item.parameters
        let parameter = parameters
            .compactMap { try? $0.unwrapped(in: spec) }
            .first { $0.context.inPath && $0.name == name }
        let type: TypeName
        if let parameter = parameter {
            type = try getPathParameterType(for: parameter)
        } else {
            type = TypeName("String")
        }
        return PathParameter(key: name, name: makePropertyName(name), type: type)
    }
    
    private func getPathParameterType(for parameter: OpenAPI.Parameter) throws -> TypeName {
        let (schema, _ ) = try parameter.unwrapped(in: spec)
        switch schema {
        case .integer: return TypeName("Int")
        default: return TypeName("String")
        }
    }
    
    private func getPathParameters(for item: OpenAPI.PathItem, _ operation: OpenAPI.Operation) throws -> [PathParameter] {
        let parameters = try (item.parameters + operation.parameters)
            .compactMap { try $0.unwrapped(in: spec) }
            .filter { $0.context.inPath }
        return try parameters.map {
            let type = try getPathParameterType(for: $0)
            return PathParameter(key: $0.name, name: makePropertyName($0.name), type: type)
        }
    }
        
    private func getPathParameterName(from component: String) -> String? {
        guard let from = component.firstIndex(of: "{"), let to = component.firstIndex(of: "}") else {
            return nil
        }
        return String(component[component.index(after: from)..<to])
    }
    
    // MARK: - Paths (Operation)
    
    private func makePath(job: JobOperation) throws -> String {
        let context = Context(parents: [], namespace: arguments.module?.rawValue)
        // TODO: Add non-strict version
        guard let entry = try makeOperation(job.path, job.item, job.operation, job.method, .operations, context) else {
            throw GeneratorError("Failed to generate operation")
        }
        return templates.extensionOf("Paths", contents: entry)
    }
    
    // MARK: - Operations

    private func makeOperations(for path: OpenAPI.Path, item: OpenAPI.PathItem, style: GenerateOptions.PathsStyle, context: Context) throws -> [String] {
        try item.allOperations.map { method, operation in
            try makeOperation(path, item, operation, method, style, context)
        }.compactMap { $0 }
    }

    private func makeOperation(_ path: OpenAPI.Path, _ item: OpenAPI.PathItem, _ operation: OpenAPI.Operation, _ method: String, _ style: GenerateOptions.PathsStyle, _ context: Context) throws -> String? {
        do {
            return try _makeOperation(path, item, operation, method, style, context)
        } catch {
            if arguments.isStrict {
                throw error
            } else {
                print("ERROR: Failed to generate \(method) for \(operation.operationId ?? "\(operation)"): \(error)")
                return nil
            }
        }
    }
    
    private func _makeOperation(_ path: OpenAPI.Path, _ item: OpenAPI.PathItem, _ operation: OpenAPI.Operation, _ method: String, _ style: GenerateOptions.PathsStyle, _ context: Context) throws -> String {
        let operationId = getOperationId(for: operation)
        if style == .operations, operationId.isEmpty {
            throw GeneratorError("OperationId is invalid or missing")
        }
        
        var nested: [String] = []
        var parameters: [String] = []
        var call: [String] = []
        
        func makeNestedTypeName(_ appending: String) -> TypeName {
            switch style {
            case .operations: return makeTypeName(operationId).appending(appending)
            case .rest: return TypeName("\(method.capitalizingFirstLetter())\(appending)")
            }
        }
        
        // Path parameters (operation only)
        switch style {
        case .operations:
            // TODO: What if parameters are common?
            var path = path.rawValue
            let pathParameters = try getPathParameters(for: item, operation)
            for parameter in pathParameters {
                if let range = path.range(of: "{\(parameter.key)}") {
                    path.replaceSubrange(range, with: "\\(" + parameter.name.rawValue + ")")
                    parameters.append("\(parameter.name): \(parameter.type)")
                }
            }
            if path.contains("{") {
                throw GeneratorError("One or more path parameters for \(operationId) is missing")
            }
            call.append("\"\(path)\"")
        case .rest:
            call.append("path") // Already provided by the wrapping type
        }

        // Response type and headers
        let responseType: String
        var responseHeaders: String?
        if let response = getSuccessfulResponse(for: operation) {
            let responseValue = try makeResponse(for: response, nestedTypeName: makeNestedTypeName("Response"), context: context)
            responseType = responseValue.type.rawValue
            if let value = responseValue.nested {
                nested.append(render(value))
            }
            responseHeaders = try? makeHeaders(for: response, name: makeNestedTypeName("ResponseHeaders").rawValue)
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
            let type = makeNestedTypeName("Parameters")
            // TODO: Relax the restriction for `operations` style
            if options.paths.isInliningSimpleQueryParameters && query.count <= options.paths.simpleQueryParametersThreshold, (style == .rest || query.allSatisfy { $0.nested == nil }) {
                for item in query {
                    parameters.append("\(item.name): \(item.type)\(item.isOptional ? "? = nil" : "")")
                }
                let initArgs = query.map { "\($0.name)" }.joined(separator: ", ")
                let initName = "make\(makeNestedTypeName("Query"))"
                let initalizer = "\(initName)(\(initArgs))"
                call.append("query: \(initalizer)")
                nested.append(templates.asQueryInline(name: initName, properties: query, isStatic: style == .operations))
                nested += query.compactMap { $0.nested }.map(render)
            } else {
                let isOptional = query.allSatisfy { $0.isOptional }
                parameters.append("parameters: \(type)\(isOptional ? "? = nil" : "")")
                call.append("query: parameters\(isOptional ? "?" : "").asQuery()")
                setNeedsQuery()
                nested.append(templates.entity(name: type, contents: contents, protocols: []))
            }
        }
        
        // Request body
        if let requestBody = operation.requestBody, method != "get" {
            let requestBody = try makeRequestBodyType(for: requestBody, method: method, nestedTypeName: makeNestedTypeName("Request"), context: context)
            if requestBody.type.rawValue != "Void" {
                if options.paths.isInliningSimpleRequestType,
                   let entity = (requestBody.nested as? EntityDeclaration),
                   entity.properties.count == 1,
                   !entity.isForm {
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
                    if let entity = (requestBody.nested as? EntityDeclaration), entity.isForm {
                        call.append("body: body\(requestBody.isOptional ? "?" : "").asQuery()")
                    } else {
                        call.append("body: body")
                    }
                    if let value = requestBody.nested {
                        nested.append(render(value))
                    }
                }
            }
        }
        
        // Finally, generate the output
        var contents = ".\(method)(\(call.joined(separator: ", ")))"
        if options.paths.isAddingOperationIds, !operationId.isEmpty {
            setNeedsRequestOperationIdExtension()
            contents += ".id(\"\(operationId)\")"
        }

        var output = templates.comments(for: .init(operation), name: "")
        let methodName = style == .operations ? makePropertyName(operationId).rawValue : method
        output += templates.methodOrProperty(name: methodName, parameters: parameters, returning: "Request<\(responseType)>", contents: contents, isStatic: style == .operations)
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
            case .integer(let info, _):
                guard options.isUsingIntegersWithPredefinedCapacity else {
                    return QueryItemType("Int")
                }
                switch info.format {
                case .generic, .other: return QueryItemType("Int")
                case .int32: return QueryItemType("Int32")
                case .int64: return QueryItemType("Int64")
                }
            case .string(let info, _):
                switch info.format {
                case .dateTime: return QueryItemType("Date")
                case .date: if options.isNaiveDateEnabled {
                    setNaiveDateNeeded()
                    return QueryItemType("NaiveDate")
                }
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
    // TODO: Add uploads support
    private func makeRequestBodyType(for requestBody: RequestBody, method: String, nestedTypeName: TypeName, context: Context) throws -> GeneratedType {
        var context = context
        context.isDecodableNeeded = false
        context.isPatch = method == "patch"
        
        let request = try requestBody.unwrapped(in: spec)
        
        func firstContent(for keys: [OpenAPI.ContentType]) -> (OpenAPI.Content, OpenAPI.ContentType)? {
            for key in keys {
                if let content = request.content[key] {
                    return (content, key)
                }
            }
            return nil
        }
        
        if request.content.values.isEmpty {
            return GeneratedType(type: TypeName("Void"))
        }
        
        func makeRequestType(_ type: TypeName, nested: Declaration? = nil) -> GeneratedType {
            GeneratedType(type: type, nested: nested, isOptional: !(requestBody.requestValue?.required ?? true))
        }
        
        if let (content, contentType) = firstContent(for: [.json, .jsonapi, .other("application/scim+json"), .form]) {
            let schema: JSONSchema
            switch content.schema {
            case .a(let reference):
                schema = JSONSchema.reference(reference)
            case .b(let value):
                switch value {
                case .string:
                    return makeRequestType(TypeName("String"))
                case .integer, .boolean:
                    return makeRequestType(TypeName("Data"))
                default:
                    schema = value
                }
            default:
                throw GeneratorError("ERROR: response not handled")
            }
            context.isFormEncoding = contentType == .form
            let property = try makeProperty(key: nestedTypeName.rawValue, schema: schema, isRequired: true, in: context)
            setNeedsEncodable(for: property.type)
            return makeRequestType(property.type.name, nested: property.nested)
        }
        if firstContent(for: [.multipartForm]) != nil {
            return makeRequestType(TypeName("Data"))
        }
        if arguments.vendor == "github", firstContent(for: [.other("application/octocat-stream")]) != nil {
            return makeRequestType(TypeName("String"))
        }
        if firstContent(for: [.css, .csv, .form, .html, .javascript, .txt, .xml, .yaml, .anyText, .other("application/jwt")]) != nil {
            return makeRequestType(TypeName("String"))
        }
        if firstContent(for: [.anyImage, .anyVideo, .anyAudio, .other("application/octet-stream")]) != nil {
            return makeRequestType(TypeName("Data"))
        }
        if let (content, _) = firstContent(for: [.any]) {
            if case .b(let schema) = content.schema, case .string = schema {
                return makeRequestType(TypeName("String"))
            }
            return makeRequestType(TypeName("Data"))
        }
        if arguments.isStrict {
            throw GeneratorError("Unknown request body content types: \(request.content.keys)")
        } else {
            print("WARNING: Unknown request body content types: \(request.content.keys)")
        }
        return makeRequestType(TypeName("Data"))
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

    private func makeResponse(for response: Response, nestedTypeName: TypeName, context: Context) throws -> GeneratedType {
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
        
        return try makeResponse(for: schema, nestedTypeName: nestedTypeName, context: context)
    }
    
    private func makeResponse(for response: OpenAPI.Response, nestedTypeName: TypeName, context: Context) throws -> GeneratedType {
        func firstContent(for keys: [OpenAPI.ContentType]) -> OpenAPI.Content? {
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
            let schema: JSONSchema
            switch content.schema {
            case .a(let reference):
                schema = JSONSchema.reference(reference)
            case .b(let value):
                switch value {
                case .string:
                    return GeneratedType(type: TypeName("String"))
                case .integer, .boolean:
                    return GeneratedType(type: TypeName("Data"))
                default:
                    schema = value
                }
            default:
                throw GeneratorError("ERROR: response not handled")
            }
            let property = try makeProperty(key: nestedTypeName.rawValue, schema: schema, isRequired: true, in: context)
            return GeneratedType(type: property.type.name, nested: property.nested)
        }
        if arguments.vendor == "github", firstContent(for: [.other("application/octocat-stream")]) != nil {
            return GeneratedType(type: TypeName("String"))
        }
        if firstContent(for: [.css, .csv, .form, .html, .javascript, .txt, .xml, .yaml, .anyText, .other("application/jwt")]) != nil {
            return GeneratedType(type: TypeName("String"))
        }
        if firstContent(for: [.anyImage, .anyVideo, .anyAudio, .other("application/octet-stream")]) != nil {
            return GeneratedType(type: TypeName("Data"))
        }
        if let content = firstContent(for: [.any]) {
            if case .b(let schema) = content.schema, case .string = schema {
                return GeneratedType(type: TypeName("String"))
            }
            return GeneratedType(type: TypeName("Data"))
        }
        if arguments.isStrict {
            throw GeneratorError("Unknown response body content types: \(response.content.keys)")
        } else {
            print("WARNING: Unknown response body content types: \(response.content.keys)")
        }
        return GeneratedType(type: TypeName("Data"))
    }
        
    // MARK: - Response Headers

    private func makeHeaders(for response: Response, name: String) throws -> String? {
        guard options.paths.isAddingResponseHeaders, let headers = response.responseValue?.headers else {
            return nil
        }
        let contents: [String] = try headers.map { try makeHeader(key: $0, header: $1) }
        guard !contents.isEmpty else {
            return nil
        }
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

protocol Job {
    var filename: String { get }
}
