// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

final class GenerateOptions {
    var access: String?
    var isAddingDeprecations: Bool
    var isGeneratingEnums: Bool
    var isGeneratingSwiftyBooleanPropertyNames: Bool
    var isInliningTypealiases: Bool
    var isReplacingCommonAcronyms: Bool
    var addedAcronyms: [String]
    var ignoredAcronyms: [String]
    var indentation: Indentation
    var spaceWidth: Int
    var isPluralizationEnabled: Bool
    var isNaiveDateEnabled: Bool
    var isUsingIntegersWithPredefinedCapacity: Bool
    var isSwiftLintDisabled: Bool
    var fileHeader: String?
    
    var entities: Entities
    var paths: Paths
    var rename: Rename
    var comments: Comments
    
    // It's important for longer names to come first
    lazy var allAcronyms: [String] = Set(acronyms)
        .union(addedAcronyms)
        .subtracting(ignoredAcronyms)
        .sorted { $0.count > $1.count }

    enum Indentation: String, Codable {
        case spaces
        case tabs
    }
    
    struct Entities {
        var isGeneratingStructs: Bool
        var entitiesGeneratedAsClasses: Set<String>
        var entitiesGeneratedAsStructs: Set<String>
        var isMakingClassesFinal: Bool
        var baseClass: String?
        var protocols: Set<String>
        var isSkippingRedundantProtocols: Bool
        // TODO: simplify this
        var isGeneratingInitializers: Bool
        var isGeneratingInitWithDecoder: Bool
        var isGeneratingEncodeWithEncoder: Bool
        var isSortingPropertiesAlphabetically: Bool
        var isGeneratingCustomCodingKeys: Bool
        var isAddingDefaultValues: Bool
        var isInliningPropertiesFromReferencedSchemas: Bool
        var isAdditionalPropertiesOnByDefault: Bool
        var exclude: Set<String>
        var include: Set<String>
        
        init(_ options: GenerateOptionsSchema.Entities?) {
            self.isGeneratingStructs = options?.isGeneratingStructs ?? true
            self.entitiesGeneratedAsClasses = Set(options?.entitiesGeneratedAsClasses ?? [])
            self.entitiesGeneratedAsStructs = Set(options?.entitiesGeneratedAsStructs ?? [])
            self.isMakingClassesFinal = options?.isMakingClassesFinal ?? true
            self.baseClass = options?.baseClass
            self.protocols = Set(options?.protocols ?? ["Codable"])
            self.isSkippingRedundantProtocols = options?.isSkippingRedundantProtocols ?? true
            self.isGeneratingInitializers = options?.isGeneratingInitializers ?? true
            self.isGeneratingInitWithDecoder = options?.isGeneratingInitWithDecoder ?? true
            self.isGeneratingEncodeWithEncoder = options?.isGeneratingEncodeWithEncoder ?? true
            self.isSortingPropertiesAlphabetically = options?.isSortingPropertiesAlphabetically ?? false
            self.isGeneratingCustomCodingKeys = options?.isGeneratingCustomCodingKeys ?? true
            self.isAddingDefaultValues = options?.isAddingDefaultValues ?? true
            self.isInliningPropertiesFromReferencedSchemas = options?.isInliningPropertiesFromReferencedSchemas ?? false
            self.isAdditionalPropertiesOnByDefault = options?.isAdditionalPropertiesOnByDefault ?? true
            self.exclude = Set(options?.exclude ?? [])
            self.include = Set(options?.include ?? [])
        }
    }
    
    struct Paths {
        var style: PathsStyle
        var namespace: String
        var isGeneratingResponseHeaders: Bool
        var isAddingOperationIds: Bool
        var imports: Set<String>
        var overridenResponses: [String: String]
        var overridenBodyTypes: [String: String]
        var isInliningSimpleRequests: Bool
        var isInliningSimpleQueryParameters: Bool
        var simpleQueryParametersThreshold: Int
        // TODO: Replace this with a better solution for patch params
        var isMakingOptionalPatchParametersDoubleOptional: Bool
        var isRemovingRedundantPaths: Bool
        var skip: Set<String>
        
