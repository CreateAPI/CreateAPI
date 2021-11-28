// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

func makeType(_ string: String) -> String {
    let name = string.toCamelCase
    return string.isParameter ? "With\(name)" : name
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
        replacingOccurrences(of: "+", with: "Plus") // GitHub API uses these
            .replacingOccurrences(of: "-", with: "Minus")
            .components(separatedBy: badCharacters)
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, string in
                if index != 0 && alwaysUppercased.contains(string.lowercased()) {
                    return string.uppercased()
                }
                return string.capitalizingFirstLetter()
            }
            .joined(separator: "")
    }
    
    func shiftedRight(count: Int) -> String {
        components(separatedBy: "\n")
            .map { String(repeating: " ", count: count) + $0 }
            .joined(separator: "\n")
    }
}

private let keywords = Set(["public", "private", "open", "fileprivate", "default", "extension", "import", "init", "deinit", "typealias", "let", "var", "in", "return", "for", "switch", "enum", "struct", "class", "if", "self"])

private let alwaysUppercased = Set(["url", "id", "html"])

extension String {
    var escaped: String {
        guard keywords.contains(self) else { return self }
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