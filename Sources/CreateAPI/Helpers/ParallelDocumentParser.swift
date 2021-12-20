// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import OpenAPIKit30

// Experimental. This only seems to work with YAML and crashes with JSONDecoder.
// But for YAML, you get a solid x2 speed boost.
final class ParallelDocumentParser: Decodable {
    let document: OpenAPI.Document
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let version = try container.decode(OpenAPI.Document.Version.self, forKey: .openAPIVersion)
        let info = try container.decode(OpenAPI.Document.Info.self, forKey: .info)
        
        let group = DispatchGroup()
        
        var components: Result<OpenAPI.Components, Error>!
        perform(in: group) {
            components = Result(catching: { try container.decodeIfPresent(OpenAPI.Components.self, forKey: .components) ?? .noComponents })
        }
        
        var paths: Result<OpenAPI.PathItem.Map, Error>!
        perform(in: group) {
            paths = Result(catching: { try container.decode(OpenAPI.PathItem.Map.self, forKey: .paths) })
        }

        group.wait()

        // Skip fields that we don't need for code generation

        self.document = OpenAPI.Document(
            openAPIVersion: version,
            info: info,
            servers: [],
            paths: try paths.get(),
            components: try components.get(),
            security: [],
            tags: nil,
            externalDocs: nil,
            vendorExtensions: [:]
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case openAPIVersion = "openapi"
        case info
        case paths
        case components
    }
}

private final class ResultBox<T> {
    var value: Result<T, Error>!
    
    func get() throws -> T {
        try value.get()
    }
}

private func perform(in group: DispatchGroup, _ closure: @escaping () -> Void) {
    group.enter()
    DispatchQueue.global().async {
        closure()
        group.leave()
    }
}
