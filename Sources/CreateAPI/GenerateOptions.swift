// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

final class GenerateOptions {
    var access: String?
    var schemes: SchemesOptions
    var isGeneratingEnums: Bool
    var isGeneratingSwiftyBooleanPropertyNames: Bool
    var isInliningPrimitiveTypes: Bool
    var isReplacingCommonAcronyms: Bool
    var additionalAcronyms: [String]
    var fileHeader: FileHeader
    var comments: Comments

    struct FileHeader {
        var addSwiftLintDisabled: Bool
        var addGetImport: Bool
        var header: String?
        
        init(_ fileHeader: GenerateOptionsScheme.FileHeader?) {
            self.addSwiftLintDisabled = fileHeader?.addSwiftLintDisabled ?? true
            self.addGetImport = fileHeader?.addGetImport ?? true
            self.header = fileHeader?.header
        }
    }
    
    struct Comments {
        var isEnabled: Bool
        var addTitle: Bool
        var addDescription: Bool
        var addExamples: Bool
        var capitilizeTitle: Bool
        var capitilizeDescription: Bool
        
        init(_ comments: GenerateOptionsScheme.Comments?) {
            self.isEnabled = comments?.isEnabled ?? true
            self.addTitle = comments?.addTitle ?? true
            self.addDescription = comments?.addDescription ?? true
            self.addExamples = comments?.addExamples ?? true
            self.capitilizeTitle = comments?.capitilizeTitle ?? true
            self.capitilizeDescription = comments?.capitilizeDescription ?? true
        }
    }
    
    // TODO: Inline this?
    struct SchemesOptions {
        var isGeneratingStructs: Bool
        var entitiesGeneratedAsClasses: Set<String>
        var entitiesGeneratedAsStructs: Set<String>
        var isGeneratingInitWithCoder: Bool
        var baseClass: String?
        var adoptedProtocols: [String]
        // TODO: Move to separate "Rename" object
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
        self.isGeneratingEnums = options.isGeneratingEnums ?? true
        self.isGeneratingSwiftyBooleanPropertyNames = options.isGeneratingSwiftyBooleanPropertyNames ?? true
        self.isInliningPrimitiveTypes = options.isInliningPrimitiveTypes ?? true
        self.isReplacingCommonAcronyms = options.isReplacingCommonAcronyms ?? true
        self.additionalAcronyms = (options.additionalAcronyms ?? []).map { $0.lowercased() }
        self.schemes = SchemesOptions(options.schemes)
        self.fileHeader = FileHeader(options.fileHeader)
        self.comments = Comments(options.comments)
    }
}

final class GenerateOptionsScheme: Decodable {
    var access: String?
    var isGeneratingEnums: Bool?
    var isGeneratingSwiftyBooleanPropertyNames: Bool?
    var isInliningPrimitiveTypes: Bool?
    var isReplacingCommonAcronyms: Bool?
    var additionalAcronyms: [String]?
    var schemes: SchemesOptions?
    var fileHeader: FileHeader?
    var comments: Comments?
    
    struct FileHeader: Decodable {
        var addSwiftLintDisabled: Bool?
        var addGetImport: Bool?
        var header: String?
    }
    
    struct Comments: Decodable {
        var isEnabled: Bool?
        var addTitle: Bool?
        var addDescription: Bool?
        var addExamples: Bool?
        var capitilizeTitle: Bool?
        var capitilizeDescription: Bool?
    }
    
    struct SchemesOptions: Decodable {
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
