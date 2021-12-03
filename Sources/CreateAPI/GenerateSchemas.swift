// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Fix AnyJSON and StringCodingKeys layout
// TODO: Add option to hide AnyJSON
// TODO: testEdgecasesRename "Status": "State" is not working
// TODO: New APIs in spec for renams
// TODO: Rename enums as separate properrty

// TODO: Add not support and fix warnings
// TODO: Add File (Data) support (see FormatTest.date)
// TODO: Add Date(Day) support (NaiveDate?) (see FormatTest.date)
// TODO: Add UUID support (and test it!)
// TODO: Review OpenAPI spec for -all
// TODO: Add int32/int64 support (optional) (and a way to disable)
// TODO: Check why public struct ConfigItem: Decodable { is empty
// TODO: Get rid of typealiases where a custom type is generated public typealias SearchResultTextMatches = [SearchResultTextMatchesItem]
// TODO: Final imporvementes to OctoKit
// TODO: anyOf should be class or struct?
// TODO: Add an option to skip types

// TODO: Add Encodable support
// TODO: Test remaining String formats https://swagger.io/docs/specification/data-models/data-types/ AND add options to disable some of tem
// TODO: More concise examples if it's just array of plain types
// TODO: Add an option to use CodingKeys instead of custom init
// TODO: Option to just use automatic CodingKeys (if you backend is perfect)
// TODO: Add an option to generate an initializer
// TODO: See what needs to be fixed in petstore-all
// TODO: Add support for default values
// TODO: Option to disable custom key generation
// TODO: Add support for deprecated fields
// TODO: Better naming for inline/nested objects
// TODO: Print more in verbose mode
// TODO: Add warnings for unsupported features
// TODO: Add Linux support
// TODO: Add SwiftLint disable all
// TODO: Remove remainig dereferencing
// TODO: Add JSON tests
// TODO: Add OpenAPI 3.1 support
// TODO: Autocapitilize description/title
// TODO: Add an option to ignore errors in arrays
// TODO: Rename to GenerateEntities
// TODO: Add an option to set a custom header

// TODO: Add an obeserver for a file (and keep tool running)

// TODO: Separate mapped* dictionary for enums
// TODO: entitiesGeneratedAsClasses - add support for nesting
// TODO: Add an option how allOf is generated (inline properties, create protocols)
// TODO: Add nesting support for "entitiesGeneratedAsStructs(classes)"

final class GenerateSchemas {
    private let spec: OpenAPI.Document
    private let options: GenerateOptions
    private let arguments: GenerateArguments
    private let templates: Templates
    private var isAnyJSONUsed = false
    private let lock = NSLock()
    
    init(spec: OpenAPI.Document, options: GenerateOptions, arguments: GenerateArguments) {
        self.spec = spec
        self.options = options
        self.arguments = arguments
        self.templates = Templates(options: options)
    }

    func run() -> String {
        let startTime = CFAbsoluteTimeGetCurrent()
        if arguments.isVerbose {
            print("Generating schemas (\(spec.components.schemas.count))")
        }
        
        let output = _run()
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        if arguments.isVerbose {
            print("Generated schemas in \(timeElapsed) s.")
        }
        
        return output
    }
    
    func _run() -> String {
        var output = templates.fileHeader
        output += "\n\n"
        
        let schemas = Array(spec.components.schemas)
        var generated = Array<String?>(repeating: nil, count: schemas.count)
        let context = Context(parents: [])
        let lock = NSLock()
        concurrentPerform(on: schemas, parallel: arguments.isParallel) { index, item in
            let (key, schema) = schemas[index]
            
            guard let name = makeTypeNameFor(key: key, schema: schema) else {
                if arguments.isVerbose {
                    print("Skipping generation for \(key.rawValue)")
                }
                return
            }
                        
            do {
                if let entry = try makeTopDeclaration(name: name, schema: schema, context: context), !entry.isEmpty {
                    lock.lock()
                    generated[index] = entry
                    lock.unlock()
                }
            } catch {
                print("ERROR: Failed to generate entity for \(key.rawValue): \(error)")
            }
        }

        for entry in generated where entry != nil {
            output += entry!
            output += "\n\n"
        }
        
        if isAnyJSONUsed {
            output += "\n"
            output += anyJSON
            output += "\n"
        }

        output += stringCodingKey
        output += "\n"
    
        return output.indent(using: options)
    }
    
