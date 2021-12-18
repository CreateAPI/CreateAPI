// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation

// TODO: When parsing additionalProperties remove known keys
final class Templates {
    let options: GenerateOptions
    
    var access: String { options.access.isEmpty ? "" :  options.access + " " }
    
    init(options: GenerateOptions) {
        self.options = options
    }

    // MARK: Entity
    
    /// Generates an entity declaration:
    ///
    ///     public struct <name>: Decodable {
    ///         <contents>
    ///     }
    func entity(name: TypeName, contents: [String], protocols: Protocols) -> String {
        let isStruct = (options.entities.isGeneratingStructs && !options.entities.entitiesGeneratedAsClasses.contains(name.rawValue)) || (options.entities.entitiesGeneratedAsStructs.contains(name.rawValue))
        let type = isStruct ? "struct" : (options.entities.isMakingClassesFinal ? "final class" : "class")
        let lhs = [options.access, type, name.rawValue]
            .compactMap { $0 }.joined(separator: " ")
        let rhs = ([isStruct ? nil : options.entities.baseClass] + protocols.sorted())
            .compactMap { $0 }.joined(separator: ", ")

        let declaration = rhs.isEmpty ? lhs : "\(lhs): \(rhs)"
        
        return """
        \(declaration) {
        \(contents.joined(separator: "\n\n").indented)
        }
        """
    }
    
    func codingKeys(for properties: [Property]) -> String? {
        guard properties.contains(where: { $0.name.rawValue != $0.key }) else {
            return nil
        }
        let cases: [String] = properties.map {
            if $0.name.rawValue == $0.key {
                return "case \($0.name)"
            } else {
                return "case \($0.name) = \"\($0.key)\""
            }
        }
        return """
        private enum CodingKeys: String, CodingKey {
        \(cases.joined(separator: "\n").indented)
        }
        """
    }
    
    // MARK: Enum
    
    func enumOneOf(name: TypeName, contents: [String], protocols: Protocols) -> String {
        return """
        \(access)enum \(name): \(protocols.sorted().joined(separator: ", ")) {
        \(contents.joined(separator: "\n\n").indented)
        }
        """
    }
        
    func `case`(property: Property) -> String {
        "case \(property.name)(\(property.type))"
    }
    
    func `case`(name: String, value: String) -> String {
        if name.trimmingCharacters(in: CharacterSet.ticks) != value {
            return "case \(name) = \"\(value)\""
        } else {
            return "case \(name)"
        }
    }
    
    func enumOfStrings(name: TypeName, contents: String) -> String {
        return """
        \(access)enum \(name): String, Codable, CaseIterable {
        \(contents.indented)
        }
        """
    }
    
    // MARK: Query Parameters
    
    func asQuery(properties: [Property]) -> String {
        """
        \(access)func asQuery() -> [(String, String?)] {
        \(asQueryContents(properties: properties).indented)
        }
        """
    }
        
    func asQueryContents(properties: [Property]) -> String {
        let statements: [String] = properties.map {
            let prefix = $0.name.rawValue == "query" ? "self." : ""
            if case .array = $0.type {
                if $0.explode {
                    return """
                    for value in \(prefix)\($0.name)\($0.isOptional ? " ?? []" : "") {
                        query.addQueryItem(\"\($0.key)\", value.asQueryValue)
                    }
                    """
                } else {
                    return "query.addQueryItem(\"\($0.key)\", \(prefix)\($0.name)\($0.isOptional ? "?" : "").map(\\.asQueryValue).joined(separator: \",\"))"
                }
            } else {
                return "query.addQueryItem(\"\($0.key)\", \(prefix)\($0.name)\($0.isOptional ? "?" : "").asQueryValue)"
            }
        }
        return """
        var query: [(String, String?)] = []
        \(statements.joined(separator: "\n"))
        return query
        """
    }
    
    /// Example:
    ///
    ///     private func makeGetQuery(_ perPage: Int?, _ page: Int?) -> [(String, String?)] {
    ///         [("per_page", perPage?.asQueryValue), ("page", page?.asQueryValue)]
    ///     }
    func asQueryInline(method: String, properties: [Property]) -> String {
        let arguments = properties.map { "_ \($0.name): \($0.type)\($0.isOptional ? "?" : "")" }.joined(separator: ", ")
        return """
        private func make\(method.capitalizingFirstLetter())Query(\(arguments)) -> [(String, String?)] {
        \(asQueryContents(properties: properties).indented)
        }
        """
    }

