// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

// TODO: Add an option to generate parametes as `let` and a list of exceptions
final class GenerateOptions {
    var access: String
    var isRemovingUnneededImports: Bool
    var paths: Paths
    var entities: Entities
    var isAddingDeprecations: Bool
    var isGeneratingEnums: Bool
    var isGeneratingSwiftyBooleanPropertyNames: Bool
    var isInliningPrimitiveTypes: Bool
    var isReplacingCommonAcronyms: Bool
    var additionalAcronyms: [String]
    var fileHeader: FileHeader
    var rename: Rename
    var comments: Comments
    var indentation: Indentation
    var spaceWidth: Int
    var isPluralizationEnabled: Bool
    var pluralizationExceptions: Set<String>
    var isInterpretingEmptyObjectsAsDictionaries: Bool
    
    enum Indentation: String, Codable {
        case spaces
        case tabs
    }

    struct FileHeader {
        var addSwiftLintDisabled: Bool
        var addGetImport: Bool
        var header: String?
        
        init(_ fileHeader: GenerateOptionsSchema.FileHeader?) {
            self.addSwiftLintDisabled = fileHeader?.addSwiftLintDisabled ?? true
            self.addGetImport = fileHeader?.addGetImport ?? true
            self.header = fileHeader?.header
        }
    }
        
    struct Rename {
        var properties: [String: String]
        var parameters: [String: String]
        var enumCaseNames: [String: String]
        var entities: [String: String]
        
        init(_ paths: GenerateOptionsSchema.Rename?) {
            self.properties = paths?.properties ?? [:]
            self.parameters = paths?.parameters ?? [:]
            self.enumCaseNames = paths?.enumCaseNames ?? [:]
            self.entities = paths?.entities ?? [:]
        }
    }
    
    struct Comments {
        var isEnabled: Bool
        var isAddingTitles: Bool
        var isAddingDescription: Bool
        var isAddingExamples: Bool
        var isAddingExternalDocumentation: Bool
        var isCapitalizationEnabled: Bool
        
        init(_ comments: GenerateOptionsSchema.Comments?) {
            self.isEnabled = comments?.isEnabled ?? true
            self.isAddingTitles = comments?.isAddingTitles ?? true
            self.isAddingDescription = comments?.isAddingDescription ?? true
            self.isAddingExamples = comments?.isAddingExamples ?? true
            self.isAddingExternalDocumentation = comments?.isAddingExternalDocumentation ?? true
            self.isCapitalizationEnabled = comments?.isCapitalizationEnabled ?? true
        }
    }
    
    struct Paths {
        var namespace: String
        var isAddingResponseHeaders: Bool
        var isAddingOperationIds: Bool
        var imports: Set<String>
        var overrideResponses: [String: String]
        var queryParameterEncoders: [String: String]
        var isUsingPropertiesForMethodsWithNoArguments: Bool
        var isInliningSimpleRequestType: Bool
        var isInliningSimpleQueryParameters: Bool
        var simpleQueryParametersThreshold: Int
        
        init(_ paths: GenerateOptionsSchema.Paths?) {
            self.namespace = paths?.namespace ?? "Paths"
            self.isAddingResponseHeaders = paths?.isAddingResponseHeaders ?? true
            self.isAddingOperationIds = paths?.isAddingOperationIds ?? false
            self.imports = Set(paths?.imports ?? ["APIClient", "HTTPHeaders"])
            self.overrideResponses = paths?.overrideResponses ?? [:]
            var queryParameterEncoders = makeDefaultParameterEncoders()
            for (key, value) in paths?.queryParameterEncoders ?? [:] {
                queryParameterEncoders[key] = value // Override default values
            }
            self.queryParameterEncoders = queryParameterEncoders
            self.isUsingPropertiesForMethodsWithNoArguments = paths?.isUsingPropertiesForMethodsWithNoArguments ?? true
            self.isInliningSimpleRequestType = paths?.isInliningSimpleRequestType ?? true
            self.isInliningSimpleQueryParameters = paths?.isInliningSimpleQueryParameters ?? true
            self.simpleQueryParametersThreshold = paths?.simpleQueryParametersThreshold ?? 2
        }
    }
        
    // TODO: Inline this?
    struct Entities {
        var isGeneratingStructs: Bool
        var entitiesGeneratedAsClasses: Set<String>
        var entitiesGeneratedAsStructs: Set<String>
        var isMakingClassesFinal: Bool
        var baseClass: String?
        var adoptedProtocols: Set<String>
        var isSkippingRedundantProtocols: Bool
        // TODO: simplify this
        var isGeneratingInitializers: Bool
        var isGeneratingInitWithCoder: Bool
        var isGeneratingDecode: Bool
        var isSortingPropertiesAlphabetically: Bool
        
