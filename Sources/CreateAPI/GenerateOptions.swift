// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

final class GenerateOptions {
    var access: String?
    var isGeneratingComments: Bool
    var isGeneratingEnums: Bool
    var isGeneratingSwiftyBooleanPropertyNames: Bool
    var isInliningPrimitiveTypes: Bool
    var isReplacingCommongAbbreviations: Bool
    var schemes: SchemesOptions
    
    // TODO: Inline this?
    struct SchemesOptions {
        var isGeneratingStructs: Bool
        var entitiesGeneratedAsClasses: Set<String>
        var entitiesGeneratedAsStructs: Set<String>
        var isGeneratingInitWithCoder: Bool
        var baseClass: String?
        var adoptedProtocols: [String]
        var mappedPropertyNames: [String: String]
        var mappedTypeNames: [String: String] // Currently doesn't work for nested types
        
        init(_ schemes: GenerateOptionsScheme.SchemesOptions?) {
            self.isGeneratingStructs = schemes?.isGeneratingStructs ?? true
            self.entitiesGeneratedAsClasses = Set(schemes?.entitiesGeneratedAsClasses ?? [])
            self.entitiesGeneratedAsStructs = Set(schemes?.entitiesGeneratedAsStructs ?? [])
            self.isGeneratingInitWithCoder = schemes?.isGeneratingInitWithCoder ?? true
            self.baseClass = schemes?.baseClass
            self.adoptedProtocols = schemes?.adoptedProtocols ?? ["Decodable"]
            self.mappedPropertyNames = schemes?.mappedPropertyNames ?? [:]
            self.mappedTypeNames = schemes?.mappedTypeNames ?? [:]
        }
    }

    init(_ options: GenerateOptionsScheme = .init()) {
        self.access = options.access ?? "public"
        self.isGeneratingComments = options.isGeneratingComments ?? true
        self.isGeneratingEnums = options.isGeneratingEnums ?? true
        self.isGeneratingSwiftyBooleanPropertyNames = options.isGeneratingSwiftyBooleanPropertyNames ?? true
        self.isInliningPrimitiveTypes = options.isInliningPrimitiveTypes ?? true
        self.isReplacingCommongAbbreviations = options.isReplacingCommongAbbreviations ?? true
        self.schemes = SchemesOptions(options.schemes)
    }
}

final class GenerateOptionsScheme: Decodable {
    var access: String?
    var isGeneratingComments: Bool?
    var isGeneratingEnums: Bool?
    var isGeneratingSwiftyBooleanPropertyNames: Bool?
    var isInliningPrimitiveTypes: Bool?
    var isReplacingCommongAbbreviations: Bool?
    var schemes: SchemesOptions?
    
    struct SchemesOptions: Codable {
        var isGeneratingStructs: Bool?
        var entitiesGeneratedAsClasses: [String]?
        var entitiesGeneratedAsStructs: [String]?
        var isGeneratingInitWithCoder: Bool?
        var baseClass: String?
        var adoptedProtocols: [String]?
        var mappedPropertyNames: [String: String]?
        var mappedTypeNames: [String: String]?
    }
}

struct GenerateArguments {
    let isVerbose: Bool
    let isParallel: Bool
    let vendor: String?
}
