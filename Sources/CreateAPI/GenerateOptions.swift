// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

final class GenerateOptions {
    var access: String?
    var schemes: Schemes
    var generateComments: Bool
    
    struct Schemes {
        var isGeneratingStructs: Bool
        var isGeneratingInitWithCoder: Bool
        // TODO: Implement baseClass and adoptedProtocols
        var baseClass: String?
        var adoptedProtocols: [String]
        var isInliningPrimitiveTypes: Bool
        
        init(_ schemes: GenerateOptionsScheme.Schemes?) {
            self.isGeneratingStructs = schemes?.isGeneratingStructs ?? true
            self.isGeneratingInitWithCoder = schemes?.isGeneratingInitWithCoder ?? true
            self.baseClass = schemes?.baseClass
            self.adoptedProtocols = schemes?.adoptedProtocols ?? ["Decodable"]
            self.isInliningPrimitiveTypes = schemes?.isInliningPrimitiveTypes ?? true
        }
    }
    
    enum CodableGenerationStrategy: String {
        case customInit
        case codingKeys
    }
    
    init(_ options: GenerateOptionsScheme = .init()) {
        self.access = options.access ?? "public"
        self.generateComments = options.generateComments ?? true
        self.schemes = Schemes(options.schemes)
    }
}

final class GenerateOptionsScheme: Decodable {
    var access: String?
    var schemes: Schemes?
    var generateComments: Bool?

    struct Schemes: Codable {
        var isGeneratingStructs: Bool?
        var isGeneratingInitWithCoder: Bool?
        var baseClass: String?
        var adoptedProtocols: [String]?
        var isInliningPrimitiveTypes: Bool?
    }
}