    // MARK: Init
    
    func initializer(properties: [Property]) -> String {
        guard !properties.isEmpty else {
            return "public init() {}"
        }
        let statements = properties.map {
            "self.\($0.name.accessor) = \($0.name)"
        }.joined(separator: "\n")
        let arguments = properties.map {
            "\($0.name): \($0.type)\($0.isOptional ? "? = nil" : "")"
        }.joined(separator: ", ")
        return """
        \(access)init(\(arguments)) {
        \(statements.indented)
        }
        """
    }
    
    // MARK: Decodable
    
    func decode(properties: [Property]) -> String {
        properties.map(decode).joined(separator: "\n")
    }
    
    /// Generates a decode statement.
    ///
    ///     self.id = values.decode(Int.self, forKey: "id")
    func decode(property: Property) -> String {
        let decode = property.isOptional ? "decodeIfPresent" : "decode"
        return "self.\(property.name.accessor) = try values.\(decode)(\(property.type).self, forKey: \"\(property.key)\")"
    }
    
    /// Generated decoding of the directly inlined nested object.
    ///
    ///     self.animal = try Animal(from: decoder)
    func decodeFromDecoder(property: Property) -> String {
        "self.\(property.name.accessor) = try \(property.type)(from: decoder)"
    }
    
    func initFromDecoder(properties: [Property]) -> String {
        initFromDecoder(contents: decode(properties: properties))
    }
    
    func initFromDecoder(contents: String) -> String {
        """
        \(access)init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: StringCodingKey.self)
        \(contents.indented)
        }
        """
    }
    
    func initFromDecoderAnyOf(properties: [Property]) -> String {
        let contents = properties.map {
            "self.\($0.name.accessor) = try? container.decode(\($0.type).self)"
        }.joined(separator: "\n")
        return """
        \(access)init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
        \(contents.indented)
        }
        """
    }
    
    func initFromDecoderOneOf(properties: [Property]) -> String {
        var statements = ""
        for property in properties {
            statements += """
            if let value = try? container.decode(\(property.type).self) {
                self = .\(property.name)(value)
            } else
            """
            statements += " "
        }
        
        statements += """
        {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Failed to intialize `oneOf`")
        }
        """
        
        return """
        \(access)init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
        \(statements.indented)
        }
        """
    }
    
    func encodeOneOf(properties: [Property]) -> String {
        let statements = properties.map {
            "case .\($0.name)(let value): try container.encode(value)"
        }
        return """
        \(access)func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
        \(statements.joined(separator: "\n").indented)
            }
        }
        """
    }
    
    // MARK: Encodable
    
    func encode(properties: [Property]) -> String {
        let contents = properties.map {
            let encode = $0.isOptional ? "encodeIfPresent" : "encode"
            return "try values.\(encode)(\($0.name), forKey: \"\($0.key)\")"
        }.joined(separator: "\n")
        
        return """
        \(access)func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: StringCodingKey.self)
        \(contents.indented)
        }
        """
    }
    
    // MARK: Properties
    
    /// Generates a list of properties.
    func properties(_ properties: [Property]) -> String {
        properties.map(property).joined(separator: "\n")
    }
    
    /// Generates a property with comments and everything.
    ///
    ///     public var files: [Files]?
    func property(_ property: Property) -> String {
        var output = ""
        if let metadata = property.metadata {
            output += comments(for: metadata, name: property.name.rawValue, isProperty: true)
        }
        output += "\(access)var \(property.name): \(property.type)\(property.isOptional ? "?" : "")"
        return output
    }
    
    // MARK: Typealias
    
    func `typealias`(name: DeclarationName, type: DeclarationName) -> String {
        "\(access)typealias \(name) = \(type)"
    }
    
    // MARK: Comments
    
