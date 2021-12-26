// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber
import AppKit

// TODO: Pass info to oneOf, anyOf
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
    
    func makeDeclaration(name: TypeName, schema: JSONSchema, context: Context) throws -> Declaration? {
        guard let declaration = try _makeDeclaration(name: name, schema: schema, context: context) else {
            return nil
        }
        #warning("TODO: inline if nested isnt nil too?")
        if options.isInliningTypealiases, let alias = declaration as? TypealiasDeclaration, alias.nested == nil {
            return nil
        }
        return declaration
    }
    
    /// Recursively a type declaration: struct, class, enum, typealias, etc.
    func _makeDeclaration(name: TypeName, schema: JSONSchema, context: Context) throws -> Declaration? {
        let context = context.adding(name)
        switch schema.value {
        case .boolean, .number, .integer:
            return nil // Always inline
        case .string(let info, _):
            guard isEnum(info) else { return nil } // Always inline
            return try makeStringEnum(name: name, info: info)
        case .object(let info, let details):
            return try makeObject(name: name, info: info, details: details, context: context)
        case .array(let info, let details):
            return try makeTypealiasArray(name: name, info: info, details: details, context: context)
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
            return TypealiasDeclaration(name: name, type: .userDefined(name: makeTypeName(ref)))
        case .fragment:
            setNeedsAnyJson()
            return TypealiasDeclaration(name: name, type: .anyJSON)
        }
    }
    
    // MARK: - Property
    
    func makeProperty(key: String, schema: JSONSchema, isRequired: Bool, in context: Context) throws -> Property {
        let propertyName = makePropertyName(key)
        
        func makeName(for name: PropertyName, type: MyType? = nil) -> PropertyName {
            if !options.rename.properties.isEmpty {
                let names = context.parents.map { $0.rawValue } + [name.rawValue]
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
        
        func property(type: MyType, info: JSONSchemaContext?, nested: Declaration? = nil) -> Property {
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
            return Property(name: name, type: type, isOptional: isOptional, key: key, defaultValue: defaultValue, metadata: .init(info), nested: nested)
        }
                
        // TODO: Reuse 
        
        func makeObject(info: JSONSchemaContext, details: JSONSchema.ObjectContext) throws -> Property {
            // TODO: This should be done using the same apporach as makeSomeOf
            if let dictionary = try makeDictionary(key: key, info: info, details: details, context: context) {
                return property(type: dictionary.type, info: dictionary.info, nested: dictionary.nested)
            }
            let type = makeTypeName(key)
            let nested = try makeDeclaration(name: type, schema: schema, context: context)
            return property(type: .userDefined(name: type), info: info, nested: nested)
        }
        
        func makeArray(info: JSONSchemaContext, details: JSONSchema.ArrayContext) throws -> Property {
            guard let item = details.items else {
                throw GeneratorError("Missing array item type")
            }
            if let type = try getPrimitiveType(for: item, context: context) {
                return property(type: type.asArray(), info: info)
            }
            let name = makeNestedArrayTypeName(for: key)
            let nested = try makeDeclaration(name: name, schema: item, context: context)
            return property(type: .userDefined(name: name).asArray(), info: info, nested: nested)
        }
        
        func makeString(info: JSONSchemaContext) throws -> Property {
            if isEnum(info) {
                let typeName = makeTypeName(makeName(for: propertyName, type: nil).rawValue)
                let nested = try makeStringEnum(name: typeName, info: info)
                return property(type: .userDefined(name: typeName), info: schema.coreContext, nested: nested)
            }
            guard let type = try getPrimitiveType(for: schema, context: context) else {
                throw GeneratorError("Failed to generate primitive type for: \(key)")
            }
            return property(type: type, info: info)
        }

        func makeSomeOf() throws -> Property {
            if let type = try getPrimitiveType(for: schema, context: context) {
                return property(type: type, info: schema.coreContext)
            }
            let name = makeTypeName(key)
            let nested = try makeDeclaration(name: name, schema: schema, context: context)
            return property(type: .userDefined(name: name), info: schema.coreContext, nested: nested)
        }
        
        func makeReference(reference: JSONReference<JSONSchema>, details: JSONSchema.ReferenceContext) throws -> Property {
            // TODO: Refactor (changed it to `null` to avoid issue with cycles)
            // Maybe remove dereferencing entirely?
            let info = (try? reference.dereferenced(in: spec.components))?.coreContext
            guard let type = try getPrimitiveType(for: schema, context: context) else {
                throw GeneratorError("Failed to generate primitive type for: \(key)")
            }
            return property(type: type, info: info)
        }
        
        func makeProperty(schema: JSONSchema) throws -> Property {
            let info = schema.coreContext
            guard let type = try getPrimitiveType(for: schema, context: context) else {
                throw GeneratorError("Failed to generate primitive type for: \(key)")
            }
            return property(type: type, info: info)
        }

        switch schema.value {
        case .object(let info, let details): return try makeObject(info: info, details: details)
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
        if let dictionary = try makeDictionary(key: name.rawValue, info: info, details: details, context: context) {
            return TypealiasDeclaration(name: name, type: dictionary.type, nested: dictionary.nested)
        }
        let properties = try makeProperties(for: name, object: details, context: context)
            .filter { !$0.type.isVoid }
            .removingDuplicates(by: \.name) // Sometimes Swifty bool names create dups
        let protocols = getProtocols(for: name, context: context)
        return EntityDeclaration(name: name, type: .object, properties: properties, protocols: protocols, metadata: .init(info), isForm: context.isFormEncoding)
    }
    
    private func getProtocols(for type: TypeName, context: Context) -> Protocols {
        var protocols = Protocols(options.entities.protocols)
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
            return makeTypeName(sing) // TODO: refactor
        }
        return name.appending("Item")
    }
    
    // MARK: - Typealiases
    
    private func makeTypealiasArray(name: TypeName, info: JSONSchema.CoreContext<JSONTypeFormat.ArrayFormat>, details: JSONSchema.ArrayContext, context: Context) throws -> Declaration? {
        guard let item = details.items else {
            throw GeneratorError("Missing array item type")
        }
        if let type = try getPrimitiveType(for: item, context: context) {
            return TypealiasDeclaration(name: name, type: type.asArray())
        }
        let itemName = MyType.userDefined(name: name.appending("Item"))
        let nested = try _makeDeclaration(name: itemName.name, schema: item, context: context)
        return TypealiasDeclaration(name: name, type: itemName.asArray(), nested: nested)
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
        let hasDuplicates = values.count != Set(caseNames.map(\.rawValue)).count
        let cases: [EnumOfStringsDeclaration.Case] = zip(values, caseNames).map { value, name in
            // TODO: This handles somescenarios but not all,
            // e.g "reaction+1", "reaction-1" will fail to compile. You can
            // use `rename.enumCases` to fix these scenarios.
            let caseName = hasDuplicates ? value : name.rawValue
            return EnumOfStringsDeclaration.Case(name: caseName, key: value)
        }
        return EnumOfStringsDeclaration(name: name, cases: cases, metadata: .init(info))
    }
        
    private func isEnum(_ info: JSONSchemaContext) -> Bool {
        options.isGeneratingEnums && info.allowedValues != nil
    }
    
    // MARK: - Misc
    
    // Returns a value if the schema produces a type identifier and doesn't
    // require a type declaration. It works not just with primitive types, like
    // Int, or String, but with much more complex constructs.
    func getPrimitiveType(for schema: JSONSchema, context: Context) throws -> MyType? {
        var context = context
        context.isInlinableTypeCheck = true
        switch schema.value {
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
            // TODO: Use _makeDeclaration
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
            if let alias = try _makeDeclaration(name: TypeName("placeholder"), schema: schema, context: context) as? TypealiasDeclaration, alias.nested == nil {
                return alias.type
            }
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
            if options.isInliningTypealiases, let name = ref.name {
                // If there is a cycle, it can't be a primitive value
                if context.parents.contains(makeTypeName(name)) {
                    return .userDefined(name: makeTypeName(name))
                }
                if let key = OpenAPI.ComponentKey(rawValue: name),
                   let schema = spec.components.schemas[key],
                   let inlined = try getPrimitiveType(for: schema, context: context) {
                    return inlined // Inline simple types
                }
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
    
    private func makeOneOf(name: TypeName, schemas: [JSONSchema], info: JSONSchemaContext, context: Context) throws -> Declaration? {
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
            return TypealiasDeclaration(name: name, type: properties[0].type)
        }
        
        guard !context.isInlinableTypeCheck else { return nil }
    
        var protocols = getProtocols(for: name, context: context)
        let hashable = Set(["String", "Bool", "URL", "Int", "Double"]) // TODO: Add support for more types
        let isHashable = properties.allSatisfy { hashable.contains($0.type.builtinTypeName ?? "") }
        if isHashable { protocols.insert("Hashable") }
        
        return EntityDeclaration(name: name, type: .oneOf, properties: properties, protocols: protocols, metadata: DeclarationMetadata(info), isForm: context.isFormEncoding)
    }
    
    private func makeAnyOf(name: TypeName, schemas: [JSONSchema], info: JSONSchemaContext, context: Context) throws -> Declaration? {
        guard !context.isInlinableTypeCheck else { return nil }
        var properties = try makeProperties(for: schemas, context: context)
        // `anyOf` where one type is off just means optional response
        if let index = properties.firstIndex(where: { $0.type.isVoid }) {
            properties.remove(at: index)
        }
        let protocols = getProtocols(for: name, context: context)
        return EntityDeclaration(name: name, type: .anyOf, properties: properties, protocols: protocols, metadata: DeclarationMetadata(info), isForm: context.isFormEncoding)
    }
    
    private func makeAllOf(name: TypeName, schemas: [JSONSchema], info: JSONSchemaContext, context: Context) throws -> Declaration? {
        let types = makeTypeNames(for: schemas, context: context)
        let properties: [Property] = try zip(types, schemas).flatMap { type, schema -> [Property] in
            switch schema.value {
            case .object(_, let details):
                // Inline properties for nested objects (different from other OpenAPI constructs)
                return try makeProperties(for: name, object: details, context: context)
            case .reference(let info,_ ):
                if options.entities.isInliningPropertiesFromReferencedSchemas,
                   let schema = try? info.dereferenced(in: spec.components),
                   case .object(_, let details) = schema.jsonSchema.value {
                    return try makeProperties(for: name, object: details, context: context)
                } else {
                    var context = context
                    if name.rawValue == info.name { // Gotta disambiguate
                        context.namespace = arguments.module.rawValue
                    }
                    return [try makeProperty(key: type, schema: schema, isRequired: true, in: context)]
                }
            default:
                return [try makeProperty(key: type, schema: schema, isRequired: true, in: context)]
            }
        }.removingDuplicates(by: \.name)
        
        // TODO: Figure out how to inline these
        if properties.count == 1 {
            return TypealiasDeclaration(name: name, type: properties[0].type)
        }
        
        guard !context.isInlinableTypeCheck else { return nil }

        let protocols = getProtocols(for: name, context: context)
        return EntityDeclaration(name: name, type: .allOf, properties: properties, protocols: protocols, metadata: DeclarationMetadata(info), isForm: context.isFormEncoding)
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
