// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Add Read-Only and Write-Only Properties support
// TODO: stirng with format "binary"?
// TODO: Add an option to convert optional arrays to empty arrays
// TODO: Add support for more default values, strings, arrays?
// TODO: `Rename.entities` to support nested types
// TODO: Add `Rename.enums`
// TODO: Add an option to hide `anyJSON`
// TODO: Generate IDs with phantom types
// TODO: Add `byte` and `binary` string formats support
// TODO: Clarify intentions behind `properties` mixed with `anyOf` https://github.com/github/rest-api-description/discussions/805
// TODO: `entitiesGeneratedAsClasses` - add support for nesting
// TODO: Remove StringCodingKeys when they are not needed

extension Generator {
    func schemas() throws -> GeneratorOutput {
        let benchmark = Benchmark(name: "Generating entities")
        defer { benchmark.stop() }
        return try _schemas()
    }
    
    private func _schemas() throws -> GeneratorOutput {
        let jobs = try makeJobs()
        var declarations = Array<Result<Declaration, Error>?>(repeating: nil, count: jobs.count)
        topLevelTypes = Set(jobs.map(\.name))
        let lock = NSLock()
        
        concurrentPerform(on: jobs, parallel: arguments.isParallel) { index, job in
            let job = jobs[index]

            do {
                if let decl = try makeDeclaration(job: job) {
                    lock.sync {
                        declarations[index] = .success(decl)
                    }
                }
            } catch {
                if arguments.isIgnoringErrors {
                    print("ERROR: Failed to generate entity for \(job.name.rawValue): \(error)")
                } else {
                    lock.sync { declarations[index] = .failure(error) }
                }
            }
        }

        // Preprocess before rendering.
        try preprocess(declarations: declarations.compactMap { $0 })

        // Render entities as a final phase
        let files: [GeneratedFile] = try zip(jobs, declarations).map { job, result in
            guard let entity = try result?.get() else { return nil }
            return GeneratedFile(name: job.name.rawValue, contents: render(entity))
        }.compactMap { $0 }
   
        return GeneratorOutput(
            header: makeHeader(imports: options.entities.imports),
            files: files,
            extensions: makeExtensions()
        )
    }
    
    private func preprocess(declarations: [Result<Declaration, Error>]) throws {
        // Create an index of all generated entities.
        for result in declarations {
            let entity = try result.get()
            generatedSchemas[entity.name] = entity as? EntityDeclaration
        }
    }
    
    private func makeJobs() throws -> [Job] {
        var jobs: [Job] = []
        var encountered = Set<TypeName>()
        for (key, schema) in spec.components.schemas {
            guard let name = getTypeName(for: key) else {
                continue
            }

            guard shouldGenerate(name: name.rawValue) else {
                verbose("Skipping entity named: \(name.rawValue)")
                continue
            }

            let job = Job(name: name, schema: schema)
            if encountered.contains(job.name) {
                try handle(warning: "Duplicated type name: \(job.name), skipping")
            } else {
                encountered.insert(job.name)
                jobs.append(job)
            }
        }
        return jobs
    }
    
    private func shouldGenerate(name: String) -> Bool {
        if !options.entities.include.isEmpty {
            return options.entities.include.contains(name)
        }
        if !options.entities.exclude.isEmpty {
            return !options.entities.exclude.contains(name)
        }
        return true
    }
    
    private struct Job {
        let name: TypeName
        let schema: JSONSchema
    }
    
    private func makeExtensions() -> GeneratedFile? {
        var contents: [String] = []
        if isAnyJSONUsed {
            contents.append(templates.anyJSON)
        }
        contents.append(stringCodingKey)
        guard !contents.isEmpty else {
            return nil
        }
        return GeneratedFile(name: "Extensions", contents: contents.joined(separator: "\n\n"))
    }
    