    /// Return `nil` to skip generation.
    private func makeTypeNameFor(key: OpenAPI.ComponentKey, schema: JSONSchema) -> TypeName? {
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
        let name = makeTypeName(key.rawValue)
        if !options.schemes.mappedTypeNames.isEmpty {
            if let mapped = options.schemes.mappedTypeNames[name.rawValue] {
                return TypeName(processedRawValue: mapped)
            }
        }
        return makeTypeName(key.rawValue)
    }
    
    // Recursively creates a complete type declaration: struct, class, enum, etc.
    private func makeTopDeclaration(name: TypeName, schema: JSONSchema, context: Context) throws -> String? {
        switch schema {
        case .boolean, .number, .integer:
            return nil // Always inline
        case .string(let info, _):
            guard isEnum(info) else { return nil } // Always inline
            return try makeEnum(name: name, info: info)
        case .object(let info, let details):
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
        case .reference:
            return nil // Can't appear in this context
        case .fragment:
            return nil // Can't appear in this context
        }
    }
                        
    private func makeProperty(key: String, schema: JSONSchema, isRequired: Bool, in context: Context) throws -> Property {
        let propertyName = makePropertyName(key)
        
        func makeChildPropertyName(for name: PropertyName, type: String) -> PropertyName {
            if !options.schemes.mappedPropertyNames.isEmpty {
                let names = context.parents.map { $0.rawValue } + [name.rawValue]
                for i in names.indices {
                    if let name = options.schemes.mappedPropertyNames[names[i...].joined(separator: ".")] {
                        return PropertyName(processedRawValue: name)
                    }
                }
            }
            if options.isGeneratingSwiftyBooleanPropertyNames && type == "Bool" {
                return name.asBoolean
            }
            return name
        }
        
        func child(name: PropertyName, type: String, info: JSONSchemaContext?, nested: String? = nil) -> Property {
            assert(info != nil) // context is null for references, but the caller needs to dereference first
            let nullable = info?.nullable ?? true
            let name = makeChildPropertyName(for: name, type: type)
            return Property(name: name, type: type, isOptional: !isRequired || nullable, key: key, schema: schema, context: info, nested: nested)
        }
   
        /// E.g. [String: String], [String: [String: AnyJSON]]
        func makeDictionary(info: JSONSchemaContext, properties: Either<Bool, JSONSchema>) throws -> Property {
            switch properties {
            case .a:
                return child(name: propertyName, type: "[String: AnyJSON]", info: info)
            case .b(let schema):
                // TODO: Do this recursively, but for now two levels will suffice (map of map)
                if case .object(let info, let details) = schema,
                   details.properties.isEmpty,
                   let additional = details.additionalProperties {
                    switch additional {
                    case .a:
                        return child(name: propertyName, type: "[String: [String: AnyJSON]]", info: info)
                    case .b(let schema):
                        if let type = try? getPrimitiveType(for: schema) {
                            return child(name: propertyName, type: "[String: [String: \(type)]]", info: info, nested: nil)
                        }
                        let nestedTypeName = makeTypeName(key).appending("Item")
                        let nested = try makeTopDeclaration(name: nestedTypeName, schema: schema, context: context)
                        return child(name: propertyName, type: "[String: [String: \(nestedTypeName)]]", info: info, nested: nested)
                    }
                }
                if let type = try? getPrimitiveType(for: schema) {
                    return child(name: propertyName, type: "[String: \(type)]", info: info, nested: nil)
                }
                let nestedTypeName = makeTypeName(key).appending("Item")
                // TODO: implement shiftRight (fix nested enums)
                let nested = try makeTopDeclaration(name: nestedTypeName, schema: schema, context: context)
                return child(name: propertyName, type: "[String: \(nestedTypeName)]", info: info, nested: nested)
            }
        }
        
        func makeObject(info: JSONSchemaContext, details: JSONSchema.ObjectContext) throws -> Property {
            if details.properties.isEmpty {
                var additional = details.additionalProperties
                if options.isInterpretingEmptyObjectsAsDictionary {
                    additional = additional ?? .a(true)
                }
                if let additional = additional {
                    return try makeDictionary(info: info, properties: additional)
                }
            }
            let type = makeTypeName(key)
            let nested = try makeTopDeclaration(name: type, schema: schema, context: context)
            return child(name: propertyName, type: type.rawValue, info: info, nested: nested)
        }
        
        func makeArray(info: JSONSchemaContext, details: JSONSchema.ArrayContext) throws -> Property {
            guard let item = details.items else {
                throw GeneratorError("Missing array item type")
            }
            if let type = try? getPrimitiveType(for: item) {
                return child(name: propertyName, type: "[\(type)]", info: info)
            }
            let name = makeNestedArrayTypeName(for: key)
            let nested = try makeTopDeclaration(name: name, schema: item, context: context)
            return child(name: propertyName, type: "[\(name)]", info: info, nested: nested)
        }
        
        func makeString(info: JSONSchemaContext) throws -> Property {
            if isEnum(info) {
                let typeName = makeTypeName(makeChildPropertyName(for: propertyName, type: "CreateAPIEnumPlaceholderName").rawValue)
                let nested = try makeEnum(name: typeName, info: info)
                return child(name: propertyName, type: typeName.rawValue, info: schema.coreContext, nested: nested)
            }
            let type = try getPrimitiveType(for: schema)
            return child(name: propertyName, type: type, info: info)
        }
        
        func makeSomeOf() throws -> Property {
            let name = makeTypeName(key)
            let nested = try makeTopDeclaration(name: name, schema: schema, context: context)
            return child(name: propertyName, type: name.rawValue, info: schema.coreContext, nested: nested)
        }
        
        func makeProperty(schema: JSONSchema) throws -> Property {
            let info: JSONSchemaContext?
            switch schema {
                // TODO: rewrite
            case .reference(let ref, _):
                let deref = try ref.dereferenced(in: spec.components)
                info = deref.coreContext
            default:
                info = schema.coreContext
            }
            let type = try getPrimitiveType(for: schema)
            return child(name: propertyName, type: type, info: info)
        }
        
        switch schema {
        case .object(let info, let details): return try makeObject(info: info, details: details)
        case .array(let info, let details): return try makeArray(info: info, details: details)
        case .string(let info, _): return try makeString(info: info)
        case .all, .one, .any: return try makeSomeOf()
        case .not: throw GeneratorError("`not` properties are not supported")
        default: return try makeProperty(schema: schema)
        }
    }
    
