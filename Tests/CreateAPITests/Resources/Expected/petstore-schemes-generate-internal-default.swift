// Auto-generated by [Create API](https://github.com/kean/CreateAPI).

// swiftlint:disable all

import Foundation

/// A pet title
///
/// A pet description
struct Pet: Decodable {
    var id: Int
    /// Example: Buddy
    var name: String
    var tag: String?

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decode(Int.self, forKey: "id")
        self.name = try values.decode(String.self, forKey: "name")
        self.tag = try values.decodeIfPresent(String.self, forKey: "tag")
    }
}

typealias Pets = Pet

struct Error: Decodable {
    var code: Int
    var message: String

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.code = try values.decode(Int.self, forKey: "code")
        self.message = try values.decode(String.self, forKey: "message")
    }
}

struct StringCodingKey: CodingKey, ExpressibleByStringLiteral {

    private let string: String
    private let int: Int?

    var stringValue: String { return string }

    init(string: String) {
        self.string = string
        int = nil
    }
    init?(stringValue: String) {
        string = stringValue
        int = nil
    }

    var intValue: Int? { return int }
    init?(intValue: Int) {
        string = String(describing: intValue)
        int = intValue
    }

    init(stringLiteral value: String) {
        string = value
        int = nil
    }
}