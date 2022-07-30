// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import CreateOptions
import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Add support for common parameters and HTTP header parameteres
// TODO: Add support for multipart form data (currently defaults to `Data`)
// TODO: Add support for inlining body with `x-www-form-urlencoded` encoding
// TODO: Add support for `application/json-patch+json`
// TODO: Add in documentation additional context, e.g. "only values from 100 to 500"

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
                if arguments.isIgnoringErrors {
                    print("ERROR: Failed to generate path for \(job.filename): \(error)")
                } else {
                    lock.sync { generated[index] = .failure(error) }
                }
            }
        }
        return GeneratorOutput(
            header: makeHeader(imports: makePathImports()),
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
        case let job as JobGenerateRest: return try makePath(job: job)
        case let job as JobGenerateOperation: return try makePath(job: job)
        default: fatalError("Unsupported job")
        }
    }

    // MARK: - Jobs (Rest)
    
    // Generate code for the given (sub)path.
    private final class JobGenerateRest: Job {
        let types: [TypeName]
        var type: TypeName { types.last! }
        let component: String
        let path: OpenAPI.Path // Can be sub-path too
        let components: [String]
        var isSubpath: Bool
        let item: OpenAPI.PathItem
        let commonIndices: Int
        
        var isTopLevel: Bool { components.count == 1 }
        var filename: String { "Paths" + types.map(\.rawValue).joined(separator: "-") }
        
        init(types: [TypeName], component: String, path: OpenAPI.Path, components: [String], isSubpath: Bool, item: OpenAPI.PathItem, commonIndices: Int) {
            self.types = types
            self.component = component
            self.path = path
            self.components = components
            self.isSubpath = isSubpath
            self.item = item
            self.commonIndices = commonIndices
        }
    }
    
    // Make all jobs upfront so we could then parallelize code generation
    private func makeJobsRest() -> [JobGenerateRest] {
        guard !spec.paths.isEmpty else { return [] }
        
        let commonIndices = findCommonIndiciesCount()

        var jobs: [JobGenerateRest] = []
        var encountered = Set<OpenAPI.Path>()
        var generatedNames: [String: Int] = [:]
        for path in spec.paths {
            guard shouldGenerate(path: path.key.rawValue) else {
                verbose("Skipping path: \(path.key.rawValue)")
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

                // Find duplicated type names generated for different paths,
                // e.g. /last-names and /last_names (yes, some specs have that)
                var types = subpath.components.map(makePathName)
                let typesKey = types.map(\.rawValue).joined(separator: ".")
                if let count = generatedNames[typesKey] {
                    if let last = types.popLast() {
                        types.append(last.appending("\(count + 1)"))
                    }
                    generatedNames[typesKey] = count + 1
                } else {
                    generatedNames[typesKey] = 1
                }
                
                let job = JobGenerateRest(types: types, component: components[index], path: subpath, components: Array(components[commonIndices...index]), isSubpath: isSubpath, item: path.value, commonIndices: commonIndices)
                jobs.append(job)
            }
        }
        
        addGetPrefixIfNeeded(for: jobs)
        
        return jobs
    }
    
    private func shouldGenerate(path: String) -> Bool {
        if !options.paths.include.isEmpty {
            return options.paths.include.contains(path)
        }
        if !options.paths.exclude.isEmpty {
            return !options.paths.exclude.contains(path)
        }
        return true
    }
    
    // Add `Get.Request` instead of just `Request` in paths that themselve
    // define a `Request` type (to avoid conflicts).
    private func addGetPrefixIfNeeded(for jobs: [JobGenerateRest]) {
        // Figure out what subpaths contain "Request" type
        for job in jobs where job.type.rawValue == "Request" {
            let path = job.components.dropLast().joined(separator: "/")
            pathsContainingRequestType.append(path)
        }
    }
    
    private func needsGetPrefix(for path: OpenAPI.Path) -> Bool {
        pathsContainingRequestType.contains {
            path.components.joined(separator: "/").hasPrefix($0)
        }
    }
    
    // TODO: Make it smarter: skip intermediate path components too
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
    
    private struct JobGenerateOperation: Job {
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
 
    private func makeJobsOperations() -> [JobGenerateOperation] {
        spec.paths.flatMap { path, item -> [JobGenerateOperation] in
            guard shouldGenerate(path: path.rawValue) else {
                verbose("Skipping path: \(path.rawValue)")
                return []
            }
            return item.allOperations.map { method, operation in
                JobGenerateOperation(path: path, item: item, method: method, operation: operation, filename: getOperationId(for: operation))
            }
        }
    }
    
    // MARK: - Misc
    
    private func makePathImports() -> Set<String> {
        var imports = options.paths.imports
        if isHTTPHeadersDependencyNeeded { imports.insert("HTTPHeaders") }
        if isQueryEncoderNeeded { imports.insert("URLQueryEncoder") }
        return imports
    }
    
    private func makeExtensions() -> GeneratedFile? {
        var contents: [String] = []
        contents.append(templates.namespace(options.paths.namespace))
        if isRequestOperationIdExtensionNeeded {
            contents.append(templates.requestOperationIdExtension)
        }
        return GeneratedFile(name: "Extensions", contents: contents.joined(separator: "\n\n"))
    }
    
    // MARK: - Paths (Rest)
    
    private func makePath(job: JobGenerateRest) throws -> String {
        let parameterName = getPathParameterName(from: job.component)
    
        let parents = Array(job.components.dropLast().map(makePathName))
        let extensionOf = ([options.paths.namespace] + parents.map(\.rawValue)).joined(separator: ".")

        let context = Context(namespace: arguments.module.rawValue)
        let operations = job.isSubpath ? [] : try makeOperations(for: job.path, item: job.item, context: context)
        let generatedType = templates.pathEntity(name: job.type.rawValue, subpath: job.path.rawValue, operations: operations)
        
        let parameter = try parameterName.map { try getPathParameter(item: job.item, name: $0) }
        let path = job.isTopLevel ? job.path.rawValue : "/\(job.component)"
        return templates.pathExtension(of: extensionOf, component: job.component.isEmpty ? "root" : job.component, type: job.type, isTopLevel: job.isTopLevel, path: path, parameter: parameter, contents: generatedType)
    }
    
    private func makePathName(for component: String) -> TypeName {
        if component.isEmpty {
            return TypeName("Root")
        }
        if let parameter = getPathParameterName(from: component) {
            func makeType(for input: String) -> TypeName {
                // Remove ticks from types like `Type`. Maybe use a different techinque?
                TypeName("With" + makeTypeName(input).rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "`")))
            }
            if parameter.count == component.count - 2 {
                return makeType(for: parameter)
            } else {
                return makeType(for: component.replacingOccurrences(of: "{\(parameter)}", with: ""))
            }
        }
        return makeTypeName(component)
    }
    
    // MARK: - Path Parameters
    
    private func getPathParameter(item: OpenAPI.PathItem, name: String) throws -> PathParameter {
        let parameters = item.parameters.isEmpty ? (item.allOperations.first?.1.parameters ?? []) : item.parameters
        let parameter = try parameters
            .map { try $0.unwrapped(in: spec) }
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
        let schema = try parameter.unwrapped(in: spec).schema.unwrapped(in: spec)
        switch schema.value {
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
        guard let from = component.firstIndex(of: "{"),
              let to = component.firstIndex(of: "}") else {
                  return nil
              }
        return String(component[component.index(after: from)..<to])
    }
    
    // MARK: - Paths (Operation)
    
    private func makePath(job: JobGenerateOperation) throws -> String {
        let context = Context(namespace: arguments.module.rawValue)
        var nestedTypeNames = Set<TypeName>()
        let task = GenerateOperationTask(path: job.path, item: job.item, method: job.method, operation: job.operation, operationId: getOperationId(for: job.operation), options: options)
        guard let entry = try makeOperation(task: task, context, &nestedTypeNames) else {
            throw GeneratorError("Failed to generate operation")
        }
        return templates.extensionOf(options.paths.namespace, contents: entry)
    }
    
    // MARK: - Operations

    private final class GenerateOperationTask {
        let path: OpenAPI.Path
        let item: OpenAPI.PathItem
        let method: String
        let operation: OpenAPI.Operation
        let operationId: String
        let options: GenerateOptions
        
        init(path: OpenAPI.Path, item: OpenAPI.PathItem, method: String, operation: OpenAPI.Operation, operationId: String, options: GenerateOptions) {
            self.path = path
            self.item = item
            self.method = method
            self.operation = operation
            self.operationId = operationId
            self.options = options
        }
        
        func makeNestedTypeName(_ appending: String) -> TypeName {
            switch options.paths.style {
            case .operations:
                return TypeName(processing: operationId, options: options).appending(appending)
            case .rest:
                return TypeName("\(method.capitalizingFirstLetter())\(appending)")
            }
        }
    }
    
    private func makeOperations(for path: OpenAPI.Path, item: OpenAPI.PathItem, context: Context) throws -> [String] {
        var nestedTypeNames = Set<TypeName>()
        return try item.allOperations.map { method, operation in
            let task = GenerateOperationTask(path: path, item: item, method: method, operation: operation, operationId: getOperationId(for: operation), options: options)
            return try makeOperation(task: task, context, &nestedTypeNames)
        }.compactMap { $0 }
    }

    private func makeOperation(task: GenerateOperationTask, _ context: Context, _ nestedTypeNames: inout Set<TypeName>) throws -> String? {
        do {
            return try _makeOperation(task, context, &nestedTypeNames)
        } catch {
            return try handle(error: "Failed to generate \(task.method) for \(task.operation). \(error)")
        }
    }

    private func _makeOperation(_ task: GenerateOperationTask, _ context: Context, _ nestedTypeNames: inout Set<TypeName>) throws -> String {
        let style = options.paths.style
        if style == .operations, task.operationId.isEmpty {
            throw GeneratorError("OperationId is invalid or missing")
        }
        
        var parameters: [String] = []
        var call: [String] = []
        var nested: [Declaration] = []
        
        // Add `path` parameter to the call
        switch style {
        case .operations:
            var path = task.path.rawValue
            for parameter in try getPathParameters(for: task.item, task.operation) {
                if let range = path.range(of: "{\(parameter.key)}") {
                    path.replaceSubrange(range, with: "\\(" + parameter.name.rawValue + ")")
                    parameters.append("\(parameter.name): \(parameter.type)")
                }
            }
            if path.contains("{") {
                throw GeneratorError("One or more path parameters for \(task.operationId) is missing")
            }
            call.append("\"\(path)\"")
        case .rest:
            call.append("path") // Already provided by the wrapping type
        }

        // Response type
        let response = try makeResponse(for: task, context: context)
        if let value = response.nested { nested.append(value) }
        
        // Response headers
        if let headers = try makeResponseHeaders(for: task) {
            nested.append(headers)
        }
        
        // Query parameters
        let query = try task.operation.parameters.compactMap {
            try makeQueryParameter(for: $0, context: context)
        }.removingDuplicates(by: \.name)
        if query.isEmpty {
            // Do nothing
        } else if options.paths.isInliningSimpleQueryParameters && query.count <= options.paths.simpleQueryParametersThreshold && (style == .rest || query.allSatisfy { $0.nested == nil }) {
            for item in query {
                parameters.append("\(item.name): \(item.type)\(item.isOptional ? "? = nil" : "")")
            }
            if query.count < 3, query.allSatisfy({ ["String", "Int", "Double", "Bool"].contains($0.type.name.rawValue) && !$0.isOptional }) {
                call.append("query: \(templates.asKeyValuePairs(query))")
            } else {
                // Skip creatning nested entity, and add simple make*Query method instead
                let initArgs = query.map { "\($0.name)" }.joined(separator: ", ")
                let initName = "make\(task.makeNestedTypeName("Query"))"
                let initalizer = "\(initName)(\(initArgs))"
                call.append("query: \(initalizer)")
                nested.append(AnyDeclaration(name: TypeName(initName), rawValue: templates.asQueryInline(name: initName, properties: query, isStatic: style == .operations)))
                nested += query.compactMap { $0.nested } // Add nested types directly
                setNeedsQuery()
            }
        } else {
            // Add full `\(Method)Parameters` entity
            let type = task.makeNestedTypeName("Parameters")
            
            let isOptional = query.allSatisfy { $0.isOptional }
            parameters.append("parameters: \(type)\(isOptional ? "? = nil" : "")")
            call.append("query: parameters\(isOptional ? "?" : "").asQuery")
            
            let entity = EntityDeclaration(name: type, type: .object, metadata: .init(nil), isForm: true)
            entity.isRenderedAsStruct = true
            entity.properties = query
            nested.append(entity)
            
            setNeedsQuery()
        }
        
        // Request body
        if let requestBody = task.operation.requestBody, task.method != "get" {
            let requestBody = try makeRequestBodyType(for: requestBody, method: task.method, nestedTypeName: task.makeNestedTypeName("Request"), context: context)
            if requestBody.type.rawValue == "Void" {
                // Do nothing
            } else if options.paths.isInliningSimpleRequests,
                      let entity = (requestBody.nested as? EntityDeclaration),
                      entity.properties.count == 1,
                      !entity.isForm,
                      !parameters.contains(where: { $0.hasPrefix(entity.properties[0].name.rawValue + ":") })  {
                let property = entity.properties[0]
                if entity.isNested(property.type.elementType) {
                    parameters.append("\(property.name): \(property.type.identifier(namespace: entity.name.rawValue))\(property.isOptional ? "? = nil" : "")")
                    call.append("body: \(entity.name)(\(property.name): \(property.name))")
                    if let value = requestBody.nested { nested.append(value) }
                } else {
                    parameters.append("\(property.name): \(property.type)\(property.isOptional ? "? = nil" : "")")
                    call.append("body: [\"\(property.key)\": \(property.name)]")
                }
            } else {
                parameters.append("_ body: \(requestBody.type)\(requestBody.isOptional ? "? = nil" : "")")
                if let entity = (requestBody.nested as? EntityDeclaration), entity.isForm {
                    call.append("body: \(templates.asURLEncodedBody(name: "body", requestBody.isOptional))")
                } else {
                    call.append("body: body")
                }
                if let value = requestBody.nested { nested.append(value) }
            }
        }

        // Add disambiguation for `path` (property vs argument name)
        if call.first == "path" && parameters.contains(where: { $0.hasPrefix("path:")}) {
            call[0] = "self.path"
        }

        // Finally, generate the output
        var contents = ".\(task.method)(\(call.joined(separator: ", ")))"

        // Add `.id`
        if options.paths.isAddingOperationIds, !task.operationId.isEmpty {
            setNeedsRequestOperationIdExtension()
            contents += ".id(\"\(task.operationId)\")"
        }

        var output = templates.comments(for: .init(task.operation), name: "")
        let methodName = style == .operations ? makePropertyName(task.operationId).rawValue : task.method
        let prefix = needsGetPrefix(for: task.path) ? "Get." : ""
        output += templates.methodOrProperty(name: methodName, parameters: parameters, returning: "\(prefix)Request<\(response.type)>", contents: contents, isStatic: style == .operations)
        for value in nested where !nestedTypeNames.contains(value.name) {
            nestedTypeNames.insert(value.name)
            output += "\n\n"
            output += render(value)
        }
        return output
    }
    
    // MARK: - Query Parameters
    
    private func makeQueryParameter(for input: Either<JSONReference<OpenAPI.Parameter>, OpenAPI.Parameter>, context: Context) throws -> Property? {
        do {
            var context = context
            context.isFormEncoding = true
            guard let property = try _makeQueryParameter(for: input, context: context) else {
                return nil
            }
            return property
        } catch {
            return try handle(error: "Failed to generate query parameter \(input.description). \(error)")
        }
    }

    private func _makeQueryParameter(for input: Either<JSONReference<OpenAPI.Parameter>, OpenAPI.Parameter>, context: Context) throws -> Property? {
        let parameter = try input.unwrapped(in: spec)
        guard parameter.context.inQuery else {
            return nil
        }
        let schemaContext = try parameter.unwrapped(in: spec)
        let schema = try schemaContext.schema.unwrapped(in: spec)
        
        struct QueryItemType {
            var type: TypeIdentifier
            var nested: Declaration?
            
            init(type: TypeIdentifier, nested: Declaration? = nil) {
                self.type = type
                self.nested = nested
            }
            
            init(_ name: String) {
                self.type = .builtin(name)
            }
        }
                
        func getQueryItemType(for schema: JSONSchema, isTopLevel: Bool) throws -> QueryItemType? {
            switch schema.value {
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
            case .object, .all, .one, .any:
                let type = makeTypeName(parameter.name)
                let nested = try _makeDeclaration(name: type, schema: schema, context: context)
                return QueryItemType(type: .userDefined(name: type), nested: nested)
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
            case .reference(let ref, _):
                guard let name = ref.name.map(makeTypeName) else {
                    throw GeneratorError("Missing or invalid reference name")
                }
                if let type = try getTypeIdentifier(for: name, schema: schema, context: context) {
                    return type.isVoid ? nil : QueryItemType(type: type)
                }
                return QueryItemType(type: .userDefined(name: name))
            case .fragment:
                return QueryItemType("String")
            case .not:
                throw GeneratorError("Unsupported query parameter type: \(parameter)")
            }
        }
        
        guard let type = try getQueryItemType(for: schema, isTopLevel: true) else {
            return nil
        }
        
        func getPropertyName(for name: PropertyName, type: TypeIdentifier) -> PropertyName {
            if let name = options.rename.parameters[name.rawValue] {
                return PropertyName(name)
            }
            if options.isGeneratingSwiftyBooleanPropertyNames && type.isBool {
                return name.asBoolean(options)
            }
            return name
        }

        let name = getPropertyName(for: makePropertyName(parameter.name), type: type.type)
        return Property(name: name, type: type.type, isOptional: !parameter.required, key: parameter.name, explode: schemaContext.explode, style: schemaContext.style, metadata: .init(schema.coreContext), nested: type.nested)
    }
        
    // MARK: - Request Body
    
    private typealias RequestBody = Either<JSONReference<OpenAPI.Request>, OpenAPI.Request>

    private func makeRequestBodyType(for requestBody: RequestBody, method: String, nestedTypeName: TypeName, context: Context) throws -> BodyType {
        var context = context
        context.isDecodableNeeded = false
        context.isPatch = method == "patch"
        
        let request = try requestBody.unwrapped(in: spec)
        
        var type = try makeBodyType(for: request.content, nestedTypeName: nestedTypeName, context: context)
        type.isOptional = !(requestBody.requestValue?.required ?? true)
        return type
    }
    
    // MARK: - Response Body
    
    private typealias Response = Either<JSONReference<OpenAPI.Response>, OpenAPI.Response>
    
    private func makeResponse(for task: GenerateOperationTask, context: Context) throws -> BodyType {
        guard let response = task.operation.firstSuccessfulResponse else {
            return BodyType("Void")
        }
        
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
                if let rename = options.paths.overridenResponses[name] {
                    return BodyType(type: TypeName(rename))
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
        
        let type = task.makeNestedTypeName("Response")
        return try makeBodyType(for: schema.content, nestedTypeName: type, context: context)
    }
    
    // MARK: - (Any) Body
    
    private struct BodyType {
        var type: TypeName
        var nested: Declaration?
        var isOptional = false
        
        init(_ name: String) {
            self.type = TypeName(name)
        }
        
        init(type: TypeName, nested: Declaration? = nil) {
            self.type = type
            self.nested = nested
        }
    }

    private func makeBodyType(for content: OpenAPI.Content.Map, nestedTypeName: TypeName, context: Context) throws -> BodyType {
        if content.values.isEmpty {
            return BodyType("Void")
        }
        
        if !options.paths.overridenBodyTypes.isEmpty {
            for key in content.keys {
                if let type = options.paths.overridenBodyTypes[key.rawValue] {
                    return BodyType(type)
                }
            }
        }
        
        func firstContent(for keys: [OpenAPI.ContentType]) -> (OpenAPI.Content, OpenAPI.ContentType)? {
            for key in keys {
                if let content = content.first(where: { $0.key.typeAndSubtype == key.typeAndSubtype }) {
                    return (content.value, content.key)
                }
            }
            return nil
        }
        
        if let (content, contentType) = firstContent(for: [.json, .jsonapi, .other("application/scim+json"), .other("application/json"), .form]) {
            let schema: JSONSchema
            switch content.schema {
            case .a(let reference):
                schema = JSONSchema.reference(reference)
            case .b(let value):
                switch value {
                case .string: return BodyType("String")
                case .integer, .boolean: return BodyType("Data")
                default: schema = value
                }
            default:
                return BodyType("String")
            }
            var context = context
            if contentType == .form {
                setNeedsQuery()
                context.isFormEncoding = true
            }
            let property = try makeProperty(key: nestedTypeName.rawValue, schema: schema, isRequired: true, in: context)
            if contentType != .form {
                setNeedsEncodable(for: property.type)
            }
            return BodyType(type: property.type.name, nested: property.nested)
        }
        if firstContent(for: [.multipartForm]) != nil {
            return BodyType("Data") // Currently isn't supported
        }
        if firstContent(for: [.css, .csv, .form, .html, .javascript, .txt, .xml, .yaml, .anyText, .other("application/jwt"), .other("image/svg+xml"), .other("text/xml"), .other("plain/text")]) != nil {
            return BodyType("String")
        }
        if firstContent(for: [
            .bmp, .jpg, .tif, .anyImage, .other("image/jpg"),
            .mov, .mp4, .mpg, .anyVideo,
            .mp3, .anyAudio,
            .rar, .tar, .zip, .other("gzip"), .other("application/gzip"),
            .pdf,
            .other("application/octet-stream")
        ]) != nil {
            return BodyType("Data")
        }
        if let (content, _) = firstContent(for: [.any]) {
            if case .b(let schema) = content.schema, case .string = schema.value {
                return BodyType("String")
            }
            return BodyType("Data")
        }
        if firstContent(for: [.other("application/json-patch+json")]) != nil {
            return BodyType("Data") // Currently isn't supported
        }
        try handle(warning: "Unknown body content types: \(content.keys), defaulting to Data. Use paths.overridenBodyTypes to add support for your content types.")
        return BodyType("Data")
    }
        
    // MARK: - Response Headers

    private func makeResponseHeaders(for task: GenerateOperationTask) throws -> Declaration? {
        guard options.paths.isGeneratingResponseHeaders,
              let response = task.operation.firstSuccessfulResponse,
              let headers = response.responseValue?.headers else {
            return nil
        }
        let contents = try headers.map(makeHeader)
        guard !contents.isEmpty else {
            return nil
        }
        setNeedsHTTPHeadersDependency()
        let name = task.makeNestedTypeName("ResponseHeaders")
        let raw = templates.headers(name: name.rawValue, contents: contents.joined(separator: "\n"))
        return AnyDeclaration(name: name, rawValue: raw)
    }
    
    private func makeHeader(key: String, header: Either<JSONReference<OpenAPI.Header>, OpenAPI.Header>) throws -> String {
        let header = try header.unwrapped(in: spec)
        switch header.schemaOrContent {
        case .a(let value):
            let schema = try value.schema.unwrapped(in: spec)
            var property = try makeProperty(key: key, schema: schema, isRequired: schema.required, in: Context())
            // Avoid generating enums for properties
            if case .string = schema.value, case .userDefined = property.type {
                property.type = .builtin("String")
            }
            return templates.header(for: property, header: header)
        case .b:
            throw GeneratorError("HTTP headers with content map are not supported")
        }
    }
}

private protocol Job {
    var filename: String { get }
}