    /// Return `nil` to skip generation.
    private func getTypeName(for key: OpenAPI.ComponentKey) -> TypeName? {
        var name: String? {
            if arguments.vendor == "github" {
                // This makes sense only for the GitHub API spec where types like
                // `simple-user` and `nullable-simple-user` exist which are duplicate
                // and the only different is that the latter is nullable.
                if key.rawValue.hasPrefix("nullable-") {
                    let counterpart = key.rawValue.replacingOccurrences(of: "nullable-", with: "")
                    if let counterpartKey = OpenAPI.ComponentKey(rawValue: counterpart),
                       spec.components.schemas[counterpartKey] != nil {
                        return nil
                    } else {
                        // Some types in GitHub specs are only defined once as Nullable
                        return counterpart
                    }
                }
            }
            if !options.rename.entities.isEmpty {
                let name = makeTypeName(key.rawValue)
                if let mapped = options.rename.entities[name.rawValue] {
                    return mapped
                }
            }
            return key.rawValue
        }
        if let name = name {
            return makeTypeName(Template(arguments.entityNameTemplate).substitute(name))
        } else {
            return nil
        }
    }

    // MARK: - Declarations
    
    private func makeDeclaration(job: Job) throws -> Declaration? {
        let context = Context(parents: [])
        return try makeDeclaration(name: job.name, schema: job.schema, context: context)
    }
    
    func makeDeclaration(name: TypeName, schema: JSONSchema, context: Context) throws -> Declaration? {
        let declaration = try _makeDeclaration(name: name, schema: schema, context: context)
        if options.isInliningTypealiases, let alias = declaration as? TypealiasDeclaration {
            return alias.nested
        }
        return declaration
    }
    
    /// Recursively a type declaration: struct, class, enum, typealias, etc.
    func _makeDeclaration(name: TypeName, schema: JSONSchema, context: Context) throws -> Declaration {
        switch schema.value {
        case .boolean:
            return TypealiasDeclaration(name: name, type: .builtin("Bool"))
        case .number:
            return TypealiasDeclaration(name: name, type: .builtin("Double"))
        case .integer(let info, _):
            return TypealiasDeclaration(name: name, type: getIntegerType(for: info))
        case .string(let info, _):
            if isEnum(info) {
                return try makeStringEnum(name: name, info: info)
            } else {
                return TypealiasDeclaration(name: name, type: getStringType(for: info))
            }
        case .object(let info, let details):
            return try makeObject(name: name, info: info, details: details, context: context)
        case .array(let info, let details):
            return try makeTypealiasArray(name: name, info: info, details: details, context: context)
        case .all(let schemas, _) where schemas.count == 1, // unnest allOf/oneOf/anyOf when only a single schema is present
             .one(let schemas, _) where schemas.count == 1,
             .any(let schemas, _) where schemas.count == 1:
            return try _makeDeclaration(name: name, schema: schemas[0], context: context)
        case .all(let schemas, let info):
            return try makeAllOf(name: name, schemas: schemas, info: info, context: context)
        case .one(let schemas, let info):
            return try makeOneOf(name: name, schemas: schemas, info: info, context: context)
        case .any(let schemas, let info):
            return try makeAnyOf(name: name, schemas: schemas, info: info, context: context)
        case .not:
            throw GeneratorError("`not` is not supported: \(name)")
        case .reference(let info, _):
            guard let ref = info.name, !ref.isEmpty else {
                throw GeneratorError("Reference name is missing")
            }
            let type = try getReferenceType(info, context: context)
            return TypealiasDeclaration(name: name, type: type)
        case .fragment:
            setNeedsAnyJson()
            return TypealiasDeclaration(name: name, type: .anyJSON)
        }
    }
    
    func getTypeIdentifier(for name: TypeName, schema: JSONSchema, context: Context) throws -> TypeIdentifier? {
        var context = context
        context.isInlinableTypeCheck = true
        let decl = try _makeDeclaration(name: name, schema: schema, context: context)
        return (decl as? TypealiasDeclaration)?.type
    }
    
    private func getIntegerType(for info: JSONSchema.CoreContext<JSONTypeFormat.IntegerFormat>) -> TypeIdentifier {
        guard options.isUsingIntegersWithPredefinedCapacity else {
            return .builtin("Int")
        }
        switch info.format {
        case .generic, .other: return .builtin("Int")
        case .int32: return .builtin("Int32")
        case .int64: return .builtin("Int64")
        }
    }
    