        init(_ options: GenerateOptionsSchema.Paths?) {
            self.style = options?.style ?? .rest
            self.namespace = options?.namespace ?? "Paths"
            self.isGeneratingResponseHeaders = options?.isGeneratingResponseHeaders ?? true
            self.isAddingOperationIds = options?.isAddingOperationIds ?? false
            self.imports = Set(options?.imports ?? ["Get"])
            self.overridenResponses = options?.overridenResponses ?? [:]
            self.overridenBodyTypes = options?.overridenBodyTypes ?? [:]
            self.isInliningSimpleRequests = options?.isInliningSimpleRequests ?? true
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

    struct Rename {
        var properties: [String: String]
        var parameters: [String: String]
        var enumCases: [String: String]
        var entities: [String: String]
        var operations: [String: String]
        var collectionElements: [String: String]
        var entityPrefix: String?
        var entitySuffix: String?
        
        init(_ options: GenerateOptionsSchema.Rename?) {
            self.properties = options?.properties ?? [:]
            self.parameters = options?.parameters ?? [:]
            self.enumCases = options?.enumCases ?? [:]
            self.entities = options?.entities ?? [:]
            self.operations = options?.operations ?? [:]
            self.collectionElements = options?.collectionElements ?? [:]
            self.entityPrefix = options?.entityPrefix
            self.entitySuffix = options?.entitySuffix
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

    init(_ options: GenerateOptionsSchema = .init()) {
        self.access = options.access ?? "public"
        self.paths = Paths(options.paths)
        self.isAddingDeprecations = options.isAddingDeprecations ?? true
        self.isGeneratingEnums = options.isGeneratingEnums ?? true
        self.isGeneratingSwiftyBooleanPropertyNames = options.isGeneratingSwiftyBooleanPropertyNames ?? true
        self.isInliningTypealiases = options.isInliningTypealiases ?? true
        self.isReplacingCommonAcronyms = options.isReplacingCommonAcronyms ?? true
        self.addedAcronyms = (options.addedAcronyms ?? []).map { $0.lowercased() }
        self.ignoredAcronyms = (options.ignoredAcronyms ?? []).map { $0.lowercased() }
        self.entities = Entities(options.entities)
        self.rename = Rename(options.rename)
        self.comments = Comments(options.comments)
        self.indentation = options.indentation ?? .spaces
        self.spaceWidth = options.spaceWidth ?? 4
        self.isPluralizationEnabled = options.isPluralizationEnabled ?? true
        self.isNaiveDateEnabled = options.isNaiveDateEnabled ?? true
        self.isUsingIntegersWithPredefinedCapacity = options.isUsingIntegersWithPredefinedCapacity ?? false
        self.isSwiftLintDisabled = options.isSwiftLintDisabled ?? true
        self.fileHeader = options.fileHeader
    }
}

final class GenerateOptionsSchema: Decodable {
    var access: String?
    var isAddingDeprecations: Bool?
    var isGeneratingEnums: Bool?
    var isGeneratingSwiftyBooleanPropertyNames: Bool?
    var isInliningTypealiases: Bool?
    var isReplacingCommonAcronyms: Bool?
    var addedAcronyms: [String]?
    var ignoredAcronyms: [String]?
    var indentation: GenerateOptions.Indentation?
    var spaceWidth: Int?
    var isPluralizationEnabled: Bool?
    var isAdditionalPropertiesOnByDefault: Bool?
    var isNaiveDateEnabled: Bool?
    var isUsingIntegersWithPredefinedCapacity: Bool?
    var isSwiftLintDisabled: Bool?
    var fileHeader: String?
    
    var entities: Entities?
    var paths: Paths?
    var rename: Rename?
    var comments: Comments?
    
    struct Entities: Decodable {
        var isGeneratingStructs: Bool?
        var entitiesGeneratedAsClasses: [String]?
        var entitiesGeneratedAsStructs: [String]?
        var isMakingClassesFinal: Bool?
        var isGeneratingInitializers: Bool?
        var baseClass: String?
        var protocols: [String]?
        var isSkippingRedundantProtocols: Bool?
        var isGeneratingInitWithDecoder: Bool?
        var isGeneratingEncodeWithEncoder: Bool?
        var isSortingPropertiesAlphabetically: Bool?
        var isGeneratingCustomCodingKeys: Bool?
        var isAddingDefaultValues: Bool?
        var isInliningPropertiesFromReferencedSchemas: Bool?
        var isAdditionalPropertiesOnByDefault: Bool?
        var exclude: [String]?
        var include: [String]?
    }
    
    struct Paths: Decodable {
        var style: GenerateOptions.PathsStyle?
        var namespace: String?
        var isGeneratingResponseHeaders: Bool?
        var isAddingOperationIds: Bool?
        var imports: [String]?
        var overridenResponses: [String: String]?
        var overridenBodyTypes: [String: String]?
        var isInliningSimpleRequests: Bool?
        var isInliningSimpleQueryParameters: Bool?
        var simpleQueryParametersThreshold: Int?
        var isMakingOptionalPatchParametersDoubleOptional: Bool?
        var isRemovingRedundantPaths: Bool?
        var skip: [String]?
    }

    struct Rename: Decodable {
        var properties: [String: String]?
        var parameters: [String: String]?
        var enumCases: [String: String]?
        var entities: [String: String]?
        var operations: [String: String]?
        var collectionElements: [String: String]?
        var entityPrefix: String?
        var entitySuffix: String?
    }
    
    struct Comments: Decodable {
        var isEnabled: Bool?
        var isAddingTitles: Bool?
        var isAddingDescription: Bool?
        var isAddingExamples: Bool?
        var isAddingExternalDocumentation: Bool?
        var isCapitalizationEnabled: Bool?
    }
}

struct GenerateArguments {
    let isVerbose: Bool
    let isParallel: Bool
    let isStrict: Bool
    let isIgnoringErrors: Bool
    let vendor: String?
    let module: ModuleName
}

private let acronyms = ["url", "id", "html", "ssl", "tls", "https", "http", "dns", "ftp", "api", "uuid", "json"]
