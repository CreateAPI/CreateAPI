// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import OpenAPIKit30

/// A camel-case  type name.
///
/// Using these types add type-safety and allows the client to avoid redundant computations.
struct TypeName: CustomStringConvertible {
    let rawValue: String
    
    init(_ key: OpenAPI.ComponentKey) {
        self.init(key.rawValue)
    }
    
    init(_ rawValue: String) {
        self.rawValue = rawValue.toCamelCase.escapedTypeName
    }

    private init(processedRawValue: String) {
        self.rawValue = processedRawValue
    }

    var description: String { rawValue }
    
    // Appends the name without re-doing most of the processing.
    func appending(_ text: String) -> TypeName {
        TypeName(processedRawValue: rawValue + text)
    }
}

/// A property/parameter name in a camel-case format, e.g. `gistsURL`.
///
/// If the name matches one of the Swift keywords, it's automatically escaped.
struct PropertyName: CustomStringConvertible {
    let rawValue: String
    
    init(_ rawValue: String) {
        self.rawValue = rawValue.sanitized.toCamelCase.lowercasedFirstLetter().escapedPropertyName
    }
    
    var description: String { rawValue }
}

private extension String {
    var sanitized: String {
        if first == "+" {
            return "plus\(dropFirst())"
        }
        if first == "-" {
            return "minus\(dropFirst())"
        }
        return self
    }
    
    var escapedPropertyName: String {
        guard keywords.contains(self.lowercased()) else { return self }
        return "`\(self)`"
    }
    
    var escapedTypeName: String {
        if self == "Self" {
            return "`Self`"
        }
        return self
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
    
    func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }

    func lowercasedFirstLetter() -> String {
        prefix(1).lowercased() + dropFirst()
    }
}

extension String {
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

private let badCharacters = CharacterSet.alphanumerics.inverted

func concurrentPerform<T>(on array: [T], _ work: (Int, T) -> Void) {
    let coreCount = suggestedCoreCount
    let iterations = array.count > (coreCount * 2) ? coreCount : 1
    
    DispatchQueue.concurrentPerform(iterations: iterations) { index in
        let start = index * array.indices.count / iterations
        let end = (index + 1) * array.indices.count / iterations
        for index in start..<end {
            work(index, array[index])
        }
    }
}

// TODO: Find a better way to do concurrent perform.
var suggestedCoreCount: Int {
    ProcessInfo.processInfo.processorCount
}

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

let stringCodingKey = """
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
"""
