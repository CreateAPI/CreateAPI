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
        components(separatedBy: badCharacters)
            .filter { !$0.isEmpty }
            .map { $0.capitalizingFirstLetter() }
            .joined(separator: "")
    }
}

private let keywords = Set(["public", "private", "open", "fileprivate", "default", "extension", "import", "init", "deinit", "typealias", "let", "var", "in", "return", "for", "switch", "enum", "struct", "class", "if", "self"])

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