    /// Generates inline comments for a declaration containing a title, description, and examples.
    func comments(for metadata: DeclarationMetadata, name: String, isProperty: Bool = false) -> String {
        let options = options.comments
        guard options.isEnabled else {
            return ""
        }
        var output = ""
        
        var title = metadata.title ?? ""
        var description = metadata.description ?? ""
        if title == description && options.isAddingTitles && options.isAddingDescription {
            description = ""
        }
        if title.components(separatedBy: .whitespaces).joined(separator: "").caseInsensitiveCompare(name) == .orderedSame {
            title = ""
        }
        
        if options.isAddingTitles, !title.isEmpty {
            let title = options.isCapitalizationEnabled ? title.capitalizingFirstLetter() : title
            output += "/// \(title)\n"
        }
        if options.isAddingDescription, !description.isEmpty, description != metadata.title {
            if !output.isEmpty {
                output += "///\n"
            }
            let description = options.isCapitalizationEnabled ? description.capitalizingFirstLetter() : description
            for line in description.lines {
                output += "/// \(line)\n"
            }
        }
        if options.isAddingExamples, let example = metadata.example?.value {
            let value: String
        
            if let example = example as? String, !example.hasPrefix("\"") {
                value = "\"\(example)\""
            } else if let example = example as? Array<String> {
                value = "\(example)"
            } else if let example = example as? Array<Int> {
                value = "\(example)"
            } else if let example = example as? Array<Bool> {
                value = "\(example)"
            } else if JSONSerialization.isValidJSONObject(example) {
                let data = try? JSONSerialization.data(withJSONObject: example, options: [.prettyPrinted, .sortedKeys])
                value = String(data: data ?? Data(), encoding: .utf8) ?? ""
            } else {
                value = "\(example)"
            }
            if value.count > 1 { // Only display if it's something substantial
                if !output.isEmpty {
                    output += "///\n"
                }
                let lines = value.lines
                if lines.count == 1 {
                    output += "/// Example: \(value)\n"
                } else {
                    output += "/// Example:\n///\n"
                    for line in lines {
                        output += "/// \(line)\n"
                    }
                }
            }
        }
        if options.isAddingExternalDocumentation, let docsURL = metadata.externalDocsURL {
            if !output.isEmpty {
                output += "///\n"
            }
            // I tried to use `seealso`, but Xcode doesn't render it
            output += "/// [\(metadata.externalDocsDescription ?? "External Documentation")](\(docsURL.absoluteString))\n"
        }
        if self.options.isAddingDeprecations, metadata.isDeprecated {
            // We can't mark properties deprecated because then initialier and
            // encoder will start throwing warnings.
            if isProperty {
                if !output.isEmpty {
                    output += "///\n"
                }
                output += "/// - warning: Deprecated.\n"
            } else {
                output += deprecated
            }
        }
        return output
    }
    
    // MARK: Method

    func methodOrProperty(name: String, parameters: [String] = [], returning type: String, contents: String) -> String {
        if parameters.isEmpty && options.paths.isUsingPropertiesForMethodsWithNoArguments {
            return property(name: name, returning: type, contents: contents)
        } else {
            return method(name: name, parameters: parameters, returning: type, contents: contents)
        }
    }
    
    func method(name: String, parameters: [String] = [], returning type: String, contents: String) -> String {
        """
        \(access)func \(name)(\(parameters.joined(separator: ", "))) -> \(type) {
        \(contents.indented)
        }
        """
    }
    
    func property(name: String, returning type: String, contents: String) -> String {
        """
        \(access)var \(name): \(type) {
        \(contents.indented)
        }
        """
    }
    
    // MARK: Headers

    func headers(name: String, contents: String) -> String {
        """
        \(access)enum \(name) {
        \(contents.indented)
        }
        """
    }
    
    func header(for property: Property, header: OpenAPI.Header) -> String {
        var name = property.name.rawValue
        if (property.key.hasPrefix("x-") || property.key.hasPrefix("X-")) {
            name = PropertyName(processing: String(property.key.dropFirst(2)), options: options).rawValue
        }
        var output = ""
        if options.comments.isEnabled, options.comments.isAddingDescription,
           let description = header.description, !description.isEmpty {
            let description = options.comments.isCapitalizationEnabled ? description.capitalizingFirstLetter() : description
            for line in description.lines {
                output += "/// \(line)\n"
            }
        }
        if options.isAddingDeprecations, header.deprecated {
            output += deprecated
        }
        output += """
        \(access)static let \(name) = HTTPHeader<\(property.type)>(field: \"\(property.key)\")
        """
        return output
    }
    