    private func getStringType(for info: JSONSchema.CoreContext<JSONTypeFormat.StringFormat>) -> TypeIdentifier {
        switch info.format {
        case .dateTime: return .builtin("Date")
        case .date: if options.isNaiveDateEnabled {
            setNaiveDateNeeded()
            return .builtin("NaiveDate")
        }
        case .other(let other) where other == "uri": 
            return .builtin("URL")
        case .other(let other) where other == "uuid":
            return .builtin("UUID")
        case .byte:
          return .builtin("Data")
        default: break
        }
        return .builtin("String")
    }

    private func getReferenceType(_ reference: JSONReference<JSONSchema>, context: Context) throws -> TypeIdentifier {
        switch reference {
        case .internal(let ref):
            return try getReferenceType(ref, context: context)
        case .external(let url):
            throw GeneratorError("External references are not supported: \(url)")
        }
    }
    
    private func getReferenceType(_ ref: JSONReference<JSONSchema>.InternalReference, context: Context) throws -> TypeIdentifier {
        if arguments.vendor == "github", let name = ref.name, name.hasPrefix("nullable-") {
            let replacement = makeTypeName(name.replacingOccurrences(of: "nullable-", with: ""))
            return .userDefined(name: replacement.namespace(context.namespace))
        }
        // Note: while dereferencing, it does it recursively.
        // So if you have `typealias Pets = [Pet]`, it'll dereference
        // `Pet` to an `.object`, not a `.reference`.
        if options.isInliningTypealiases, let name = ref.name {
            // Check if the schema can be expanded into a type identifier
            let type = makeTypeName(name)
            if let key = OpenAPI.ComponentKey(rawValue: name),
               let schema = spec.components.schemas[key] {
                // If there is a cycle, it can't be a primitive value (and we must stop recursion)
                if context.encountered.contains(key) {
                    return .userDefined(name: makeTypeName(name).namespace(context.namespace))
                }
                var context = context
                context.encountered.insert(key)
                
                // No retain cycle - check the reference
                if let type = try getTypeIdentifier(for: type, schema: schema, context: context) {
                    return type
                }
            }
        }
        guard let referenceName = ref.name else {
            throw GeneratorError("Internal reference name is missing: \(ref)")
        }
        var name = referenceName
        // Check if the entity is missing
        if let key = OpenAPI.ComponentKey(rawValue: name) {
            if spec.components.schemas[key] == nil {
                try handle(warning: "A reference \"\(name)\" is missing.")
                return .anyJSON
            }
        }
        // TODO: Remove duplication
        if !options.rename.entities.isEmpty {
            if let mapped = options.rename.entities[name] {
                name = mapped
            }
        }
        name = Template(arguments.entityNameTemplate).substitute(name)
        return .userDefined(name: makeTypeName(name).namespace(context.namespace))
    }
    
    // MARK: - Object
    
    private func makeObject(name: TypeName, info: JSONSchema.CoreContext<JSONTypeFormat.ObjectFormat>, details: JSONSchema.ObjectContext, context: Context) throws -> Declaration {
        if let dictionary = try makeDictionary(key: name.rawValue, info: info, details: details, context: context) {
            return TypealiasDeclaration(name: name, type: dictionary.type, nested: dictionary.nested)
        }
        guard !context.isInlinableTypeCheck else { return AnyDeclaration.empty }

        var (entity, context) = makeEntity(name: name, type: .object, info: info, context: context)
        context.objectSchema = details
        entity.properties = try makeInlineProperties(for: name, object: details, context: context)
            .filter { !$0.type.isVoid }
            .removingDuplicates(by: \.name) // Sometimes Swifty bool names create dups
        entity.protocols = getProtocols(for: entity, context: context)
        
        return entity
    }
    
    private func getProtocols(for entity: EntityDeclaration, context: Context) -> Protocols {
        var protocols = Protocols(options.entities.protocols)
        let isDecodable = protocols.isDecodable && (context.isDecodableNeeded || !options.entities.isSkippingRedundantProtocols)
        let isEncodable = protocols.isEncodable && (context.isEncodableNeeded || !options.entities.isSkippingRedundantProtocols)
        if !isDecodable { protocols.removeDecodable() }
        if !isEncodable { protocols.removeEncodable() }
        
        if options.entities.isGeneratingIdentifiableConformance {
            let isIdentifiable = entity.properties.contains { $0.name.rawValue == "id" && $0.type.isBuiltin }
            if isIdentifiable { protocols.insert("Identifiable") }
        }
        
        return protocols
    }
    