    // MARK: Object
    
    private func makeObject(name: TypeName, info: JSONSchema.CoreContext<JSONTypeFormat.ObjectFormat>, details: JSONSchema.ObjectContext, context: Context) throws -> String {
        var contents: [String] = []
        let context = Context(parents: context.parents + [name])
        let properties = makeProperties(for: details, context: context)
        
        contents.append(templates.properties(properties))
        contents += properties.compactMap { $0.nested }
        
        // Generate initializer
        if !properties.isEmpty && options.schemes.isGeneratingInitWithCoder {
            contents.append(templates.initFromDecoder(properties: properties))
        }
        
        // TODO: Add this an an options
//        let hasCustomCodingKeys = keys.contains { PropertyName($0).rawValue != $0 }
//        if hasCustomCodingKeys {
//            output += "\n"
//            output += "    private enum CodingKeys: String, CodingKey {\n"
//            for key in keys where !skippedKeys.contains(key) {
//                let parameter = PropertyName(key).rawValue
//                if parameter == key {
//                    output += "        case \(parameter)\n"
//                } else {
//                    output += "        case \(parameter) = \"\(key)\"\n"
//                }
//            }
//            output +=  "    }\n"
//        }
        
        
        var output = templates.comments(for: info, name: name.rawValue)
        output += templates.entity(name: name, contents: contents)
        return output
    }
    
    private func makeProperties(for object: JSONSchema.ObjectContext, context: Context) -> [Property] {
        object.properties.keys.sorted().compactMap { key in
            let schema = object.properties[key]!
            let isRequired = object.requiredProperties.contains(key)
            do {
                return try makeProperty(key: key, schema: schema, isRequired: isRequired, in: context)
            } catch {
                print("ERROR: Failed to generate property \(error)")
                return nil
            }
        }
    }
    
