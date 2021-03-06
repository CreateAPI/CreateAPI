// Generated by Create API
// https://github.com/CreateAPI/CreateAPI
//
// swiftlint:disable all

import Foundation
import Get

extension Paths {
    public static var collections: Collections {
        Collections(path: "/api/collections")
    }

    public struct Collections {
        /// Path: `/api/collections`
        public let path: String

        /// All Collections
        ///
        /// Returns an array of all Collection models in display order.
        public var get: Request<[cookpad.Collection]> {
            .get(path)
        }
    }
}

extension Paths.Collections {
    public func id(_ id: Int) -> WithID {
        WithID(path: "\(path)/\(id)")
    }

    public struct WithID {
        /// Path: `/api/collections/{id}`
        public let path: String

        /// Find a Collection by ID
        ///
        /// Returns a single Collection model associated with the given identifier.
        public var get: Request<cookpad.Collection> {
            .get(path)
        }
    }
}

extension Paths.Collections.WithID {
    public var recipes: Recipes {
        Recipes(path: path + "/recipes")
    }

    public struct Recipes {
        /// Path: `/api/collections/{id}/recipes`
        public let path: String

        /// Find Recipes in a Collection
        ///
        /// Returns an ordered array of Recipe models in the given Collection.
        public var get: Request<[cookpad.Recipe]> {
            .get(path)
        }
    }
}

extension Paths {
    public static var recipes: Recipes {
        Recipes(path: "/api/recipes")
    }

    public struct Recipes {
        /// Path: `/api/recipes`
        public let path: String

        /// All Recipes
        ///
        /// Returns an array of all Recipe models in order of most recently published.
        public var get: Request<[cookpad.Recipe]> {
            .get(path)
        }
    }
}

extension Paths.Recipes {
    public func id(_ id: Int) -> WithID {
        WithID(path: "\(path)/\(id)")
    }

    public struct WithID {
        /// Path: `/api/recipes/{id}`
        public let path: String

        /// Find a Recipe by ID
        ///
        /// Returns a specific Recipe model with the given identifier.
        public var get: Request<cookpad.Recipe> {
            .get(path)
        }
    }
}

public enum Paths {}
