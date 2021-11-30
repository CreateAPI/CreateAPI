// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

final class GenerateOptions {
    var access: String?
    var isGeneratingComments: Bool
    var isGeneratingEnums: Bool
    var isInliningPrimitiveTypes: Bool
    var schemes: SchemesOptions
    
    struct SchemesOptions {
        var isGeneratingStructs: Bool
        var isGeneratingInitWithCoder: Bool
        var baseClass: String?
        var adoptedProtocols: [String]
        
        init(_ schemes: GenerateOptionsScheme.SchemesOptions?) {
            self.isGeneratingStructs = schemes?.isGeneratingStructs ?? true
            self.isGeneratingInitWithCoder = schemes?.isGeneratingInitWithCoder ?? true
            self.baseClass = schemes?.baseClass
            self.adoptedProtocols = schemes?.adoptedProtocols ?? ["Decodable"]
        }
    }
    
    enum CodableGenerationStrategy: String {
        case customInit
        case codingKeys
    }
    
    init(_ options: GenerateOptionsScheme = .init()) {
        self.access = options.access ?? "public"
        self.isGeneratingComments = options.isGeneratingComments ?? true
        self.isGeneratingEnums = options.isGeneratingEnums ?? true
        self.isInliningPrimitiveTypes = options.isInliningPrimitiveTypes ?? true
        self.schemes = SchemesOptions(options.schemes)
    }
}

final class GenerateOptionsScheme: Decodable {
    var access: String?
    var isGeneratingComments: Bool?
    var isGeneratingEnums: Bool?
    var isInliningPrimitiveTypes: Bool?
    var schemes: SchemesOptions?
    
    struct SchemesOptions: Codable {
        var isGeneratingStructs: Bool?
        var isGeneratingInitWithCoder: Bool?
        var baseClass: String?
        var adoptedProtocols: [String]?
    }
}
