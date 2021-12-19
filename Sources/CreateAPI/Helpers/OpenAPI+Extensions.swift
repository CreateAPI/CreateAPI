// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import OpenAPIKit30

extension Either where A == JSONReference<OpenAPI.Parameter>, B == OpenAPI.Parameter {
    func unwrapped(in spec: OpenAPI.Document) throws -> OpenAPI.Parameter {
        switch self {
        case .a(let reference):
            return try reference.dereferenced(in: spec.components).underlyingParameter
        case .b(let value):
            return value
        }
    }
}

extension Either where A == JSONReference<OpenAPI.Request>, B == OpenAPI.Request {
    func unwrapped(in spec: OpenAPI.Document) throws -> OpenAPI.Request {
        switch self {
        case .a(let reference):
            guard let name = reference.name else {
                throw GeneratorError("Inalid reference")
            }
            guard let key = OpenAPI.ComponentKey(rawValue: name), let request = spec.components.requestBodies[key] else {
                throw GeneratorError("Failed to find a requesty body named \(name)")
            }
            return request
        case .b(let request):
            return request
        }
    }
}

extension OpenAPI.Parameter {
    func unwrapped(in spec: OpenAPI.Document) throws -> (JSONSchema, Bool) {
        let schema: JSONSchema
        var explode = true
        switch schemaOrContent {
        case .a(let schemaContext):
            explode = schemaContext.explode
            switch schemaContext.schema {
            case .a(let reference):
                schema = JSONSchema.reference(reference)
            case .b(let value):
                schema = value
            }
        case .b:
            throw GeneratorError("Parameter content map not supported for parameter: \(name)")
        }
        return (schema, explode)
    }
}

extension OpenAPI.PathItem {
    var allOperations: [(String, OpenAPI.Operation)] {
        [
            self.get.map { ("get", $0) },
            self.post.map { ("post", $0) },
            self.put.map { ("put", $0) },
            self.patch.map { ("patch", $0) },
            self.delete.map { ("delete", $0) },
            self.options.map { ("options", $0) },
            self.head.map { ("head", $0) },
            self.trace.map { ("trace", $0) },
        ].compactMap { $0 }
    }
}

extension JSONSchema {
    var isOptional: Bool {
        !self.required || self.nullable
    }
}