    private func makeInlineProperties(for type: TypeName, object: JSONSchema.ObjectContext, context: Context) throws -> [Property] {
        var keys = object.properties.keys
        if options.entities.isSortingPropertiesAlphabetically { keys.sort() }
        return try keys.compactMap { key in
            let schema = object.properties[key]!
            let isRequired = object.requiredProperties.contains(key)
            do {
                return try makeProperty(key: key, schema: schema, isRequired: isRequired, in: context, isInlined: true)
            } catch {
                return try handle(error: "Failed to generate property \"\(key)\" in \"\(type)\". \(error).")
            }
        }
    }
    
    private func makeNestedElementTypeName(for key: String, context: Context) -> TypeName {
        if let name = options.rename.collectionElements[key] {
            return TypeName(name)
        }
        let name = makeTypeName(key)
        // Some know words that the library doesn't handle well
        if name.rawValue == "Environments" { return TypeName("Environment") }
        let words = name.rawValue.trimmingCharacters(in: CharacterSet.ticks).words
        if words.last?.singularized() != words.last {
            let sing = (words.dropLast() + [words.last?.singularized()])
                .compactMap { $0?.capitalizingFirstLetter() }
                .joined(separator: "")
            if context.parents.isEmpty && !topLevelTypes.contains(TypeName(sing)) {
                return makeTypeName(sing)
            }
            if !context.parents.isEmpty && !hasConflict(name: TypeName(sing), context: context.objectSchema) {
                return makeTypeName(sing)
            }
        }
        return name.appending("Item")
    }
    
    // TODO: This take inlining into account
    private func hasConflict(name: TypeName, context: JSONSchema.ObjectContext?) -> Bool {
        guard let context = context else {
            return false
        }
        return context.properties.contains { key, value in
            switch value.value {
            case .object, .all, .any, .one:
                return makeTypeName(key) == name
            default:
                return false
            }
        }
    }
    
    private struct AdditionalProperties {
        let type: TypeIdentifier
        let info: JSONSchemaContext
        var nested: Declaration?
    }
    
    // Creates a dictionary, e.g. `[ String: AnyJSON]`, `[String: [String: String]]`,
    // `[String: CustomNestedType]`. Returns `Void` if no properties are allowed.
    private func makeDictionary(key: String, info: JSONSchemaContext, details: JSONSchema.ObjectContext, context: Context) throws -> AdditionalProperties? {
        var additional = details.additionalProperties
        if details.properties.isEmpty, options.entities.isAdditionalPropertiesOnByDefault {
            additional = additional ?? .a(true)
        }
        guard let additional = additional else {
            return nil
        }
        switch additional {
        case .a(let allowed):
            if !allowed && details.properties.isEmpty {
                return AdditionalProperties(type: .builtin("Void"), info: info)
            }
            if !details.properties.isEmpty {
                return nil
            }
            setNeedsAnyJson()
            return AdditionalProperties(type: .dictionary(value: .anyJSON), info: info)
        case .b(let schema):
            let nestedTypeName = makeNestedElementTypeName(for: key, context: context)
            let decl = try _makeDeclaration(name: nestedTypeName, schema: schema, context: context)
            switch decl {
            case let alias as TypealiasDeclaration:
                return AdditionalProperties(type: .dictionary(value: alias.type), info: info)
            default:
                return AdditionalProperties(type: .dictionary(value: .userDefined(name: nestedTypeName)), info: info, nested: decl)
            }
        }
    }

    private func makeDiscriminator(info: JSONSchemaContext, context: Context) throws -> Discriminator? {
        if let discriminator = info.discriminator {
            var mapping: [String: TypeIdentifier] = [:]

            if let innerMapping = discriminator.mapping {
                for (key, value) in innerMapping {
                    let stripped = String(value.dropFirst("#/components/schemas/".count))
                    guard let componentKey = OpenAPI.ComponentKey(rawValue: stripped) else {
                        throw GeneratorError("Encountered invalid type name \"\(value)\" while constructing discriminator")
                    }

                    if let name = getTypeName(for: componentKey) {
                        mapping[key] = .userDefined(name: name)
                    } else {
                        try handle(warning: "Mapping \"\(key)\" has no matching type")
                    }
                }
            }

            return .init(
                propertyName: discriminator.propertyName,
                mapping: mapping
            )
        }

        return .none
    }

