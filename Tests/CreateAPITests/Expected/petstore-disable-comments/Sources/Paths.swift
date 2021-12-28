// Generated by Create API
// https://github.com/kean/CreateAPI
//
// swiftlint:disable all

import Foundation
import Get
import HTTPHeaders
import URLQueryEncoder

extension Paths {
    public static var pets: Pets {
        Pets(path: "/pets")
    }

    public struct Pets {
        /// Path: `/pets`
        public let path: String

        public func get(limit: Int? = nil) -> Request<[petstore_disable_comments.Pet]> {
            .get(path, query: makeGetQuery(limit))
        }

        public enum GetResponseHeaders {
            public static let next = HTTPHeader<String>(field: "x-next")
        }

        private func makeGetQuery(_ limit: Int?) -> [(String, String?)] {
            let encoder = URLQueryEncoder()
            encoder.encode(["limit": limit])
            return encoder.items
        }

        public var post: Request<Void> {
            .post(path)
        }
    }
}

extension Paths.Pets {
    public func petID(_ petID: String) -> WithPetID {
        WithPetID(path: "\(path)/\(petID)")
    }

    public struct WithPetID {
        /// Path: `/pets/{petId}`
        public let path: String

        public var get: Request<petstore_disable_comments.Pet> {
            .get(path)
        }
    }
}

public enum Paths {}
