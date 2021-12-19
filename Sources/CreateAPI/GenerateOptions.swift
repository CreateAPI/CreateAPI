// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

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
    var isNaiveDateEnabled: Bool
    var isUsingIntegersWithPredefinedCapacity: Bool
    
    enum Indentation: String, Codable {
        case spaces
        case tabs
    }

    struct FileHeader {
        var addSwiftLintDisabled: Bool
        var addGetImport: Bool
        var header: String?
        
        init(_ options: GenerateOptionsSchema.FileHeader?) {
            self.addSwiftLintDisabled = options?.addSwiftLintDisabled ?? true
            self.addGetImport = options?.addGetImport ?? true
            self.header = options?.header
        }
    }
        
    struct Rename {
        var properties: [String: String]
        var parameters: [String: String]
        var enumCaseNames: [String: String]
        var entities: [String: String]
        var operations: [String: String]
        
        init(_ options: GenerateOptionsSchema.Rename?) {
            self.properties = options?.properties ?? [:]
            self.parameters = options?.parameters ?? [:]
            self.enumCaseNames = options?.enumCaseNames ?? [:]
            self.entities = options?.entities ?? [:]
            self.operations = options?.operations ?? [:]
        }
    }
    
    struct Comments {
        var isEnabled: Bool
        var isAddingTitles: Bool
        var isAddingDescription: Bool
        var isAddingExamples: Bool
        var isAddingExternalDocumentation: Bool
        var isCapitalizationEnabled: Bool
        
        init(_ options: GenerateOptionsSchema.Comments?) {
            self.isEnabled = options?.isEnabled ?? true
            self.isAddingTitles = options?.isAddingTitles ?? true
            self.isAddingDescription = options?.isAddingDescription ?? true
            self.isAddingExamples = options?.isAddingExamples ?? true
            self.isAddingExternalDocumentation = options?.isAddingExternalDocumentation ?? true
            self.isCapitalizationEnabled = options?.isCapitalizationEnabled ?? true
        }
    }
    
    struct Paths {
        var style: PathsStyle
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
        var isMakingOptionalPatchParametersDoubleOptional: Bool
        var isRemovingRedundantPaths: Bool
        var skip: Set<String>
        
        init(_ options: GenerateOptionsSchema.Paths?) {
            self.style = options?.style ?? .rest
            self.namespace = options?.namespace ?? "Paths"
            self.isAddingResponseHeaders = options?.isAddingResponseHeaders ?? true
            self.isAddingOperationIds = options?.isAddingOperationIds ?? false
            self.imports = Set(options?.imports ?? ["APIClient", "HTTPHeaders"])
            self.overrideResponses = options?.overrideResponses ?? [:]
            var queryParameterEncoders = makeDefaultParameterEncoders()
            for (key, value) in options?.queryParameterEncoders ?? [:] {
                queryParameterEncoders[key] = value // Override default values
            }
            self.queryParameterEncoders = queryParameterEncoders
            self.isUsingPropertiesForMethodsWithNoArguments = options?.isUsingPropertiesForMethodsWithNoArguments ?? true
            self.isInliningSimpleRequestType = options?.isInliningSimpleRequestType ?? true
            self.isInliningSimpleQueryParameters = options?.isInliningSimpleQueryParameters ?? true
            self.simpleQueryParametersThreshold = options?.simpleQueryParametersThreshold ?? 2
            self.isRemovingRedundantPaths = options?.isRemovingRedundantPaths ?? true
            self.isMakingOptionalPatchParametersDoubleOptional = options?.isMakingOptionalPatchParametersDoubleOptional ?? false
            self.skip = Set(options?.skip ?? [])
        }
    }
    
    enum PathsStyle: String, Decodable {
        case rest
        case operations
    }
        
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
        var isGeneratingInitWithDecoder: Bool
        var isGeneratingEncodeWithEncoder: Bool
        var isSortingPropertiesAlphabetically: Bool
        var isUsingCustomCodingKeys: Bool
        var isAddingDefaultValues: Bool
        var skip: Set<String>
        
        init(_ options: GenerateOptionsSchema.Entities?) {
            self.isGeneratingStructs = options?.isGeneratingStructs ?? true
            self.entitiesGeneratedAsClasses = Set(options?.entitiesGeneratedAsClasses ?? [])
            self.entitiesGeneratedAsStructs = Set(options?.entitiesGeneratedAsStructs ?? [])
            self.isMakingClassesFinal = options?.isMakingClassesFinal ?? true
            self.baseClass = options?.baseClass
            self.adoptedProtocols = Set(options?.adoptedProtocols ?? ["Codable"])
            self.isSkippingRedundantProtocols = options?.isSkippingRedundantProtocols ?? true
            self.isGeneratingInitializers = options?.isGeneratingInitializers ?? true
            self.isGeneratingInitWithDecoder = options?.isGeneratingInitWithDecoder ?? true
            self.isGeneratingEncodeWithEncoder = options?.isGeneratingEncodeWithEncoder ?? true
            self.isSortingPropertiesAlphabetically = options?.isSortingPropertiesAlphabetically ?? false
            self.isUsingCustomCodingKeys = options?.isUsingCustomCodingKeys ?? true
            self.isAddingDefaultValues = options?.isAddingDefaultValues ?? true
            self.skip = Set(options?.skip ?? [])
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
        self.isNaiveDateEnabled = options.isNaiveDateEnabled ?? true
        self.isUsingIntegersWithPredefinedCapacity = options.isUsingIntegersWithPredefinedCapacity ?? false
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
    var entities: Entities?
    var fileHeader: FileHeader?
    var rename: Rename?
    var comments: Comments?
    var indentation: GenerateOptions.Indentation?
    var spaceWidth: Int?
    var isPluralizationEnabled: Bool?
    var pluralizationExceptions: [String]?
    var isInterpretingEmptyObjectsAsDictionaries: Bool?
    var isNaiveDateEnabled: Bool?
    var isUsingIntegersWithPredefinedCapacity: Bool?
    
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
        var operations: [String: String]?
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
        var style: GenerateOptions.PathsStyle?
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
        var isMakingOptionalPatchParametersDoubleOptional: Bool?
        var isRemovingRedundantPaths: Bool?
        var skip: [String]?
    }
    
    struct Entities: Decodable {
        var isGeneratingStructs: Bool?
        var entitiesGeneratedAsClasses: [String]?
        var entitiesGeneratedAsStructs: [String]?
        var isMakingClassesFinal: Bool?
        var isGeneratingInitializers: Bool?
        var baseClass: String?
        var adoptedProtocols: [String]?
        var isSkippingRedundantProtocols: Bool?
        var isGeneratingInitWithDecoder: Bool?
        var isGeneratingEncodeWithEncoder: Bool?
        var isSortingPropertiesAlphabetically: Bool?
        var isUsingCustomCodingKeys: Bool?
        var isAddingDefaultValues: Bool?
        var skip: [String]?
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
        "Int32": "String(self)",
        "Int64": "String(self)",
        "Double": "String(self)",
        "Bool": #"self ? "true" : "false""#,
        "Date": "ISO8601DateFormatter().string(from: self)",
        "URL": "absoluteString",
        "NaiveDate": "String(self)",
    ]
}
