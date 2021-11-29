// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

final class GenerateOptions {
    var access: String
    var schemes: Schemes
    
    struct Schemes {
        var isGeneratingStructs: Bool
        // TODO: Implement baseClass and adoptedProtocols
        var baseClass: String?
        var adoptedProtocols: [String]
        
        init(_ schemes: GenerateOptionsScheme.Schemes?) {
            self.isGeneratingStructs = schemes?.isGeneratingStructs ?? true
            self.baseClass = schemes?.baseClass
            self.adoptedProtocols = schemes?.adoptedProtocols ?? ["Decodable"]
        }
    }
    
    init(_ options: GenerateOptionsScheme = .init()) {
        self.access = options.access ?? "public"
        self.schemes = Schemes(options.schemes)
    }
}

final class GenerateOptionsScheme: Decodable {
    var access: String?
    var schemes: Schemes?

    struct Schemes: Codable {
        var isGeneratingStructs: Bool?
        var baseClass: String?
        var adoptedProtocols: [String]?
    }
}