    // MARK: - oneOf/anyOf/allOf
    
    private func makeEntity(name: TypeName, type: EntityType, info: JSONSchemaContext, context: Context) -> (EntityDeclaration, Context) {
        let entity = EntityDeclaration(
            name: name, 
            type: type, 
            metadata: DeclarationMetadata(info), 
            isForm: context.isFormEncoding,
            parent: context.parents.last
        )
        let context = context.map { $0.parents.append(entity) }
        return (entity, context)
    }
    
    private func makeOneOf(name: TypeName, schemas: [JSONSchema], info: JSONSchemaContext, context: Context) throws -> Declaration {
        let (entity, context) = makeEntity(name: name, type: .oneOf, info: info, context: context)

        entity.properties = try makeProperties(for: schemas, context: context).map {
            // TODO: Generalize this and add better naming for nested types.
            // E.g. enum of strings should become "StringValue", not "Object"
            var property = $0
            if property.name.rawValue == "isBool" {
                property.name = PropertyName("bool")
            }
            return property
        }.removingDuplicates { $0.type }
        
        entity.protocols = {
            var protocols = getProtocols(for: entity, context: context)
            let hashable = Set(["String", "Bool", "URL", "Int", "Double"]) // TODO: Add support for more types
            let isHashable = entity.properties.allSatisfy { hashable.contains($0.type.builtinTypeName ?? "") }
            if isHashable { protocols.insert("Hashable") }
            return protocols
        }()
        
        entity.discriminator = try makeDiscriminator(info: info, context: context)

        // Covers a weird case encountered in open-banking.yaml spec (xml-sct schema)
        // TODO: We can potentially inline this instead of creating a typealias
        if entity.properties.count == 1, entity.properties[0].nested == nil {
            return TypealiasDeclaration(name: name, type: entity.properties[0].type, nested: entity.properties[0].nested)
        }

        return entity
    }
    
    private func makeAnyOf(name: TypeName, schemas: [JSONSchema], info: JSONSchemaContext, context: Context) throws -> Declaration {
        guard !context.isInlinableTypeCheck else { return AnyDeclaration.empty }
        
        let (entity, context) = makeEntity(name: name, type: .anyOf, info: info, context: context)
        
        var properties = try makeProperties(for: schemas, context: context)
        // `anyOf` where one type is off just means optional response
        if let index = properties.firstIndex(where: { $0.type.isVoid }) {
            properties.remove(at: index)
        }
        entity.properties = properties
        entity.protocols = getProtocols(for: entity, context: context)
        return entity
    }
    
    private func makeAllOf(name: TypeName, schemas: [JSONSchema], info: JSONSchemaContext, context: Context) throws -> Declaration {
        let (entity, context) = makeEntity(name: name, type: .allOf, info: info, context: context)

        let types = makeTypeNames(for: schemas, context: context)
        let properties: [Property] = try zip(types, schemas).flatMap { type, schema -> [Property] in
            switch schema.value {
            case .object(_, let details):
                // Inline properties for nested objects (different from other OpenAPI constructs)
                return try makeInlineProperties(for: name, object: details, context: context)
            case .reference(let info,_ ):
                if options.entities.isInliningPropertiesFromReferencedSchemas,
                   let schema = getSchema(for: info),
                   case .object(_, let details) = schema.value {
                    return try makeInlineProperties(for: name, object: details, context: context)
                } else {
                    return [try makeProperty(key: type, schema: schema, isRequired: true, in: context)]
                }
            default:
                return [try makeProperty(key: type, schema: schema, isRequired: true, in: context, isInlined: true)]
            }
        }.removingDuplicates(by: \.name)
        
        // TODO: Improve this and adopt for other types (see Zoom spec)
        if properties.count == 1 {
            var property = properties[0]
            if let nested = property.nested as? EntityDeclaration, nested.name.rawValue == "Object" {
                nested.name = name
                property.nested = nested
                property.type = .userDefined(name: name)
            }
            return TypealiasDeclaration(name: name, type: property.type, nested: property.nested)
        }
        
        guard !context.isInlinableTypeCheck else { return AnyDeclaration.empty }
        
        entity.properties = properties
        entity.protocols = getProtocols(for: entity, context: context)
        return entity
    }
    