        init(_ schemas: GenerateOptionsSchema.Schemas?) {
            self.isGeneratingStructs = schemas?.isGeneratingStructs ?? true
            self.entitiesGeneratedAsClasses = Set(schemas?.entitiesGeneratedAsClasses ?? [])
            self.entitiesGeneratedAsStructs = Set(schemas?.entitiesGeneratedAsStructs ?? [])
            self.isMakingClassesFinal = schemas?.isMakingClassesFinal ?? true
            self.baseClass = schemas?.baseClass
            self.adoptedProtocols = Set(schemas?.adoptedProtocols ?? ["Codable"])
            self.isSkippingRedundantProtocols = schemas?.isSkippingRedundantProtocols ?? true
            self.isGeneratingInitializers = schemas?.isGeneratingInitializers ?? true
            self.isGeneratingInitWithCoder = schemas?.isGeneratingInitWithCoder ?? true
            self.isGeneratingDecode = schemas?.isGeneratingDecode ?? true
            self.isSortingPropertiesAlphabetically = schemas?.isSortingPropertiesAlphabetically ?? false
        }
    }

    init(_ options: GenerateOptionsSchema = .init()) {
        self.access = options.access ?? "public"
#warning("TODO: replace with Get")
        self.isRemovingUnneededImports = options.isRemovingUnneededImports ?? true
        self.paths = Paths(options.paths)
        self.isAddingDeprecations = options.isAddingDeprecations ?? true
        self.isGeneratingEnums = options.isGeneratingEnums ?? true
        self.isGeneratingSwiftyBooleanPropertyNames = options.isGeneratingSwiftyBooleanPropertyNames ?? true
        self.isInliningPrimitiveTypes = options.isInliningPrimitiveTypes ?? true
        self.isReplacingCommonAcronyms = options.isReplacingCommonAcronyms ?? true
        self.additionalAcronyms = (options.additionalAcronyms ?? []).map { $0.lowercased() }
        self.entities = Entities(options.entities)
        self.fileHeader = FileHeader(options.fileHeader)
        self.rename = Rename(options.rename)
        self.comments = Comments(options.comments)
        self.indentation = options.indentation ?? .spaces
        self.spaceWidth = options.spaceWidth ?? 4
        self.isPluralizationEnabled = options.isPluralizationEnabled ?? true
        self.pluralizationExceptions = Set(options.pluralizationExceptions ?? [])
        self.isInterpretingEmptyObjectsAsDictionaries = options.isInterpretingEmptyObjectsAsDictionaries ?? false
    }
}

final class GenerateOptionsSchema: Decodable {
    var access: String?
    var isRemovingUnneededImports: Bool?
    var paths: Paths?
    var isAddingDeprecations: Bool?
    var isGeneratingEnums: Bool?
    var isGeneratingSwiftyBooleanPropertyNames: Bool?
    var isInliningPrimitiveTypes: Bool?
    var isReplacingCommonAcronyms: Bool?
    var additionalAcronyms: [String]?
    var entities: Schemas?
    var fileHeader: FileHeader?
    var rename: Rename?
    var comments: Comments?
    var indentation: GenerateOptions.Indentation?
    var spaceWidth: Int?
    var isPluralizationEnabled: Bool?
    var pluralizationExceptions: [String]?
    var isInterpretingEmptyObjectsAsDictionaries: Bool?
    
    struct FileHeader: Decodable {
        var addSwiftLintDisabled: Bool?
        var addGetImport: Bool?
        var header: String?
    }
    
    struct Rename: Decodable {
        var properties: [String: String]?
        var parameters: [String: String]?
        var enumCaseNames: [String: String]?
        var entities: [String: String]?
    }
    
    struct Comments: Decodable {
        var isEnabled: Bool?
        var isAddingTitles: Bool?
        var isAddingDescription: Bool?
        var isAddingExamples: Bool?
        var isAddingExternalDocumentation: Bool?
        var isCapitalizationEnabled: Bool?
    }
    
    struct Paths: Decodable {
        var namespace: String?
        var isAddingResponseHeaders: Bool?
        var isAddingOperationIds: Bool?
        var imports: [String]?
        var overrideResponses: [String: String]?
        var queryParameterEncoders: [String: String]?
        var isUsingPropertiesForMethodsWithNoArguments: Bool?
        var isInliningSimpleRequestType: Bool?
        var isInliningSimpleQueryParameters: Bool?
        var simpleQueryParametersThreshold: Int?
    }
    
    struct Schemas: Decodable {
        var isGeneratingStructs: Bool?
        var entitiesGeneratedAsClasses: [String]?
        var entitiesGeneratedAsStructs: [String]?
        var isMakingClassesFinal: Bool?
        var isGeneratingInitializers: Bool?
        var baseClass: String?
        var adoptedProtocols: [String]?
        var isSkippingRedundantProtocols: Bool?
        var isGeneratingInitWithCoder: Bool?
        var isGeneratingDecode: Bool?
        var isSortingPropertiesAlphabetically: Bool?
    }
}

struct GenerateArguments {
    let isVerbose: Bool
    let isParallel: Bool
    let isStrict: Bool
    let vendor: String?
    let module: ModuleName?
}

private func makeDefaultParameterEncoders() -> [String: String] {
    return [
        "String": "self",
        "Int": "String(self)",
        "Double": "String(self)",
        "Bool": #"self ? "true" : "false""#,
        "Date": "ISO8601DateFormatter().string(from: self)",
        "URL": "absoluteString"
    ]
}
