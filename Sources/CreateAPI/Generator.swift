// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Generate Encodable/Decodable only when needed

final class Generator {
    let spec: OpenAPI.Document
    let options: GenerateOptions
    let arguments: GenerateArguments
    let templates: Templates
    
    // State collected during generation
    var isAnyJSONUsed = false
    var isHTTPHeadersDependencyNeeded = false
    var isRequestOperationIdExtensionNeeded = false
    var isEmptyObjectNeeded = false
    var needsEncodable = Set<TypeName>()
    let lock = NSLock()
    
    private var startTime: CFAbsoluteTime?
    
    init(spec: OpenAPI.Document, options: GenerateOptions, arguments: GenerateArguments) {
        self.spec = spec
        self.options = options
        self.arguments = arguments
        self.templates = Templates(options: options)
    }
    
    // MARK: Performance Measurement
    
    func startMeasuring(_ operation: String) {
        startTime = CFAbsoluteTimeGetCurrent()
        if arguments.isVerbose {
            print("Started \(operation)")
        }
    }
    
    func stopMeasuring(_ operation: String) {
        guard let startTime = startTime else {
            return
        }
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        if arguments.isVerbose {
            print("Finished \(operation) in \(timeElapsed) s.")
        }
    }
}

extension Generator {
    
    // Recursively creates a complete type declaration: struct, class, enum, etc.
    func makeTopDeclaration(name: TypeName, schema: JSONSchema, context: Context) throws -> String? {
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
    
    func makeProperty(key: String, schema: JSONSchema, isRequired: Bool, in context: Context) throws -> Property {
        let propertyName = makePropertyName(key)
        
        func makeChildPropertyName(for name: PropertyName, type: TypeName) -> PropertyName {
            if !options.schemes.mappedPropertyNames.isEmpty {
                let names = context.parents.map { $0.rawValue } + [name.rawValue]
                for i in names.indices {
                    if let name = options.schemes.mappedPropertyNames[names[i...].joined(separator: ".")] {
                        return PropertyName(processedRawValue: name)
                    }
                }
            }
            if options.isGeneratingSwiftyBooleanPropertyNames && type.rawValue == "Bool" {
                return name.asBoolean
            }
            return name
        }
        
        func child(name: PropertyName, type: TypeName, info: JSONSchemaContext?, nested: String? = nil) -> Property {
            assert(info != nil) // context is null for references, but the caller needs to dereference first
            let nullable = info?.nullable ?? true
            let name = makeChildPropertyName(for: name, type: type)
            return Property(name: name, type: type, isOptional: !isRequired || nullable, key: key, schema: schema, context: info, nested: nested)
        }
                
        func makeObject(info: JSONSchemaContext, details: JSONSchema.ObjectContext) throws -> Property {
            // TODO: We can be smarter and combine `properties` with `additionalProperties`
            var additional = details.additionalProperties
            if details.properties.isEmpty, options.isInterpretingEmptyObjectsAsDictionaries {
                additional = additional ?? .a(true)
            }
            if let additional = additional {
                // E.g. [String: String], [String: [String: AnyJSON]]
                let property = try makeDictionary(info: info, key: key, additional, context: context)
                return child(name: propertyName, type: property.type, info: info, nested: property.nested)
            }
            let type = makeTypeName(key)
            let nested = try makeTopDeclaration(name: type, schema: schema, context: context)
            return child(name: propertyName, type: type, info: info, nested: nested)
        }
        
        func makeArray(info: JSONSchemaContext, details: JSONSchema.ArrayContext) throws -> Property {
            guard let item = details.items else {
                throw GeneratorError("Missing array item type")
            }
            if let type = try? getPrimitiveType(for: item, context: context) {
                return child(name: propertyName, type: type.asArray, info: info)
            }
            let name = makeNestedArrayTypeName(for: key)
            let nested = try makeTopDeclaration(name: name, schema: item, context: context)
            return child(name: propertyName, type: name.asArray, info: info, nested: nested)
        }
        
        func makeString(info: JSONSchemaContext) throws -> Property {
            if isEnum(info) {
                let typeName = makeTypeName(makeChildPropertyName(for: propertyName, type: TypeName(processed: "CreateAPIEnumPlaceholderName")).rawValue)
                let nested = try makeEnum(name: typeName, info: info)
                return child(name: propertyName, type: typeName, info: schema.coreContext, nested: nested)
            }
            let type = try getPrimitiveType(for: schema, context: context)
            return child(name: propertyName, type: type, info: info)
        }
        
        func makeSomeOf() throws -> Property {
            let name = makeTypeName(key)
            let nested = try makeTopDeclaration(name: name, schema: schema, context: context)
            return child(name: propertyName, type: name, info: schema.coreContext, nested: nested)
        }
        
        func makeReference(reference: JSONReference<JSONSchema>) throws -> Property {
            let deref = try reference.dereferenced(in: spec.components)
            let info = deref.coreContext
            let type = try getPrimitiveType(for: schema, context: context)
            return child(name: propertyName, type: type, info: info)
        }
        
        func makeProperty(schema: JSONSchema) throws -> Property {
            let info = schema.coreContext
            let type = try getPrimitiveType(for: schema, context: context)
            return child(name: propertyName, type: type, info: info)
        }
        
        switch schema {
        case .object(let info, let details):
            if let property = try? makeProperty(schema: schema) {
                return property
            }
            return try makeObject(info: info, details: details)
        case .array(let info, let details): return try makeArray(info: info, details: details)
        case .string(let info, _): return try makeString(info: info)
        case .all, .one, .any: return try makeSomeOf()
        case .reference(let ref, _): return try makeReference(reference: ref)
        case .not: throw GeneratorError("`not` properties are not supported")
        default: return try makeProperty(schema: schema)
        }
    }
    
    private struct AdditionalProperties {
        let type: TypeName
        let info: JSONSchemaContext
        var nested: String?
    }
    
    private func makeDictionary(info: JSONSchemaContext, key: String, _ schema: Either<Bool, JSONSchema>, context: Context) throws -> AdditionalProperties {
        switch schema {
        case .a:
            return AdditionalProperties(type: TypeName(processed: "[String: AnyJSON]"), info: info)
        case .b(let schema):
            if let type = try? getPrimitiveType(for: schema, context: context) {
                return AdditionalProperties(type: TypeName(processed: "[String: \(type)]"), info: info)
            }
            let nestedTypeName = makeTypeName(key).appending("Item")
            let nested = try makeTopDeclaration(name: nestedTypeName, schema: schema, context: context)
            return AdditionalProperties(type: TypeName(processed: "[String: \(nestedTypeName)]"), info: info, nested: nested)
        }
    }
    
    // MARK: Object
    
    private func makeObject(name: TypeName, info: JSONSchema.CoreContext<JSONTypeFormat.ObjectFormat>, details: JSONSchema.ObjectContext, context: Context) throws -> String? {
        if let type = try? getPrimitiveType(for: JSONSchema.object(info, details), context: context), !type.isVoid {
            guard !options.isInliningPrimitiveTypes else { return nil }
            return templates.typealias(name: name, type: type)
        }
        
        var contents: [String] = []
        let context = context.adding(name)
        let properties = makeProperties(for: details, context: context)
        
        contents.append(templates.properties(properties))
        contents += properties.compactMap { $0.nested }

        if options.schemes.isGeneratingInitializers {
            contents.append(templates.initializer(properties: properties))
        }
        
        let protocols = getProtocols(for: name, context: context)

        if protocols.contains("Codable") || protocols.contains("Decodable") {
            // Generate init with cocde
            if !properties.isEmpty && options.schemes.isGeneratingInitWithCoder {
                contents.append(templates.initFromDecoder(properties: properties))
            }
        }
        
        if protocols.contains("Codable") || protocols.contains("Encodable") {
            if !properties.isEmpty && options.schemes.isGeneratingDecode {
                contents.append(templates.encode(properties: properties))
            }
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
        output += makeEntity(name: name, contents: contents, context: context)
        return output
    }
    
    // TODO: Simplify
    private func getProtocols(for type: TypeName, context: Context) -> Set<String> {
        var protocols = options.schemes.adoptedProtocols
        let needsEncodable = (protocols.contains("Encodable") || protocols.contains( "Codable")) && (context.isEncodableNeeded || !options.schemes.isSkippingRedundantProtocols)
        if !needsEncodable {
            if protocols.contains("Codable") {
                protocols.remove("Codable")
                protocols.insert("Decodable")
            } else {
                protocols.remove("Encodable")
            }
        }
        return protocols
    }
    
    private func makeEntity(name: TypeName, contents: [String], context: Context) -> String {
        let protocols = getProtocols(for: name, context: context).sorted()
        return templates.entity(name: name, contents: contents, protocols: protocols)
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
            if name.rawValue == "Environments" { return TypeName(processed: "Environment") }
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
        if let type = try? getPrimitiveType(for: item, context: context) {
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
        let hasDuplicates = values.count != Set(values.map(makePropertyName).map(\.rawValue)).count
        let cases = values.map {
            let caseName = hasDuplicates ? $0 : makePropertyName($0).rawValue
            return templates.case(name: caseName, value: $0)
        }.joined(separator: "\n")
        output += templates.enumOfStrings(name: name, contents: cases)
        return output
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
        case .fragment: return false
        }
    }
    
    private func isEnum(_ info: JSONSchemaContext) -> Bool {
        options.isGeneratingEnums && info.allowedValues != nil
    }
    
    // MARK: Misc
    
    // TODO: Return `nil` when primitive types can't be found
    // Anything that's not an object or a reference.
    private func getPrimitiveType(for json: JSONSchema, context: Context) throws -> TypeName {
        switch json {
        case .boolean: return TypeName(processed: "Bool")
        case .number: return TypeName(processed: "Double")
        case .integer: return TypeName(processed: "Int")
        case .string(let info, _):
            if isEnum(info) {
                throw GeneratorError("Enum isn't a primitive type")
            }
            switch info.format {
            case .dateTime:
                return TypeName(processed: "Date")
            case .other(let other):
                if other == "uri" {
                    return TypeName(processed: "URL")
                }
            default: break
            }
            return TypeName(processed: "String")
        case .object(let info, let details):
            var additional = details.additionalProperties
            if details.properties.isEmpty, options.isInterpretingEmptyObjectsAsDictionaries {
                additional = additional ?? .a(true)
            }
            if details.properties.isEmpty, let additional = details.additionalProperties {
                switch additional {
                case .a(let allowsAdditionalProperties):
                    return TypeName(processed: allowsAdditionalProperties ? "[String: AnyJSON]" : "Void")
                case .b(let schema):
                    if let type = try? getPrimitiveType(for: schema, context: context) {
                        return TypeName(processed: "[String: \(type)]")
                    }
                }
            }
            throw GeneratorError("`object` is not supported: \(info)")
        case .array(_, let details):
            guard let items = details.items else {
                throw GeneratorError("Missing array item type")
            }
            return try getPrimitiveType(for: items, context: context).asArray
        case .all(let of, _):
            throw GeneratorError("`allOf` is not supported: \(of)")
        case .one(let of, _):
            throw GeneratorError("`oneOf` is not supported: \(of)")
        case .any(let of, _):
            throw GeneratorError("`anyOf` is not supported: \(of)")
        case .not(let scheme, _):
            throw GeneratorError("`not` is not supported: \(scheme)")
        case .reference(let reference, _):
            return try getReferenceType(reference, context: context)
        case .fragment:
            setAnyJsonNeeded()
            return TypeName(processed: "AnyJSON")
        }
    }
    
    private func getReferenceType(_ reference: JSONReference<JSONSchema>, context: Context) throws -> TypeName {
        switch reference {
        case .internal(let ref):
            if arguments.vendor == "github", let name = ref.name, name.hasPrefix("nullable-") {
                let replacement = makeTypeName(name.replacingOccurrences(of: "nullable-", with: ""))
                return replacement.namespace(context.namespace)
            }
            // Note: while dereferencing, it does it recursively.
            // So if you have `typealias Pets = [Pet]`, it'll dereference
            // `Pet` to an `.object`, not a `.reference`.
            if options.isInliningPrimitiveTypes,
               let key = OpenAPI.ComponentKey(rawValue: ref.name ?? ""),
               let scheme = spec.components.schemas[key],
               let inlined = try? getPrimitiveType(for: scheme, context: context),
               isInlinable(scheme, context: context) {
                return inlined // Inline simple types
            }
            guard let name = ref.name else {
                throw GeneratorError("Internal reference name is missing: \(ref)")
            }
            // TODO: Remove duplication
            if !options.schemes.mappedTypeNames.isEmpty {
                if let mapped = options.schemes.mappedTypeNames[name] {
                    return TypeName(processed: mapped.namespace(context.namespace))
                }
            }
            return makeTypeName(name).namespace(context.namespace)
        case .external(let url):
            throw GeneratorError("External references are not supported: \(url)")
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
        contents.append(templates.encodeOneOf(properties: properties))
        let hashable = Set(["String", "Bool", "URL", "Int", "Double"]) // TODO: Add support for more types
        let isHashable = properties.allSatisfy { hashable.contains($0.type.rawValue) }
        return templates.enumOneOf(name: name, contents: contents, isHashable: isHashable)
    }
    
    private func makeAnyOf(name: TypeName, schemas: [JSONSchema], context: Context) throws -> String {
        let context = context.adding(name)
        var properties = try makeProperties(for: schemas, context: context)
        var contents: [String] = []
        // `anyOf` where one type is off just means optional response
        if let index = properties.firstIndex(where: { $0.type.isVoid }) {
            properties.remove(at: index)
        }
        contents.append(templates.properties(properties))
        contents += properties.compactMap { $0.nested }
        contents.append(templates.initFromDecoderAnyOf(properties: properties))
        return makeEntity(name: name, contents: contents, context: context)
    }
    
    private func makeAllOf(name: TypeName, schemas: [JSONSchema], context: Context) throws -> String {
        let types = makeTypeNames(for: schemas, context: context)
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
        
        return makeEntity(name: name, contents: contents, context: context)
    }
    
    private func makeProperties(for schemas: [JSONSchema], context: Context) throws -> [Property] {
        try zip(makeTypeNames(for: schemas, context: context), schemas).map { type, schema in
            try makeProperty(key: type, schema: schema, isRequired: false, in: context)
        }
    }
    
    /// Generate type names for anonyous objects that are sometimes needed for `oneOf` or `anyOf`
    /// constructs.
    private func makeTypeNames(for schemas: [JSONSchema], context: Context) -> [String] {
        var types = Array<TypeName?>(repeating: nil, count: schemas.count)
        
        // Assign known types (references, primitive)
        for (index, schema) in schemas.enumerated() {
            types[index] = try? getPrimitiveType(for: schema, context: context)
        }
        
        // Generate names for anonymous nested objects
        let unnamedCount = types.filter { $0 == nil }.count
        var genericCount = 1
        func makeNextGenericName() -> TypeName {
            defer { genericCount += 1 }
            return TypeName(processed: "Object\((unnamedCount == 1 && genericCount == 1) ? "" : "\(genericCount)")")
        }
        for (index, _) in schemas.enumerated() {
            if types[index] == nil {
                types[index] = makeNextGenericName()
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
        return types.map { parameter(for: $0!.rawValue) }
    }
    
    // MARK: Names
    
    func makePropertyName(_ rawValue: String) -> PropertyName {
        PropertyName(rawValue, options: options)
    }
    
    func makeTypeName(_ rawValue: String) -> TypeName {
        TypeName(rawValue, options: options)
    }
    
    // MARK: State
    
    func setAnyJsonNeeded() {
        lock.lock()
        isAnyJSONUsed = true
        lock.unlock()
    }
    
    func setHTTPHeadersDependencyNeeded() {
        lock.lock()
        isHTTPHeadersDependencyNeeded = true
        lock.unlock()
    }
    
    func setNeedsEncodable(for type: TypeName) {
        lock.lock()
        needsEncodable.insert(type)
        lock.unlock()
    }
    
    func setRequestOperationIdExtensionNeeded() {
        lock.lock()
        isRequestOperationIdExtensionNeeded = true
        lock.unlock()
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

struct Context {
    var parents: [TypeName]
    var namespace: String?
    var isEncodableNeeded = true
    
    func adding(_ parent: TypeName) -> Context {
        Context(parents: parents + [parent], namespace: namespace, isEncodableNeeded: isEncodableNeeded)
    }
}

struct Property {
    // Example: "files"
    let name: PropertyName
    // Example: "[File]"
    let type: TypeName
    let isOptional: Bool
    // Key in the JSON
    let key: String
    
    let schema: JSONSchema
    let context: JSONSchemaContext?
    var nested: String?
}