    private func makeProperties(for schemas: [JSONSchema], context: Context) throws -> [Property] {
        try zip(makeTypeNames(for: schemas, context: context), schemas).map { type, schema in
            try makeProperty(key: type, schema: schema, isRequired: false, in: context)
        }
    }
    
    // TODO: Refactor, this is a mess
    /// Generate type names for anonyous objects that are sometimes needed for `oneOf` or `anyOf`
    /// constructs.
    private func makeTypeNames(for schemas: [JSONSchema], context: Context) -> [String] {
        var types = Array<TypeName?>(repeating: nil, count: schemas.count)
        
        // Assign known types (references, primitive)
        for (index, schema) in schemas.enumerated() {
            types[index] = (try? getTypeIdentifier(for: TypeName("placeholder"), schema: schema, context: context))?.name
        }
        
        // Generate names for anonymous nested objects
        let unnamedCount = types.filter { $0 == nil }.count
        if unnamedCount == types.count && types.count > 1 {
            var next = "a"
            func makeNextGenericName() -> TypeName {
                defer { next = next.nextLetter ?? "a" }
                return TypeName(next)
            }
            for (index, _) in schemas.enumerated() {
                if types[index] == nil {
                    types[index] = makeNextGenericName()
                }
            }
        } else {
            var genericCount = 1
            func makeNextGenericName() -> TypeName {
                defer { genericCount += 1 }
                return TypeName("Object\((unnamedCount == 1 && genericCount == 1) ? "" : "\(genericCount)")")
            }
            for (index, _) in schemas.enumerated() {
                if types[index] == nil {
                    types[index] = makeNextGenericName()
                }
            }
        }
        
        // Disambiguate arrays
        func parameter(for type: String) -> String {
            let name: String
            if type == "[String: AnyJSON]" {
                name = "object"
            } else {
                name = makePropertyName(type.components(separatedBy: ".").last ?? "").rawValue
            }
            guard options.isPluralizationEnabled else { return name }
            let isArray = type.starts(with: "[") && !type.contains( ":") // TODO: Refactor
            return isArray ? name.pluralized() : name
        }
        
        // TODO: Find a better way to dismabiguate this (test it on Soundcloud spec)
        return types.map { parameter(for: $0!.description) }.disambiguateDuplicateNames()
    }

    // MARK: - Typealiases
    
    private func makeTypealiasArray(name: TypeName, info: JSONSchema.CoreContext<JSONTypeFormat.ArrayFormat>, details: JSONSchema.ArrayContext, context: Context) throws -> Declaration {
        guard let item = details.items else {
            throw GeneratorError("Missing array item type")
        }
        let itemName = TypeIdentifier.userDefined(name: makeNestedElementTypeName(for: name.rawValue, context: context))
        let decl = try _makeDeclaration(name: itemName.name, schema: item, context: context)
        switch decl {
        case let decl as TypealiasDeclaration:
            return TypealiasDeclaration(name: name, type: decl.type.asArray(), nested: decl.nested)
        default:
            return TypealiasDeclaration(name: name, type: itemName.asArray(), nested: decl)
        }
    }
    
    // MARK: - Enums
    
    func makeStringEnum(name: TypeName, info: JSONSchemaContext) throws -> Declaration {
        let values = (info.allowedValues ?? []).map(\.value).compactMap { $0 as? String }
        guard !values.isEmpty else {
            throw GeneratorError("Enum \"\(name)\" has no values")
        }

        let caseNames: [PropertyName] = values.map {
            if !options.rename.enumCases.isEmpty {
                if let name = options.rename.enumCases["\(name.rawValue).\($0)"] {
                    return makePropertyName(name)
                }
                if let name = options.rename.enumCases[$0] {
                    return makePropertyName(name)
                }
            }
            let name = sanitizeEnumCaseName($0)
                .trimmingCharacters(in: .whitespaces)
            // TODO: Is this expected behavior? Or does it mean "nullable"?
            return name.isEmpty ? PropertyName("empty") : makePropertyName(name)
        }
        var deduplicator = NameDeduplicator()
        let cases: [EnumOfStringsDeclaration.Case] = zip(values, caseNames).map { value, name in
            let caseName = deduplicator.add(name: name.rawValue)
            return EnumOfStringsDeclaration.Case(name: caseName, key: value)
        }
        return EnumOfStringsDeclaration(name: name, cases: cases, metadata: .init(info))
    }
        
