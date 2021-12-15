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
            components = Result(catching: { try container.decodeIfPresent(ParallelComponentsParser.self, forKey: .components)?.components ?? .noComponents })
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

// Experimental.
final class ParallelComponentsParser: Decodable {
    let components: OpenAPI.Components
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let group = DispatchGroup()
        var schemas: Result<OpenAPI.ComponentDictionary<JSONSchema>, Error>!
        perform(in: group) {
            schemas = Result(catching: { try container.decodeIfPresent(OpenAPI.ComponentDictionary<JSONSchema>.self, forKey: .schemas) ?? [:] })
        }
        
        var examples: Result<OpenAPI.ComponentDictionary<OpenAPI.Example>, Error>!
        perform(in: group) {
            examples = Result(catching: { try container.decodeIfPresent(OpenAPI.ComponentDictionary<OpenAPI.Example>.self, forKey: .examples)
                ?? [:] })
        }
        
        var parameters: Result<OpenAPI.ComponentDictionary<OpenAPI.Parameter>, Error>!
        var requestBodies: Result<OpenAPI.ComponentDictionary<OpenAPI.Request>, Error>!
        var responses: Result<OpenAPI.ComponentDictionary<OpenAPI.Response>, Error>!
        var headers: Result<OpenAPI.ComponentDictionary<OpenAPI.Header>, Error>!
        perform(in: group) {
            responses = Result(catching: { try container.decodeIfPresent(OpenAPI.ComponentDictionary<OpenAPI.Response>.self, forKey: .responses)
                ?? [:]})
            parameters = Result(catching: { try  container.decodeIfPresent(OpenAPI.ComponentDictionary<OpenAPI.Parameter>.self, forKey: .parameters)
                ?? [:] })
            requestBodies = Result(catching: { try container.decodeIfPresent(OpenAPI.ComponentDictionary<OpenAPI.Request>.self, forKey: .requestBodies)
                ?? [:] })
            headers = Result(catching: { try container.decodeIfPresent(OpenAPI.ComponentDictionary<OpenAPI.Header>.self, forKey: .headers)
                ?? [:] })
        }
        
        group.wait()
        
        self.components = OpenAPI.Components(
            schemas: try schemas.get(),
            responses: try responses.get(),
            parameters: try parameters.get(),
            examples: try examples.get(),
            requestBodies: try requestBodies.get(),
            headers: try headers.get(),
            securitySchemes: [:],
            callbacks: [:],
            vendorExtensions: [:]
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case schemas
        case responses
        case parameters
        case examples
        case requestBodies
        case headers
        case securitySchemes
        case links
        case callbacks
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
