// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Add Read-Only and Write-Only Properties support
// TODO: stirng with format "binary"?
// TODO: Add an option to add to namespace to all generated entities
// TODO: Add an option to convert optional arrays to empty arrays
// TODO: Add support for more default values, strings, arrays?
// TODO: `Rename.entities` to support nested types
// TODO: Add `Rename.enums`
// TODO: Add an option to hide `anyJSON`
// TODO: Generate IDs with phantom types
// TODO: Add `byte` and `binary` string formats support
// TODO: Add an option to generate CodingKeys instead of using Strings
// TODO: Clarify intentions behind `properties` mixed with `anyOf` https://github.com/github/rest-api-description/discussions/805
// TODO: Improve `anyOf` support
// TODO: `entitiesGeneratedAsClasses` - add support for nesting
// TODO: `makeAllOf` to support custom coding keys
// TODO: Remove StringCodingKeys when they are not needed
// TODO: Support comments in typealiases

extension Generator {
    func schemas() throws -> GeneratorOutput {
        let benchmark = Benchmark(name: "Generating entities")
        defer { benchmark.stop() }
        return try _schemas()
    }
    
    private func _schemas() throws -> GeneratorOutput {
        let schemas = Array(spec.components.schemas)
        var generated = Array<Result<GeneratedFile, Error>?>(repeating: nil, count: schemas.count)
        let context = Context(parents: [])
        let lock = NSLock()
        concurrentPerform(on: schemas, parallel: arguments.isParallel) { index, item in
            let (key, schema) = schemas[index]
            
            guard let name = makeTypeNameFor(key: key), !options.entities.skip.contains(name.rawValue) else {
                if arguments.isVerbose {
                    print("Skipping generation for \(key.rawValue)")
                }
                return
            }
                        
            do {
                if let entry = try makeDeclaration(name: name, schema: schema, context: context) {
                    let file = GeneratedFile(name: name.rawValue, contents: render(entry))
                    lock.sync { generated[index] = .success(file) }
                }
            } catch {
                if arguments.isStrict {
                    lock.sync { generated[index] = .failure(error) }
                } else {
                    print("ERROR: Failed to generate entity for \(key.rawValue): \(error)")
                }
            }
        }
            
        return GeneratorOutput(
            header: fileHeader,
            files: try generated.compactMap { $0 }.map { try $0.get() },
            extensions: makeExtensions()
        )
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
    private func makeTypeNameFor(key: OpenAPI.ComponentKey) -> TypeName? {
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
                    return makeTypeName(counterpart)
                }
            }
        }
        if !options.rename.entities.isEmpty {
            let name = makeTypeName(key.rawValue)
            if let mapped = options.rename.entities[name.rawValue] {
                return TypeName(mapped)
            }
        }
        return makeTypeName(key.rawValue)
    }

    // MARK: - Declaration
    
    /// Recursively a type declaration: struct, class, enum, typealias, etc.
    func makeDeclaration(name: TypeName, schema: JSONSchema, context: Context) throws -> Declaration? {
        switch schema {
        case .boolean, .number, .integer:
            return nil // Always inline
        case .string(let info, _):
            guard isEnum(info) else { return nil } // Always inline
            return try makeStringEnum(name: name, info: info)
        case .object(let info, let details):
            if let type = try getPrimitiveType(for: JSONSchema.object(info, details), context: context), !type.isVoid {
                guard !options.isInliningPrimitiveTypes else { return nil }
                return nil
            }
            return try makeObject(name: name, info: info, details: details, context: context)
        case .array(let info, let details):
            return try makeTypealiasArray(name: name, info: info, details: details, context: context)
        case .all(let schemas, _):
            return try makeAllOf(name: name, schemas: schemas, context: context)
        case .one(let schemas, _):
            return try makeOneOf(name: name, schemas: schemas, context: context)
        case .any(let schemas, _):
            return try makeAnyOf(name: name, schemas: schemas, context: context)
        case .not:
            throw GeneratorError("`not` is not supported: \(name)")
        case .reference(let info, _):
            guard let ref = info.name, !ref.isEmpty else {
                throw GeneratorError("Reference name is missing")
            }
            return AnyDeclaration(name: name, contents: templates.typealias(name: name, type: makeTypeName(ref)))
        case .fragment:
            guard !options.isInliningPrimitiveTypes else { return nil }
            setNeedsAnyJson()
            return AnyDeclaration(name: name, contents: templates.typealias(name: name, type: TypeName("AnyJSON")))
        }
    }
    
    // MARK: - Property
    
    func makeProperty(key: String, schema: JSONSchema, isRequired: Bool, in context: Context) throws -> Property {
        let propertyName = makePropertyName(key)
        
        func makeChildPropertyName(for name: PropertyName, type: MyType? = nil) -> PropertyName {
            if !options.rename.properties.isEmpty {
                let names = context.parents.map { $0.rawValue } + [name.rawValue]
                for i in names.indices {
                    if let name = options.rename.properties[names[i...].joined(separator: ".")] {
                        return PropertyName(name)
                    }
                }
            }
            if let type = type, options.isGeneratingSwiftyBooleanPropertyNames && type.isBool {
                return name.asBoolean
            }
            return name
        }
        
        func property(name: PropertyName, type: MyType, info: JSONSchemaContext?, nested: Declaration? = nil) -> Property {
            let nullable = info?.nullable ?? false
            let name = makeChildPropertyName(for: name, type: type)
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
            return Property(name: name, type: type, isOptional: isOptional, key: key, defaultValue: defaultValue, metadata: .init(info), nested: nested)
        }
                
        func makeObject(info: JSONSchemaContext, details: JSONSchema.ObjectContext) throws -> Property {
            if let dictionary = try makeDictionary(key: key, info: info, details: details, context: context) {
                return property(name: propertyName, type: dictionary.type, info: dictionary.info, nested: dictionary.nested)
            }
            let type = makeTypeName(key)
            let nested = try makeDeclaration(name: type, schema: schema, context: context)
            return property(name: propertyName, type: .userDefined(name: type), info: info, nested: nested)
        }
        
        func makeArray(info: JSONSchemaContext, details: JSONSchema.ArrayContext) throws -> Property {
            guard let item = details.items else {
                throw GeneratorError("Missing array item type")
            }
            if let type = try getPrimitiveType(for: item, context: context) {
                return property(name: propertyName, type: type.asArray(), info: info)
            }
            let name = makeNestedArrayTypeName(for: key)
            let nested = try makeDeclaration(name: name, schema: item, context: context)
            return property(name: propertyName, type: .userDefined(name: name).asArray(), info: info, nested: nested)
        }
        
        func makeString(info: JSONSchemaContext) throws -> Property {
            if isEnum(info) {
                let typeName = makeTypeName(makeChildPropertyName(for: propertyName, type: nil).rawValue)
                let nested = try makeStringEnum(name: typeName, info: info)
                return property(name: propertyName, type: .userDefined(name: typeName), info: schema.coreContext, nested: nested)
            }
            guard let type = try getPrimitiveType(for: schema, context: context) else {
                throw GeneratorError("Failed to generate primitive type for: \(key)")
            }
            return property(name: propertyName, type: type, info: info)
        }
        
        func makeSomeOf() throws -> Property {
            let name = makeTypeName(key)
            let nested = try makeDeclaration(name: name, schema: schema, context: context)
            return property(name: propertyName, type: .userDefined(name: name), info: schema.coreContext, nested: nested)
        }
        
        func makeReference(reference: JSONReference<JSONSchema>, details: JSONSchema.ReferenceContext) throws -> Property {
            // TODO: Refactor (changed it to `null` to avoid issue with cycles)
            // Maybe remove dereferencing entirely?
            let info = (try? reference.dereferenced(in: spec.components))?.coreContext
            guard let type = try getPrimitiveType(for: schema, context: context) else {
                throw GeneratorError("Failed to generate primitive type for: \(key)")
            }
            return property(name: propertyName, type: type, info: info)
        }
        
        func makeProperty(schema: JSONSchema) throws -> Property {
            let info = schema.coreContext
            guard let type = try getPrimitiveType(for: schema, context: context) else {
                throw GeneratorError("Failed to generate primitive type for: \(key)")
            }
            return property(name: propertyName, type: type, info: info)
        }

        switch schema {
        case .object(let info, let details):
            // Try go generate primitive type first
            if let property = try? makeProperty(schema: schema) {
                return property
            }
            return try makeObject(info: info, details: details)
        case .array(let info, let details): return try makeArray(info: info, details: details)
        case .string(let info, _): return try makeString(info: info)
        case .all, .one, .any: return try makeSomeOf()
        case .reference(let ref, let details): return try makeReference(reference: ref, details: details)
        case .not: throw GeneratorError("`not` properties are not supported")
        default: return try makeProperty(schema: schema)
        }
    }
    
    // MARK: - Dictionary
    
    private struct AdditionalProperties {
        let type: MyType
        let info: JSONSchemaContext
        var nested: Declaration?
    }
    
    // Creates a dictionary, e.g. `[String: AnyJSON]`, `[String: [String: String]]`,
    // `[String: CustomNestedType]`. Returns `Void` if no properties are allowed.
    private func makeDictionary(key: String, info: JSONSchemaContext, details: JSONSchema.ObjectContext, context: Context) throws -> AdditionalProperties? {
        var additional = details.additionalProperties
        if details.properties.isEmpty, options.isInterpretingEmptyObjectsAsDictionaries {
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
            return AdditionalProperties(type: .dictionary(value: .anyJSON), info: info)
        case .b(let schema):
            if let type = try getPrimitiveType(for: schema, context: context) {
                return AdditionalProperties(type: .dictionary(value: type), info: info)
            }
            let nestedTypeName = makeNestedArrayTypeName(for: key)
            let nested = try makeDeclaration(name: nestedTypeName, schema: schema, context: context)
            return AdditionalProperties(type: .dictionary(value: .userDefined(name: nestedTypeName)), info: info, nested: nested)
        }
    }
    
    // MARK: - Object
    
    private func makeObject(name: TypeName, info: JSONSchema.CoreContext<JSONTypeFormat.ObjectFormat>, details: JSONSchema.ObjectContext, context: Context) throws -> Declaration? {
        let context = context.adding(name)
        let properties = try makeProperties(for: name, object: details, context: context)
            .removingDuplicates(by: \.name)
        let protocols = getProtocols(for: name, context: context)
        return EntityDeclaration(name: name, properties: properties, protocols: protocols, metadata: .init(info), isForm: context.isFormEncoding)
    }
    
    private func getProtocols(for type: TypeName, context: Context) -> Protocols {
        var protocols = Protocols(options.entities.adoptedProtocols)
        let isDecodable = protocols.isDecodable && (context.isDecodableNeeded || !options.entities.isSkippingRedundantProtocols)
        let isEncodable = protocols.isEncodable && (context.isEncodableNeeded || !options.entities.isSkippingRedundantProtocols)
        if !isDecodable { protocols.removeDecodable() }
        if !isEncodable { protocols.removeEncodable() }
        return protocols
    }
    
    private func makeProperties(for type: TypeName, object: JSONSchema.ObjectContext, context: Context) throws -> [Property] {
        var keys = object.properties.keys
        if options.entities.isSortingPropertiesAlphabetically { keys.sort() }
        return try keys.compactMap { key in
            let schema = object.properties[key]!
            let isRequired = object.requiredProperties.contains(key)
            do {
                return try makeProperty(key: key, schema: schema, isRequired: isRequired, in: context)
            } catch {
                if arguments.isStrict {
                    throw error
                } else {
                    print("ERROR: Failed to generate property \"\(key)\" in \"\(type)\". Error: \(error).")
                    return nil
                }
            }
        }
    }
    
    private func makeNestedArrayTypeName(for key: String) -> TypeName {
        let name = makeTypeName(key)
        if options.isPluralizationEnabled, !options.pluralizationExceptions.contains(name.rawValue) {
            // Some know words that the library doesn't handle well
            if name.rawValue == "Environments" { return TypeName("Environment") }
            let words = name.rawValue.trimmingCharacters(in: CharacterSet.ticks).words
            if words.last?.singularized() != words.last {
                let sing = (words.dropLast() + [words.last?.singularized()])
                    .compactMap { $0?.capitalizingFirstLetter() }
                    .joined(separator: "")
                return makeTypeName(sing) // TODO: refactor
            }
        }
        return name.appending("Item")
    }
    
    // MARK: - Typealiases
    
    private func makeTypealiasArray(name: TypeName, info: JSONSchema.CoreContext<JSONTypeFormat.ArrayFormat>, details: JSONSchema.ArrayContext, context: Context) throws -> Declaration? {
        guard let item = details.items else {
            throw GeneratorError("Missing array item type")
        }
        if let type = try getPrimitiveType(for: item, context: context) {
            guard !options.isInliningPrimitiveTypes else {
                return nil
            }
            let type = type.asArray().name
            return AnyDeclaration(name: type, contents: templates.typealias(name: name, type: type))
        }
        // Requres generation of a separate type
        var output = ""
        let itemName = name.appending("Item")
        output += templates.typealias(name: name, type: itemName.asArray)
        output += "\n\n"
        output += (try makeDeclaration(name: itemName, schema: item, context: context)).map(render) ?? ""
        return AnyDeclaration(name: name, contents: output)
    }
    
    // MARK: - Enums
    
    func makeStringEnum(name: TypeName, info: JSONSchemaContext) throws -> Declaration {
        func getValue(_ value: Any) -> String? {
            if let string = value as? String {
                return string
            }
            if let bool = value as? Bool {
                return bool ? "true" : "false"
            }
            return nil
        }
        
        let values = (info.allowedValues ?? []).map(\.value).compactMap(getValue)
        guard !values.isEmpty else {
            throw GeneratorError("Enum \"\(name)\" has no values")
        }

        let caseNames: [PropertyName] = values.map {
            if !options.rename.enumCaseNames.isEmpty {
                if let name = options.rename.enumCaseNames["\(name.rawValue).\($0)"] {
                    return makePropertyName(name)
                }
                if let name = options.rename.enumCaseNames[$0] {
                    return makePropertyName(name)
                }
            }
            return makePropertyName($0)
        }
        let hasDuplicates = values.count != Set(caseNames.map(\.rawValue)).count
        let cases: [EnumOfStringsDeclaration.Case] = zip(values, caseNames).map { value, name in
            // TODO: This handles somescenarios but not all,
            // e.g "reaction+1", "reaction-1" will fail to compile. You can
            // use `rename.enumCaseNames` to fix these scenarios.
            let caseName = hasDuplicates ? value : name.rawValue
            return EnumOfStringsDeclaration.Case(name: caseName, key: value)
        }
        return EnumOfStringsDeclaration(name: name, cases: cases, metadata: .init(info))
    }
    
    private func isInlinable(_ schema: JSONSchema, context: Context) -> Bool {
        switch schema {
        case .boolean: return true
        case .number: return true
        case .integer: return true
        case .string(let info, _):
            return !isEnum(info)
        case .object: return true
        case .array(_, let details):
            if let item = details.items {
                return (try? getPrimitiveType(for: item, context: context)) != nil
            }
            return false
        case .all: return false
        case .one: return false
        case .any: return false
        case .not: return false
        case .reference: return false
        case .fragment: return true
        }
    }
    
    private func isEnum(_ info: JSONSchemaContext) -> Bool {
        options.isGeneratingEnums && info.allowedValues != nil
    }
    
    // MARK: - Misc
    
    // Anything that's not an object or a reference.
    func getPrimitiveType(for json: JSONSchema, context: Context) throws -> MyType? {
        switch json {
        case .boolean: return .builtin("Bool")
        case .number: return .builtin("Double")
        case .integer(let info, _):
            guard options.isUsingIntegersWithPredefinedCapacity else {
                return .builtin("Int")
            }
            switch info.format {
            case .generic, .other: return .builtin("Int")
            case .int32: return .builtin("Int32")
            case .int64: return .builtin("Int64")
            }
        case .string(let info, _):
            guard !isEnum(info) else { return nil }
            switch info.format {
            case .dateTime: return .builtin("Date")
            case .date: if options.isNaiveDateEnabled {
                setNaiveDateNeeded()
                return .builtin("NaiveDate")
            }
            case .other(let other): if other == "uri" { return .builtin("URL") }
            default: break
            }
            return .builtin("String")
        case .object(let info, let details):
            if let dictionary = try makeDictionary(key: "placeholder", info: info, details: details, context: context), dictionary.nested == nil {
                return dictionary.type
            }
            return nil
        case .array(_, let details):
            guard let items = details.items else {
                throw GeneratorError("Missing array item type")
            }
            return try getPrimitiveType(for: items, context: context)?.asArray()
        case .all, .one, .any, .not:
            return nil
        case .reference(let reference, _):
            return try getReferenceType(reference, context: context)
        case .fragment:
            setNeedsAnyJson()
            return .anyJSON
        }
    }
    
    private func getReferenceType(_ reference: JSONReference<JSONSchema>, context: Context) throws -> MyType {
        switch reference {
        case .internal(let ref):
            if arguments.vendor == "github", let name = ref.name, name.hasPrefix("nullable-") {
                let replacement = makeTypeName(name.replacingOccurrences(of: "nullable-", with: ""))
                return .userDefined(name: replacement.namespace(context.namespace))
            }
            // Note: while dereferencing, it does it recursively.
            // So if you have `typealias Pets = [Pet]`, it'll dereference
            // `Pet` to an `.object`, not a `.reference`.
            if options.isInliningPrimitiveTypes,
               let key = OpenAPI.ComponentKey(rawValue: ref.name ?? ""),
               let schema = spec.components.schemas[key],
               let inlined = try getPrimitiveType(for: schema, context: context),
               isInlinable(schema, context: context) {
                return inlined // Inline simple types
            }
            guard let name = ref.name else {
                throw GeneratorError("Internal reference name is missing: \(ref)")
            }
            // TODO: Remove duplication
            if !options.rename.entities.isEmpty {
                if let mapped = options.rename.entities[name] {
                    return .userDefined(name: TypeName(mapped.namespace(context.namespace)))
                }
            }
            return .userDefined(name: makeTypeName(name).namespace(context.namespace))
        case .external(let url):
            throw GeneratorError("External references are not supported: \(url)")
        }
    }
    
    // MARK: - oneOf/anyOf/allOf
    
    private func makeOneOf(name: TypeName, schemas: [JSONSchema], context: Context) throws -> Declaration {
        let context = context.adding(name)
        let properties: [Property] = try makeProperties(for: schemas, context: context).map {
            // TODO: Generalize this and add better naming for nested types.
            // E.g. enum of strings should become "StringValue", not "Object"
            var property = $0
            if property.name.rawValue == "isBool" {
                property.name = PropertyName("bool")
            }
            return property
        }.removingDuplicates { $0.type }
        
        // Covers a weird case encountered in open-banking.yaml spec (xml-sct schema)
        // TODO: We can potentially inline this instead of creating a typealias
        if properties.count == 1, properties[0].nested == nil {
            return AnyDeclaration(name: name, contents: templates.typealias(name: name, type: properties[0].type.name))
        }
    
        var protocols = getProtocols(for: name, context: context)
        let hashable = Set(["String", "Bool", "URL", "Int", "Double"]) // TODO: Add support for more types
        let isHashable = properties.allSatisfy { hashable.contains($0.type.builtinTypeName ?? "") }
        if isHashable { protocols.insert("Hashable") }
        
        var contents: [String] = []
        // TODO: Add comments for cases
        contents.append(properties.map(templates.case).joined(separator: "\n"))
        contents += properties.compactMap { $0.nested }.map(render)
        if protocols.isDecodable {
            contents.append(templates.initFromDecoderOneOf(properties: properties))
        }
        if protocols.isEncodable {
            contents.append(templates.encodeOneOf(properties: properties))
        }
        let output = templates.enumOneOf(name: name, contents: contents, protocols: protocols)
        return AnyDeclaration(name: name, contents: output)
    }
    
    private func makeAnyOf(name: TypeName, schemas: [JSONSchema], context: Context) throws -> Declaration {
        let context = context.adding(name)
        var properties = try makeProperties(for: schemas, context: context)
        var contents: [String] = []
        // `anyOf` where one type is off just means optional response
        if let index = properties.firstIndex(where: { $0.type.isVoid }) {
            properties.remove(at: index)
        }
        contents.append(templates.properties(properties))
        contents += properties.compactMap { $0.nested }.map(render)
        let protocols = getProtocols(for: name, context: context)
        if protocols.isDecodable {
            contents.append(templates.initFromDecoderAnyOf(properties: properties))
        }
        if protocols.isEncodable {
            contents.append(templates.encodeAnyOf(properties: properties))
        }
        let output = templates.entity(name: name, contents: contents, protocols: protocols)
        return AnyDeclaration(name: name, contents: output)
    }
    
    private func makeAllOf(name: TypeName, schemas: [JSONSchema], context: Context) throws -> Declaration {
        let types = makeTypeNames(for: schemas, context: context)
        let context = context.adding(name)
        let properties: [Property] = try zip(types, schemas).flatMap { type, schema -> [Property] in
            switch schema {
            case .object(_, let details):
                // Inline properties for nested objects (differnt from other OpenAPI constructs)
                return try makeProperties(for: name, object: details, context: context)
            default:
                return [try makeProperty(key: type, schema: schema, isRequired: true, in: context)]
            }
        }
        var contents: [String] = []
        contents.append(templates.properties(properties))
        contents += properties.compactMap { $0.nested }.map(render)
        var needsValues = false
        let decoderContents = properties.map {
            if case .userDefined = $0.type {
                return templates.decodeFromDecoder(property: $0)
            } else {
                needsValues = true
                return templates.decode(property: $0, isUsingCodingKeys: false)
            }
        }.joined(separator: "\n")
        let protocols = getProtocols(for: name, context: context)
        if protocols.isDecodable {
            contents.append(templates.initFromDecoder(contents: decoderContents, needsValues: needsValues, isUsingCodingKeys: false))
        }
        if protocols.isEncodable {
            contents.append(templates.encode(properties: properties))
        }
        let output = templates.entity(name: name, contents: contents, protocols: protocols)
        return AnyDeclaration(name: name, contents: output)
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
        var types = Array<MyType?>(repeating: nil, count: schemas.count)
        
        // Assign known types (references, primitive)
        for (index, schema) in schemas.enumerated() {
            types[index] = try? getPrimitiveType(for: schema, context: context)
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
                    types[index] = .userDefined(name: makeNextGenericName())
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
                    types[index] = .userDefined(name: makeNextGenericName())
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
}