    private func isEnum(_ info: JSONSchemaContext) -> Bool {
        options.isGeneratingEnums && info.allowedValues != nil
    }
    
    // MARK: - Property
    
    func makeProperty(key: String, schema: JSONSchema, isRequired: Bool, in context: Context, isInlined: Bool? = nil) throws -> Property {
        let propertyName: PropertyName

        /**
        Strips the parent name of enum cases within objects that are `oneOf` / `allOf` / `anyOf` of 
        nested references.

        Given:

        ```
        Parent
        ├── ParentA
        └── ParentB
        ```

        Disabled:

        ```swift
        public enum Parent: Codable {
            case parentA(ParentA)
            case parentB(ParentB)
        }
        ``` 

        Enabled:

        ```swift
        public enum Parent: Codable {
            case a(ParentA)
            case b(ParentB)
        }
        ``` 

        */
        if options.entities.isStrippingParentNameInNestedObjects,
            case .reference(let ref, _) = schema.value, 
            let parentName = context.parents.first?.name.rawValue,
            let ownName = ref.name {

            let prefix = ownName.commonPrefix(with: parentName)

            propertyName = makePropertyName(String(ownName.dropFirst(prefix.count)))
        } else {
            propertyName = makePropertyName(key)
        }
        
        func makeName(for name: PropertyName, type: TypeIdentifier? = nil) -> PropertyName {
            if !options.rename.properties.isEmpty {
                let names = context.parents.map { $0.name.rawValue } + [name.rawValue]
                for i in names.indices {
                    if let name = options.rename.properties[names[i...].joined(separator: ".")] {
                        return PropertyName(name)
                    }
                }
            }
            if let type = type, options.isGeneratingSwiftyBooleanPropertyNames && type.isBool {
                return name.asBoolean(options)
            }
            return name
        }
        
        func property(type: TypeIdentifier, info: JSONSchemaContext?, nested: Declaration? = nil) -> Property {
            let nullable = info?.nullable ?? false
            let name = makeName(for: propertyName, type: type)
            let isOptional = !isRequired || nullable
            var type = type
            if context.isPatch && isOptional && options.paths.isMakingOptionalPatchParametersDoubleOptional {
                type = type.asPatchParameter()
            }
            var defaultValue: String?
            if options.entities.isAddingDefaultValues {
                if type.isBool {
                    defaultValue = (info?.defaultValue?.value as? Bool).map { $0 ? "true" : "false" }
                }
            }
            return Property(name: name, type: type, isOptional: isOptional, key: key, defaultValue: defaultValue, metadata: .init(info), nested: nested, isInlined: isInlined)
        }

        // TOOD: This can be done faster for primitive types (no makeTypeName)
        func makeSimpleProperty() throws -> Property {
            let decl = try _makeDeclaration(name: makeTypeName(key), schema: schema, context: context)
            switch decl {
            case let alias as TypealiasDeclaration:
                return property(type: alias.type, info: schema.coreContext, nested: alias.nested)
            default:
                return property(type: .userDefined(name: decl.name), info: schema.coreContext, nested: decl)
            }
        }
        
        func makeReference(reference: JSONReference<JSONSchema>, details: JSONSchema.ReferenceContext) throws -> Property {
            // TODO: Refactor (changed it to `null` to avoid issue with cycles)
            // Maybe remove dereferencing entirely?
            let info = getSchema(for: reference)?.coreContext
            let type = try getTypeIdentifier(for: makeTypeName(key), schema: schema, context: context) ?? .userDefined(name: TypeName(reference.name ?? ""))
            return property(type: type, info: info, nested: nil)
        }
        
        switch schema.value {
        case .reference(let ref, let details): return try makeReference(reference: ref, details: details)
        default: return try makeSimpleProperty()
        }
    }
    
    private func getSchema(for reference: JSONReference<JSONSchema>) -> JSONSchema? {
        guard let key = OpenAPI.ComponentKey(rawValue: reference.name ?? "") else {
            return nil
        }
        // We don't need to dereference the whole thing (including all properties).
        return spec.components.schemas[key]
    }
}