    private func makeNestedArrayTypeName(for key: String) -> TypeName {
        let name = makeTypeName(key)
        if options.isPluralizationEnabled, !options.pluralizationExceptions.contains(name.rawValue) {
            // Some know words that the library doesn't handle well
            if name.rawValue == "Environments" { return TypeName(processedRawValue: "Environment") }
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
    
    // MARK: Typealiases

    private func makeTypealiasArray(name: TypeName, info: JSONSchema.CoreContext<JSONTypeFormat.ArrayFormat>, details: JSONSchema.ArrayContext, context: Context) throws -> String {
        guard let item = details.items else {
            throw GeneratorError("Missing array item type")
        }
        if let type = try? getTypeName(for: item) {
            guard !options.isInliningPrimitiveTypes else {
                return ""
            }
            return templates.typealias(name: name, type: type.asArray)
        }
        // Requres generation of a separate type
        var output = ""
        let itemName = name.appending("Item")
        output += templates.typealias(name: name, type: itemName.asArray)
        output += "\n\n"
        output += (try makeTopDeclaration(name: itemName, schema: item, context: context)) ?? ""
        return output
    }
    
    // MARK: Enums
    
    private func makeEnum(name: TypeName, info: JSONSchemaContext) throws -> String {
        let values = (info.allowedValues ?? [])
            .compactMap { $0.value as? String }
        guard !values.isEmpty else {
            throw GeneratorError("Enum \(name) has no values")
        }
        var output = templates.comments(for: info, name: name.rawValue)
        let cases = values.map {
            let caseName = makePropertyName($0).rawValue
            return templates.case(name: caseName, value: $0)
        }.joined(separator: "\n")
        output += templates.enumOfStrings(name: name, contents: cases)
        return output
    }
    
    private func isInlinable(_ schema: JSONSchema) -> Bool {
        switch schema {
        case .boolean: return true
        case .number: return true
        case .integer: return true
        case .string(let info, _):
            return !isEnum(info)
        case .object: return false
        case .array(_, let details):
            if let item = details.items {
                return (try? getPrimitiveType(for: item)) != nil
            }
            return false
        case .all: return false
        case .one: return false
        case .any: return false
        case .not: return false
        case .reference: return false
        case .fragment: return false
        }
    }
    
    private func isEnum(_ info: JSONSchemaContext) -> Bool {
        options.isGeneratingEnums && info.allowedValues != nil
    }
    
    // MARK: Misc
    
    private func getTypeName(for json: JSONSchema) throws -> TypeName {
        TypeName(processedRawValue: try getPrimitiveType(for: json))
    }
    
    // Anything that's not an object or a reference.
    private func getPrimitiveType(for json: JSONSchema) throws -> String {
        switch json {
        case .boolean: return "Bool"
        case .number: return "Double"
        case .integer: return "Int"
        case .string(let info, _):
            if isEnum(info) {
                throw GeneratorError("Enum isn't a primitive type")
            }
            switch info.format {
            case .dateTime:
                return "Date"
            case .other(let other):
                if other == "uri" {
                    return "URL"
                }
            default: break
            }
            return "String"
        case .object(let info, _):
            throw GeneratorError("`object` is not supported: \(info)")
        case .array(_, let details):
            guard let items = details.items else {
                throw GeneratorError("Missing array item type")
            }
            return "[\(try getPrimitiveType(for: items))]"
        case .all(let of, _):
            throw GeneratorError("`allOf` is not supported: \(of)")
        case .one(let of, _):
            throw GeneratorError("`oneOf` is not supported: \(of)")
        case .any(let of, _):
            throw GeneratorError("`anyOf` is not supported: \(of)")
        case .not(let scheme, _):
            throw GeneratorError("`not` is not supported: \(scheme)")
        case .reference(let reference, _):
            switch reference {
            case .internal(let ref):
                if arguments.vendor == "github", let name = ref.name, name.hasPrefix("nullable-") {
                    return makeTypeName(name.replacingOccurrences(of: "nullable-", with: "")).rawValue
                }
                // Note: while dereferencing, it does it recursively.
                // So if you have `typealias Pets = [Pet]`, it'll dereference
                // `Pet` to an `.object`, not a `.reference`.
                if options.isInliningPrimitiveTypes,
                   let key = OpenAPI.ComponentKey(rawValue: ref.name ?? ""),
                   let scheme = spec.components.schemas[key],
                    let type = try? getPrimitiveType(for: scheme),
                    isInlinable(scheme) {
                    return type // Inline simple types
                }
                guard let name = ref.name else {
                    throw GeneratorError("Internal reference name is missing: \(ref)")
                }
                // TODO: Remove duplication
                if !options.schemes.mappedTypeNames.isEmpty {
                    if let mapped = options.schemes.mappedTypeNames[name] {
                        return mapped
                    }
                }
                return makeTypeName(name).rawValue
            case .external(let url):
                throw GeneratorError("External references are not supported: \(url)")
            }
        case .fragment:
            setAnyJsonNeeded()
            return "AnyJSON"
        }
    }
        
    // MARK: oneOf/anyOf/allOf
    
    private func makeOneOf(name: TypeName, schemas: [JSONSchema], context: Context) throws -> String {
        let context = context.adding(name)
        let properties: [Property] = try makeProperties(for: schemas, context: context)
        var contents: [String] = []
        contents.append(properties.map(templates.case).joined(separator: "\n"))
        contents += properties.compactMap { $0.nested }
        contents.append(templates.initFromDecoderOneOf(properties: properties))
        return templates.enumOneOf(name: name, contents: contents)
    }
        
    private func makeAnyOf(name: TypeName, schemas: [JSONSchema], context: Context) throws -> String {
        let context = context.adding(name)
        let properties = try makeProperties(for: schemas, context: context)
        var contents: [String] = []
        contents.append(templates.properties(properties))
        contents += properties.compactMap { $0.nested }
        contents.append(templates.initFromDecoderAnyOf(properties: properties))
        return templates.entity(name: name, contents: contents)
    }
    
    private func makeAllOf(name: TypeName, schemas: [JSONSchema], context: Context) throws -> String {
        let types = makeTypeNames(for: schemas)
        let context = context.adding(name)
        let properties: [Property] = try zip(types, schemas).flatMap { type, schema -> [Property] in
            switch schema {
            case .object(_, let details):
                // Inline properties for nested objects (differnt from other OpenAPI constructs)
                return makeProperties(for: details, context: context)
            default:
                return [try makeProperty(key: type, schema: schema, isRequired: true, in: context)]
            }
        }
        
        var contents: [String] = []
        contents.append(templates.properties(properties))
        contents += properties.compactMap { $0.nested }
        let decoderContents = properties.map {
            switch $0.schema {
            case .reference:
                return templates.decodeFromDecoder(property: $0)
            default:
                return templates.decode(property: $0)
            }
        }.joined(separator: "\n")
        contents.append(templates.initFromDecoder(contents: decoderContents))

        return templates.entity(name: name, contents: contents)
    }
    
    private func makeProperties(for schemas: [JSONSchema], context: Context) throws -> [Property] {
        try zip(makeTypeNames(for: schemas), schemas).map { type, schema in
            try makeProperty(key: type, schema: schema, isRequired: false, in: context)
        }
    }
        
    /// Generate type names for anonyous objects that are sometimes needed for `oneOf` or `anyOf`
    /// constructs.
    private func makeTypeNames(for schemas: [JSONSchema]) -> [String] {
        var types = Array<String?>(repeating: nil, count: schemas.count)
        
        // Assign known types (references, primitive)
        for (index, schema) in schemas.enumerated() {
            types[index] = try? getPrimitiveType(for: schema)
        }
        
        // Generate names for anonymous nested objects
        let unnamedCount = types.filter { $0 == nil }.count
        var genericCount = 1
        func makeNextGenericName() -> String {
            defer { genericCount += 1 }
            return "Object\((unnamedCount == 1 && genericCount == 1) ? "" : "\(genericCount)")"
        }
        for (index, _) in schemas.enumerated() {
            if types[index] == nil {
                types[index] = makeNextGenericName()
            }
        }
        
        // Disambiguate arrays
        func parameter(for type: String) -> String {
            let name = makePropertyName(type).rawValue
            guard options.isPluralizationEnabled else { return name }
            let isArray = type.starts(with: "[") // TODO: Refactor
            return isArray ? name.pluralized() : name
        }
        return types.map { parameter(for: $0!) }
    }
    
    // MARK: Helpers
    
    func setAnyJsonNeeded() {
        lock.lock()
        isAnyJSONUsed = true
        lock.unlock()
    }
    
    private func makePropertyName(_ rawValue: String) -> PropertyName {
        PropertyName(rawValue, options: options)
    }
    
    private func makeTypeName(_ rawValue: String) -> TypeName {
        TypeName(rawValue, options: options)
    }
}

struct GeneratorError: Error, LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }
    
    var errorDescription: String? {
        message
    }
}

private struct Context {
    let parents: [TypeName]
    
    func adding(_ parent: TypeName) -> Context {
        Context(parents: parents + [parent])
    }
}

struct Property {
    // Example: "files"
    let name: PropertyName
    // Example: "[File]"
    let type: String
    let isOptional: Bool
    // Key in the JSON
    let key: String

    let schema: JSONSchema
    let context: JSONSchemaContext?
    var nested: String?
}
