// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

// TODO: Add an option to add spacing between properties with comments
// TODO: Add an option to generate parametes as `let` and a list of exceptions
final class GenerateOptions {
    var access: String
    var isRemovingUnneededImports: Bool
    var paths: Paths
    var schemes: SchemesOptions
    var isAddingDeprecations: Bool
    var isGeneratingEnums: Bool
    var isGeneratingSwiftyBooleanPropertyNames: Bool
    var isInliningPrimitiveTypes: Bool
    var isReplacingCommonAcronyms: Bool
    var additionalAcronyms: [String]
    var fileHeader: FileHeader
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
        var addSummary: Bool
        var isAddingExternalDocumentation: Bool
        var capitilizeTitle: Bool
        var capitilizeDescription: Bool
        
        init(_ comments: GenerateOptionsScheme.Comments?) {
            self.isEnabled = comments?.isEnabled ?? true
            self.addTitle = comments?.addTitle ?? true
            self.addDescription = comments?.addDescription ?? true
            self.addExamples = comments?.addExamples ?? true
            self.addSummary = comments?.addSummary ?? true
            self.isAddingExternalDocumentation = comments?.isAddingExternalDocumentation ?? true
            self.capitilizeTitle = comments?.capitilizeTitle ?? true
            self.capitilizeDescription = comments?.capitilizeDescription ?? true
        }
    }
    
    struct Paths {
        var namespace: String
        var isAddingResponseHeaders: Bool
        var isAddingOperationIds: Bool
        var imports: Set<String>
        
        init(_ paths: GenerateOptionsScheme.Paths?) {
            self.namespace = paths?.namespace ?? "Paths"
            self.isAddingResponseHeaders = paths?.isAddingResponseHeaders ?? true
            self.isAddingOperationIds = paths?.isAddingOperationIds ?? false
            self.imports = Set(paths?.imports ?? ["APIClient", "HTTPHeaders"])
        }
    }
    
    // TODO: Inline this?
    struct SchemesOptions {
        var isGeneratingStructs: Bool
        var entitiesGeneratedAsClasses: Set<String>
        var entitiesGeneratedAsStructs: Set<String>
        var isMakingClassesFinal: Bool
        var baseClass: String?
        var adoptedProtocols: Set<String>
        var isSkippingRedundantProtocols: Bool
        // TODO: simplify this
        var isGeneratingInitWithCoder: Bool
        var isGeneratingDecode: Bool
        // TODO: Move to separate "Rename" object
        var mappedPropertyNames: [String: String]
        var mappedTypeNames: [String: String] // Currently doesn't work for nested types
        
        init(_ schemes: GenerateOptionsScheme.SchemesOptions?) {
            self.isGeneratingStructs = schemes?.isGeneratingStructs ?? true
            self.entitiesGeneratedAsClasses = Set(schemes?.entitiesGeneratedAsClasses ?? [])
            self.entitiesGeneratedAsStructs = Set(schemes?.entitiesGeneratedAsStructs ?? [])
            self.isMakingClassesFinal = schemes?.isMakingClassesFinal ?? true
            self.baseClass = schemes?.baseClass
            self.isGeneratingInitWithCoder = schemes?.isGeneratingInitWithCoder ?? true
            self.isGeneratingDecode = schemes?.isGeneratingDecode ?? true
            self.adoptedProtocols = Set(schemes?.adoptedProtocols ?? ["Codable"])
            self.isSkippingRedundantProtocols = schemes?.isSkippingRedundantProtocols ?? true
            self.mappedPropertyNames = schemes?.mappedPropertyNames ?? [:]
            self.mappedTypeNames = schemes?.mappedTypeNames ?? [:]
        }
    }

    init(_ options: GenerateOptionsScheme = .init()) {
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
        self.schemes = SchemesOptions(options.schemes)
        self.fileHeader = FileHeader(options.fileHeader)
        self.comments = Comments(options.comments)
        self.indentation = options.indentation ?? .spaces
        self.spaceWidth = options.spaceWidth ?? 4
        self.isPluralizationEnabled = options.isPluralizationEnabled ?? true
        self.pluralizationExceptions = Set(options.pluralizationExceptions ?? [])
        self.isInterpretingEmptyObjectsAsDictionaries = options.isInterpretingEmptyObjectsAsDictionaries ?? false
    }
}

final class GenerateOptionsScheme: Decodable {
    var access: String?
    var isRemovingUnneededImports: Bool?
    var paths: Paths?
    var isAddingDeprecations: Bool?
    var isGeneratingEnums: Bool?
    var isGeneratingSwiftyBooleanPropertyNames: Bool?
    var isInliningPrimitiveTypes: Bool?
    var isReplacingCommonAcronyms: Bool?
    var additionalAcronyms: [String]?
    var schemes: SchemesOptions?
    var fileHeader: FileHeader?
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
    
    struct Comments: Decodable {
        var isEnabled: Bool?
        var addTitle: Bool?
        var addDescription: Bool?
        var addExamples: Bool?
        var addSummary: Bool?
        var isAddingExternalDocumentation: Bool?
        var capitilizeTitle: Bool?
        var capitilizeDescription: Bool?
    }
    
    struct Paths: Decodable {
        var namespace: String?
        var isAddingResponseHeaders: Bool?
        var isAddingOperationIds: Bool?
        var imports: [String]?
    }
    
    struct SchemesOptions: Decodable {
        var isGeneratingStructs: Bool?
        var entitiesGeneratedAsClasses: [String]?
        var entitiesGeneratedAsStructs: [String]?
        var isMakingClassesFinal: Bool?
        var baseClass: String?
        var adoptedProtocols: [String]?
        var isSkippingRedundantProtocols: Bool?
        var isGeneratingInitWithCoder: Bool?
        var isGeneratingDecode: Bool?
        var mappedPropertyNames: [String: String]?
        var mappedTypeNames: [String: String]?
    }
}

struct GenerateArguments {
    let isVerbose: Bool
    let isParallel: Bool
    let vendor: String?
    let module: String?
}