    // MARK: Paths
    
    func pathEntity(name: String, subpath: String, operations: [String]) -> String {
        let contents = ["""
        /// Path: `\(subpath)`
        \(access)let path: String
        """] + operations
        return """
        \(access)struct \(name) {
        \(contents.joined(separator: "\n\n").indented)
        }
        """
    }
    
    func pathExtension(of extensionOf: String, component: String, type: TypeName, isTopLevel: Bool, parameter: PathParameter?, contents: String) -> String {
        let stat = isTopLevel ? "static " : ""
        if let parameter = parameter {
            let componentWithId = component.replacingOccurrences(of: "{\(parameter.key)}", with: "\\(" + parameter.name.rawValue + ")")
            let path = #""\(path)/"# + componentWithId + "\""
            return """
            extension \(extensionOf) {
                \(access)\(stat)func \(parameter.name)(_ \(parameter.name): \(parameter.type)) -> \(type) {
                    \(type)(path: \(path))
                }
            
            \(contents.indented)
            }
            """
        } else {
            return """
            extension \(extensionOf) {
                \(access)\(stat)var \(PropertyName(processing: type.rawValue, options: options)): \(type) {
                    \(type)(path: \(isTopLevel ? "\"/\(component)\"" : ("path + \"/\(component)\"")))
                }
            
            \(contents.indented)
            }
            """
        }
    }
    
    // MARK: Misc
    
    func namespace(_ name: String) -> String {
        "\(access)enum \(name) {}"
    }
        
    var deprecated: String {
        #"@available(*, deprecated, message: "Deprecated")"# + "\n"
    }
    
    var requestOperationIdExtension: String {
       """
       extension Request {
           private func id(_ id: String) -> Request {
               var copy = self
               copy.id = id
               return copy
           }
       }
       """
    }
    
    func queryParameterEncoders(_ encoders: [String: String]) -> String {
        var declarations = encoders.keys.sorted().map { key in
            """
            extension \(key) {
                var asQueryValue: String {
            \(encoders[key]!.indented(count: 2))
                }
            }
            """
        }
        // Encoding RawRepresentable
        declarations.append("""
        extension RawRepresentable where RawValue == String {
            var asQueryValue: String {
                rawValue
            }
        }
        """)
        declarations.append("""
        extension Array where Element == (String, String?) {
            mutating func addQueryItem(_ name: String, _ value: String?) {
                guard let value = value, !value.isEmpty else { return }
                append((name, value))
            }
        }
        """)
        return declarations.joined(separator: "\n\n")
    }
    
    var anyJSON: String {
        """
        \(access)enum AnyJSON: Equatable, Codable {
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

            \(access)func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case let .array(array): try container.encode(array)
                case let .object(object): try container.encode(object)
                case let .string(string): try container.encode(string)
                case let .number(number): try container.encode(number)
                case let .bool(bool): try container.encode(bool)
                }
            }

            \(access)init(from decoder: Decoder) throws {
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
        """
    }
}

extension RawRepresentable where RawValue == String {
    var asQueryValue: String {
        rawValue
    }
}

extension String {
    var indented: String {
        indented(count: 1)
    }
    
    func indented(count: Int) -> String {
        lines
            .map { $0.isEmpty ? $0 : String(repeating: " ", count: count * 4) + $0 }
            .joined(separator: "\n")
    }
}

extension String {
    // Unlike `components(separatedBy: "\n")`, it keeps empty lines.
    var lines: [String] {
        var lines: [String] = []
        var index = startIndex
        while let newLineIndex = self[index...].firstIndex(of: "\n") {
            lines.append(String(self[index..<newLineIndex]))
            index = self.index(after: newLineIndex)
        }
        lines.append(String(self[index...]))
        return lines
    }
}

let stringCodingKey = """
struct StringCodingKey: CodingKey, ExpressibleByStringLiteral {
    private let string: String
    private var int: Int?

    var stringValue: String { return string }

    init(string: String) {
        self.string = string
    }

    init?(stringValue: String) {
        self.string = stringValue
    }

    var intValue: Int? { return int }

    init?(intValue: Int) {
        self.string = String(describing: intValue)
        self.int = intValue
    }

    init(stringLiteral value: String) {
        self.string = value
    }
}
"""
