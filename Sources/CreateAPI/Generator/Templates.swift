// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation

// TODO: When parsing additionalProperties remove known keys
final class Templates {
    let options: GenerateOptions
    
    var access: String {
        guard let access = options.access, !access.isEmpty else { return "" }
        return access + " "
    }
    
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
        return isStruct ? self.struct(name: name, contents: contents, protocols: protocols) : self.class(name: name, contents: contents, protocols: protocols)
    }

    func `struct`(name: TypeName, contents: [String], protocols: Protocols) -> String {
        let lhs = [options.access, "struct", name.rawValue].compactMap { $0 }
        let rhs = protocols.sorted()
        return declaration(lhs: lhs, rhs: rhs, contents: contents)
    }
    
    func `class`(name: TypeName, contents: [String], protocols: Protocols) -> String {
        let type = options.entities.isMakingClassesFinal ? "final class" : "class"
        let lhs = [options.access, type, name.rawValue].compactMap { $0 }
        let rhs = ([options.entities.baseClass] + protocols.sorted()).compactMap { $0 }
        return declaration(lhs: lhs, rhs: rhs, contents: contents)
    }
    
    private func declaration(lhs: [String], rhs: [String], contents: [String]) -> String {
        let lhs = lhs.joined(separator: " ")
        let rhs = rhs.joined(separator: ", ")
        return """
        \(rhs.isEmpty ? lhs : "\(lhs): \(rhs)") {
        \(contents.joined(separator: "\n\n").indented)
        }
        """
    }
    
    func codingKeys(for properties: [Property]) -> String? {
        guard properties.contains(where: { $0.name.rawValue != $0.key }) else {
            return nil
        }
        let cases: [String] = properties.map { self.case(name: $0.name.rawValue, value: $0.key) }
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
            let value = value.isEscapingNeeded ? "#\"\(value)\"#" : "\"\(value)\""
            return "case \(name) = \(value)"
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
        \(access)var asQuery: [(String, String?)] {
        \(asQueryContents(properties).indented)
        }
        """
    }
    
    private func asQueryContents(_ properties: [Property]) -> String {
        var encoderParameters: [String] = []
        // Instead of passing `explode: false` too all individual calls,
        // try to set it once on an URLQueryEncoder itself
        if properties.filter({ !$0.explode }).count >= 2 &&
            properties.allSatisfy({ !$0.explode || $0.type.isBuiltin }) {
            encoderParameters.append("explode: false")
        }
        let statements = properties.map { asQuery($0, encoderParameters: encoderParameters) }
        return """
        let encoder = URLQueryEncoder(\(encoderParameters.joined(separator: ", ")))
        \(statements.joined(separator: "\n"))
        return encoder.items
        """
    }
    
    private func asQuery(_ property: Property) -> String {
        asQuery(property, encoderParameters: [])
    }
    
    private func asQuery(_ property: Property, encoderParameters: [String] = []) -> String {
        var parameters: [String] = []
        if !property.explode && !encoderParameters.contains("explode: false") { parameters.append("explode: false") }
        switch property.style {
        case .pipeDelimited: parameters.append("delimiter: \"|\"")
        case .spaceDelimited: parameters.append("delimiter: \" \"")
        case .deepObject: parameters.append("isDeepObject: true")
        default: break // Do nothing
        }
        parameters = [property.name.rawValue, "forKey: \"\(property.key)\""] + parameters
        return "encoder.encode(\(parameters.joined(separator: ", ")))"
    }
    
    private func delimeter(for style: OpenAPI.Parameter.SchemaContext.Style?) -> String {
        switch style {
        case .pipeDelimited: return "|"
        case .spaceDelimited: return " "
        default: return ","
        }
    }
    
    func enumAsQuery(properties: [Property]) -> String {
        let statements: [String] = properties.map {
            var property = $0
            property.key = "value"
            property.name = PropertyName("value")
            return "case .\($0.name)(let value): \(asQuery(property))"
        }
        let contents = """
        switch self {
        \(statements.joined(separator: "\n"))
        }
        """
        return """
        \(access)var asQuery: [(String, String?)] {
            let encoder = URLQueryEncoder()
        \(contents.indented)
            return encoder.items
        }
        """
    }
    
    /// Example:
    ///
    ///     private func makeGetQuery(_ perPage: Int?, _ page: Int?) -> [(String, String?)] {
    ///         [("per_page", perPage?.asQueryValue), ("page", page?.asQueryValue)]
    ///     }
    func asQueryInline(name: String, properties: [Property], isStatic: Bool) -> String {
        let arguments = properties.map { "_ \($0.name): \($0.type)\($0.isOptional ? "?" : "")" }.joined(separator: ", ")
        return """
        private \(isStatic ? "static " : "" )func \(name)(\(arguments)) -> [(String, String?)] {
        \(asQueryContents(properties).indented)
        }
        """
    }
    
    /// Example:
    ///
    ///     [("token": accessToken)]
    func asKeyValuePairs(_ properties: [Property]) -> String {
        let pairs: [String] = properties.map {
            let value = $0.type.isString ? $0.name.rawValue : "String(\($0.name))"
            return "(\"\($0.key)\", \(value))" }
        return "[\(pairs.joined(separator: ", "))]"
    }
    
    func asURLEncodedBody(name: String, _ isOptional: Bool) -> String {
        if isOptional {
            return "\(name).map(URLQueryEncoder.encode)?.percentEncodedQuery"
        } else {
            return "URLQueryEncoder.encode(\(name)).percentEncodedQuery"
        }
    }

    // MARK: Init
    
    func initializer(properties: [Property]) -> String {
        guard !properties.isEmpty else {
            return "public init() {}"
        }
        let statements = properties.map {
            let defaultValue = ($0.isOptional && $0.defaultValue != nil) ? " ?? \($0.defaultValue!)" : ""
            return "self.\($0.name.accessor) = \($0.name)\(defaultValue)"
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
    
    func decode(properties: [Property], isUsingCodingKeys: Bool) -> String {
        properties
            .map { decode(property: $0, isUsingCodingKeys: isUsingCodingKeys) }
            .joined(separator: "\n")
    }
    
    /// Generates a decode statement.
    ///
    ///     self.id = values.decode(Int.self, forKey: "id")
    func decode(property: Property, isUsingCodingKeys: Bool) -> String {
        let decode = property.isOptional ? "decodeIfPresent" : "decode"
        let key = isUsingCodingKeys ? ".\(property.name)" : "\"\(property.key)\""
        let defaultValue = (property.isOptional && property.defaultValue != nil) ? " ?? \(property.defaultValue!)" : ""
        return "self.\(property.name.accessor) = try values.\(decode)(\(property.type).self, forKey: \(key))\(defaultValue)"
    }
    
    func defaultValue(for property: Property) -> String {
        guard let value = property.defaultValue, !value.isEmpty, property.isOptional else {
            return ""
        }
        return " ?? \(value)"
    }
    
    /// Generated decoding of the directly inlined nested object.
    ///
    ///     self.animal = try Animal(from: decoder)
    func decodeFromDecoder(property: Property) -> String {
        "self.\(property.name.accessor) = try\(property.isOptional ? "?" : "") \(property.type)(from: decoder)"
    }
    
    func initFromDecoder(properties: [Property], isUsingCodingKeys: Bool) -> String {
        initFromDecoder(contents: decode(properties: properties, isUsingCodingKeys: isUsingCodingKeys), isUsingCodingKeys: isUsingCodingKeys)
    }
    
    func initFromDecoder(contents: String, needsValues: Bool = true, isUsingCodingKeys: Bool) -> String {
        let codingKeys = isUsingCodingKeys ? "CodingKeys.self" : "StringCodingKey.self"
        let values = needsValues ? "let values = try decoder.container(keyedBy: \(codingKeys))\n" : ""
        return """
        \(access)init(from decoder: Decoder) throws {
        \((values + contents).indented)
        }
        """
    }
    
    func initFromDecoderAnyOf(properties: [Property]) -> String {
        let contents = properties.map {
            let defaultValue = self.defaultValue(for: $0)
            if defaultValue.isEmpty {
                return "self.\($0.name.accessor) = try? container.decode(\($0.type).self)"
            } else {
                return "self.\($0.name.accessor) = (try? container.decode(\($0.type).self))\(defaultValue)"
            }
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

    func initFromDecoderOneOfWithDiscriminator(properties: [Property], discriminator: Discriminator) -> String {
        var statements = ""
        for property in properties {
            if let correspondingMapping = discriminator.mapping.first(where: { $1 == property.type}) {
                statements += """
                case \"\(correspondingMapping.key)\": self = .\(property.name)(try container.decode(\(property.type).self))

                """
            } else {
                continue
            }
        }
        
        statements += """
        
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Failed to initialize `oneOf`")
        }
        """
        
        return """
        \(access)init(from decoder: Decoder) throws {
            
            struct Discriminator: Decodable {
                let \(discriminator.propertyName): String
            }

            let container = try decoder.singleValueContainer()

            switch (try container.decode(Discriminator.self)).\(discriminator.propertyName) {
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
    
    func encodeAnyOf(properties: [Property]) -> String {
        let statements = properties.map {
            "if let value = \($0.name) { try container.encode(value) }"
        }
        return """
        \(access)func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
        \(statements.joined(separator: "\n").indented)
        }
        """
    }
    
    // MARK: Encodable
    
    func encode(properties: [Property]) -> String {
        let contents = properties.map {
            let encode = $0.isOptional ? "encodeIfPresent" : "encode"
            let getter = $0.name.rawValue == "values" ? "self.values" : $0.name.rawValue
            return "try values.\(encode)(\(getter), forKey: \"\($0.key)\")"
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
    func properties(_ properties: [Property], isReadonly: Bool) -> String {
        properties
            .map { property($0, isReadonly: isReadonly) }
            .joined(separator: "\n")
    }
    
    /// Generates a property with comments and everything.
    ///
    ///     public var files: [Files]?
    func property(_ property: Property, isReadonly: Bool) -> String {
        var output = ""
        if let metadata = property.metadata {
            output += comments(for: metadata, name: property.name.rawValue, isProperty: true)
        }
        let isOptional = property.isOptional && property.defaultValue == nil
        output += "\(access)\(isReadonly ? "let" : "var") \(property.name): \(property.type)\(isOptional ? "?" : "")"
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
            for line in title.lines {
                output += "/// \(line)\n"
            }
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

    func methodOrProperty(name: String, parameters: [String] = [], returning type: String, contents: String, isStatic: Bool) -> String {
        if parameters.isEmpty {
            return property(name: name, returning: type, contents: contents, isStatic: isStatic)
        } else {
            return method(name: name, parameters: parameters, returning: type, contents: contents, isStatic: isStatic)
        }
    }
    
    func method(name: String, parameters: [String] = [], returning type: String, contents: String, isStatic: Bool) -> String {
        """
        \(isStatic ? "static " : "")\(access)func \(name)(\(parameters.joined(separator: ", "))) -> \(type) {
        \(contents.indented)
        }
        """
    }
    
    func property(name: String, returning type: String, contents: String, isStatic: Bool) -> String {
        """
        \(isStatic ? "static " : "")\(access)var \(name): \(type) {
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
    
    func pathExtension(of extensionOf: String, component: String, type: TypeName, isTopLevel: Bool, path: String, parameter: PathParameter?, contents: String) -> String {
        let stat = isTopLevel ? "static " : ""
        if let parameter = parameter {
            let componentWithId = component.replacingOccurrences(of: "{\(parameter.key)}", with: "\\(" + parameter.name.rawValue + ")")
            let path = (isTopLevel ? "\"/" : #""\(path)/"#) + componentWithId + "\""
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
                    \(type)(path: \(isTopLevel ? "\"\(path)\"" : ("path + \"/\(component)\"")))
                }
            
            \(contents.indented)
            }
            """
        }
    }
    
    func extensionOf(_ type: String, contents: String) -> String {
        """
        extension \(type) {
        \(contents.indented)
        }
        """
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
       private extension Request {
           func id(_ id: String) -> Request {
               var copy = self
               copy.id = id
               return copy
           }
       }
       """
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
        let input = self.trimmingCharacters(in: .whitespacesAndNewlines)
        while let newLineIndex = input[index...].firstIndex(of: "\n") {
            lines.append(String(input[index..<newLineIndex]))
            index = input.index(after: newLineIndex)
        }
        lines.append(String(input[index...]))
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
