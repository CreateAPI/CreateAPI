// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import OpenAPIKit30

func makeType(_ string: String) -> String {
    let name = string.toCamelCase
    let output = string.isParameter ? "With\(name)" : name
    if output == "Self" {
        return "`Self`"
    }
    return output
}

func makeParameter(_ string: String) -> String {
    string.toCamelCase.lowercasedFirstLetter().escaped
}

extension String {
    var isParameter: Bool {
        starts(with: "{")
    }
    
    // Starting with capitalized first letter.
    var toCamelCase: String {
        var components = replacingOccurrences(of: "'", with: "")
            .components(separatedBy: badCharacters)
        if !components.contains(where: { $0.contains(where: { $0.isLowercase }) }) {
            components = components.map { $0.lowercased() }
        }
        return components
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, string in
                if index != 0 && abbreviations.contains(string.lowercased()) {
                    return string.uppercased()
                }
                return string.capitalizingFirstLetter()
            }
            .joined(separator: "")
    }
    
    func shiftedRight(count: Int) -> String {
        guard count > 0 else {
            return self
        }
        return components(separatedBy: "\n")
            .map { $0.isEmpty ? $0 : String(repeating: " ", count: count) + $0 }
            .joined(separator: "\n")
    }
}

private let keywords = Set(["public", "private", "open", "fileprivate", "default", "extension", "import", "init", "deinit", "typealias", "let", "var", "in", "return", "for", "switch", "enum", "struct", "class", "if", "self", "none"])

private let abbreviations = Set(["url", "id", "html", "ssl", "tls"])

extension String {
    var escaped: String {
        guard keywords.contains(self.lowercased()) else { return self }
        return "`\(self)`"
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }
}

extension String {
    func lowercasedFirstLetter() -> String {
        prefix(1).lowercased() + dropFirst()
    }
}

private let badCharacters = CharacterSet.alphanumerics.inverted

let anyJSON = """
public enum AnyJSON: Equatable {
    case string(String)
    case number(Double)
    case object([String: AnyJSON])
    case array([AnyJSON])
    case bool(Bool)
    
    var value: Any {
        switch self {
        case .string(let string): return string
        case .number(let double): return double
        case .object(let dictionary): return dictionary
        case .array(let array): return array
        case .bool(let bool): return bool
        }
    }
}

extension AnyJSON: Codable {
    public func encode(to encoder: Encoder) throws {

        var container = encoder.singleValueContainer()

        switch self {
        case let .array(array):
            try container.encode(array)
        case let .object(object):
            try container.encode(object)
        case let .string(string):
            try container.encode(string)
        case let .number(number):
            try container.encode(number)
        case let .bool(bool):
            try container.encode(bool)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let object = try? container.decode([String: AnyJSON].self) {
            self = .object(object)
        } else if let array = try? container.decode([AnyJSON].self) {
            self = .array(array)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
            )
        }
    }
}

extension AnyJSON: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .string(let str):
            return str.debugDescription
        case .number(let num):
            return num.debugDescription
        case .bool(let bool):
            return bool.description
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            return try! String(data: encoder.encode(self), encoding: .utf8)!
        }
    }
}
"""
