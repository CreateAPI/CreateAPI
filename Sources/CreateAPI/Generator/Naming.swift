// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation

/// A valid declaration name.
protocol DeclarationName: CustomStringConvertible {}

/// A camel-case  type name (or type identifier)
///
/// Using these types add type-safety and allows the client to avoid redundant computations.
struct TypeName: CustomStringConvertible, Hashable, DeclarationName {
    let rawValue: String
        
    init(processing rawValue: String, options: GenerateOptions) {
        self.rawValue = rawValue.process(isProperty: false, options: options)
    }

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    var description: String { rawValue }
    
    // Appends the name without re-doing most of the processing.
    func appending(_ text: String) -> TypeName {
        TypeName(rawValue + text)
    }
        
    func namespace(_ namespace: String?) -> TypeName {
        TypeName(rawValue.namespace(namespace))
    }
}

/// A property/parameter name in a camel-case format, e.g. `gistsURL`.
///
/// If the name matches one of the Swift keywords, it's automatically escaped.
struct PropertyName: CustomStringConvertible, Hashable, DeclarationName {
    let rawValue: String
    
    init(processing rawValue: String, options: GenerateOptions) {
        self.rawValue = rawValue.process(isProperty: true, options: options)
    }
    
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    var description: String { rawValue }
    
    /// Creates a Swifty property name, e.g. "finished" becomes "isFinished".
    func asBoolean(_ options: GenerateOptions) -> PropertyName {
        var string = rawValue.trimmingCharacters(in: CharacterSet.ticks)
        let words = string.words
        guard !words.isEmpty else {
            return self
        }
        if words.contains(where: booleanExceptions.contains) {
            return self
        }
        let first = words[0]
        if options.allAcronyms.contains(first.lowercased()) {
            string.removeFirst(first.count)
            string = first.uppercased() + string
        }
        return PropertyName("is" + string.capitalizingFirstLetter())
    }
    
    // TODO: Adopt this everywhere when it's needed
    
    // For use when accessing the property:
    //
    //    self.default = 1
    //
    // Ticks are not needed for most keywords, but there are exceptions.
    var accessor: String {
        if rawValue != "`self`" { // Most names are allowed, but not all
            return rawValue.trimmingCharacters(in: CharacterSet.ticks)
        }
        return rawValue
    }
}

struct ModuleName: CustomStringConvertible {
    let rawValue: String
        
    init(processing rawValue: String) {
        self.rawValue = rawValue.replacingOccurrences(of: "-", with: "_")
    }
    
    var description: String {
        rawValue
    }
}

extension String {
    // Returns separate words in a camelCase strings
    var words: [String] {
        // TODO: Refactor (not sure it's correct either)
        var output: [String] = []
        var remainig = self[...]
        while let index = remainig.firstIndex(where: { $0.isUppercase }) {
            output.append(String(remainig[..<index]))
            if !remainig.isEmpty {
                let start = remainig.startIndex
                remainig.replaceSubrange(start...start, with: remainig[start].lowercased())
            }
            remainig = remainig[index...]
        }
        if !remainig.isEmpty {
            output.append(String(remainig))
        }
        return output.filter { !$0.isEmpty } // TODO: refactor
    }
    
    var sanitized: String {
        if let replacement = replacements[self] {
            return replacement
        }
        if last == ">" {
            return "\(dropLast())GreaterThan"
        }
        if last == "<" {
            return "\(dropLast())LessThan"
        }
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
        if capitilizedKeywords.contains(self) {
            return "`\(self)`"
        }
        return self
    }

    func process(isProperty: Bool, options: GenerateOptions) -> String {
        // Special-case: remove `'` from words like "won't"
        var components = sanitized.replacingOccurrences(of: "'", with: "")
            .components(separatedBy: badCharacters)
        // If all letters are uppercased (but skip one-letter words)
        if !components.contains(where: { $0.count > 1 && $0.contains(where: { $0.isLowercase }) }) {
            components = components.map { $0.lowercased() }
        }
        // To camelCase
        var output = components
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, string in
                if (isProperty && index == 0) {
                    return string.lowercasedFirstLetter()
                }
                return string.capitalizingFirstLetter()
            }
            .joined(separator: "")
        guard let first = output.first else {
            return output
        }
        // Make sure it starts with a valid chatecter, e.g. "213List" doesn't pass.
        if !CharacterSet(charactersIn: String(first)).isSubset(of: .letters) {
            // Disambiguate between types and properties
            output = (isProperty ? "_" : "__") + output
        }
        // Replace abbreviations (but only at code boundries)
        // WARNING: Depends on isProperty and first lowercase letter (implementation detail)
        // TODO: Refactor
        if options.isReplacingCommonAcronyms {
            for acronym in options.allAcronyms {
                if let range = output.range(of: acronym.capitalizingFirstLetter()),
                   (range.upperBound == output.endIndex || output[range.upperBound].isUppercase || output[range.upperBound] == "s") {
                    output.replaceSubrange(range, with: acronym.uppercased())
                }
                if isProperty {
                    if let range = output.lowercased().range(of: acronym), range.lowerBound == output.startIndex {
                        output.replaceSubrange(range, with: acronym)
                    }
                }
            }
        }
        if output == "self" {
            output = "this" // Otherwise it'll mess-up initializers
        }
        
        output = isProperty ? output.escapedPropertyName : output.escapedTypeName
        return output
    }
    

}

// TODO: Expand this to work with multiple characters
func sanitizeEnumCaseName(_ string: String) -> String {
    if string.count == 1 &&
        !(string.unicodeScalars.count == 1 && Character(string).isNumber),
        string.unicodeScalars.allSatisfy({ $0.properties.isEmoji }) {
        return string.unicodeScalars
            .map { $0.properties.name }
            .compactMap { $0 }
            .joined(separator: "")
    }
    return string
}

// We can't list everything, but these are the most common words
private let booleanExceptions = Set(["is", "has", "have", "allow", "allows", "enable", "enables", "require", "requires", "delete", "deletes", "can", "should", "use", "uses", "contain", "contains", "dismiss", "dismisses", "respond", "responds", "exclude", "excludes", "lock", "locks", "was", "were", "enforce", "enforces", "resolve", "resolves"])

private let keywords = Set(["func", "public", "private", "open", "fileprivate", "internal", "default", "import", "init", "deinit", "typealias", "let", "var", "in", "return", "for", "switch", "where", "associatedtype", "guard", "enum", "struct", "class", "protocol", "extension", "if", "else", "self", "none", "throw", "throws", "rethrows", "inout", "operator", "static", "subscript", "case", "break", "continue", "defer", "do", "fallthrough", "repeat", "while", "as", "some", "super", "catch", "false", "true", "is", "nil", "try"])

private let capitilizedKeywords = Set(["Self", "Type", "Protocol", "Any", "AnyObject"])

// In reality, no one should be using case names like this.
private let replacements: [String: String] = [
    "=": "equal",
    "!=": "notEqual",
    ">=": "greaterThanOrEqualTo",
    "<=": "lessThanOrEqualTo",
    ">": "greaterThan",
    "<": "lessThan",
    "$": "dollar",
    "%": "percent",
    "#": "hash",
    "@": "alpha",
    "&": "and",
    "+": "plus",
    "\"": "backslash",
    "/": "slash",
    "~": "tilda",
    "~=": "tildaEqual"
]

private let badCharacters = CharacterSet.alphanumerics.inverted

extension CharacterSet {
    static let ticks = CharacterSet(charactersIn: "`")
}
