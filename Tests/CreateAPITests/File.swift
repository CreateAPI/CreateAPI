
import Foundation


protocol URLQueryItemEncoderDateFormatter {
    func string(from date: Date) -> String
}

extension DateFormatter: URLQueryItemEncoderDateFormatter {}
@available(iOS 10.0, iOSApplicationExtension 10.0, macOS 10.12, *)
extension ISO8601DateFormatter: URLQueryItemEncoderDateFormatter {}

let iso8601Formatter: URLQueryItemEncoderDateFormatter = {
#if os(Linux)
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")!
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    return formatter
#else
    if #available(iOS 11.0, macOS 10.13, *) {
        var formatter = ISO8601DateFormatter()
        formatter.formatOptions.formUnion([.withFractionalSeconds])
        return formatter
    } else {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")!
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }
#endif
}()


public final class URLQueryEncoder {
    public var explode: Bool
    
    fileprivate(set) public var codingPath: [CodingKey] = []
    fileprivate var items: [URLQueryItem] = []

    public init(explode: Bool = true) {
        self.explode = explode
    }
    
    public func encode(_ value: Encodable) throws -> [URLQueryItem] {
        items = []
        try value.encode(to: self)
        return items
    }
    
    public static func data(for queryItems: [URLQueryItem]) -> Data {
        var components = URLComponents()
        components.queryItems = queryItems
        return components.percentEncodedQuery?.data(using: .utf8) ?? Data()
    }
}

extension Array where Element == CodingKey {
    fileprivate var queryItemKey: String {
        guard !isEmpty else { return "" }
        var keysPath = self
        let firstKey = keysPath.removeFirst()
        return firstKey.stringValue
    }
}

private struct URLQueryItemArrayElementKey: CodingKey {
    var explode: Bool = true
    
    fileprivate var stringValue: String {
        ""
    }
    
    fileprivate init(index: Int, explode: Bool) {
        self.index = index
        self.explode = explode
    }
    
    init?(stringValue: String) {
        guard let index = Int(stringValue) else { return nil }
        self.index = index
    }
    let index: Int
    var intValue: Int? {
        return index
    }
    init?(intValue: Int) {
        self.index = intValue
    }
}

extension URLQueryEncoder {
    private func pushNil(forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: nil))
    }
    
    private func push(_ value: DateComponents, forKey codingPath: [CodingKey]) throws {
        guard (value.calendar?.identifier ?? Calendar.current.identifier) == .gregorian,
              let year = value.year, let month = value.month, let day = value.day else {
                  throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid date components"))
              }
        
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(year)-\(month)-\(day)"))
    }
    
    private func push(_ value: String, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: value))
    }
    
    private func push(_ value: Date, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: iso8601Formatter.string(from: value)))
    }
    
    private func push(_ value: Bool, forKey codingPath: [CodingKey]) throws {
        let boolValue: String
        switch value {
        case true:
            boolValue = "true"
        case false:
            boolValue = "false"
        }
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: boolValue))
    }
    
    private func push(_ value: Int, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: Int8, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: Int16, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: Int32, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: Int64, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: UInt, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: UInt8, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: UInt16, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: UInt32, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: UInt64, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: Double, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: Float, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: "\(value)"))
    }
    
    private func push(_ value: URL, forKey codingPath: [CodingKey]) throws {
        items.append(URLQueryItem(name: codingPath.queryItemKey, value: value.absoluteString))
    }
    
    private func push<T: Encodable>(_ value: T, forKey codingPath: [CodingKey]) throws {
        self.codingPath = codingPath
        switch value {
        case let value as String:
            try push(value, forKey: codingPath)
            
        case let value as Bool:
            try push(value, forKey: codingPath)
        case let value as Int:
            try push(value, forKey: codingPath)
        case let value as Int8:
            try push(value, forKey: codingPath)
        case let value as Int16:
            try push(value, forKey: codingPath)
        case let value as Int32:
            try push(value, forKey: codingPath)
        case let value as Int64:
            try push(value, forKey: codingPath)
        case let value as UInt:
            try push(value, forKey: codingPath)
        case let value as UInt8:
            try push(value, forKey: codingPath)
        case let value as UInt16:
            try push(value, forKey: codingPath)
        case let value as UInt32:
            try push(value, forKey: codingPath)
        case let value as UInt64:
            try push(value, forKey: codingPath)
            
        case let value as Double:
            try push(value, forKey: codingPath)
        case let value as Float:
            try push(value, forKey: codingPath)
            
        case let value as Date:
            try push(value, forKey: codingPath)
        case let value as DateComponents:
            try push(value, forKey: codingPath)
            
        case let value as URL:
            try push(value, forKey: codingPath)
            
#warning("TEMP")
//        case let value as Array<Encodable>:
//            #warning("TEMP")
//            if explode {
//                try value.encode(to: self)
//            } else {
//                let encoder = URLQueryEncoder()
//                let query = try encoder.encode(value)
//                try query.compactMap { $0.value }.encode(to: self)
//            }
            
        case let value:
            try value.encode(to: self)
        }
    }
}

extension URLQueryEncoder: Encoder {
    public var userInfo: [CodingUserInfoKey : Any] { return [:] }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(KeyedContainer<Key>(encoder: self, codingPath: codingPath))
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContanier(encoder: self, codingPath: codingPath)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueContanier(encoder: self, codingPath: codingPath)
    }
}

extension URLQueryEncoder {
    fileprivate struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let encoder: URLQueryEncoder
        let codingPath: [CodingKey]
        
        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            let codingPath = self.codingPath + [key]
            encoder.codingPath = codingPath
            defer { encoder.codingPath.removeLast() }
            try encoder.push(value, forKey: codingPath)
        }
        
        func encodeNil(forKey key: Key) throws {
            let codingPath = self.codingPath + [key]
            encoder.codingPath = codingPath
            defer { encoder.codingPath.removeLast() }
            try encoder.pushNil(forKey: codingPath)
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder, codingPath: codingPath + [key]))
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return UnkeyedContanier(encoder: encoder, codingPath: codingPath + [key])
        }
        
        func superEncoder() -> Encoder {
            return URLQueryItemReferencingEncoder(encoder: encoder, codingPath: codingPath)
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return URLQueryItemReferencingEncoder(encoder: encoder, codingPath: codingPath + [key])
        }
    }
    
    fileprivate class UnkeyedContanier: UnkeyedEncodingContainer {
        var encoder: URLQueryEncoder
        
        var codingPath: [CodingKey]
        
        var count: Int {
            return encodedItemsCount
        }
        
        var encodedItemsCount: Int = 0
        
        fileprivate init(encoder: URLQueryEncoder, codingPath: [CodingKey], encodedItemsCount: Int = 0) {
            self.encoder = encoder
            self.codingPath = codingPath
            self.encodedItemsCount = encodedItemsCount
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            codingPath.append(
                URLQueryItemArrayElementKey(index: encodedItemsCount, explode: encoder.explode)
            )
            defer { codingPath.removeLast() }
            return KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder, codingPath: codingPath))
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            codingPath.append(
                URLQueryItemArrayElementKey(index: encodedItemsCount, explode: encoder.explode)
            )
            defer { codingPath.removeLast() }
            return self
        }
        
        func superEncoder() -> Encoder {
            codingPath.append(URLQueryItemArrayElementKey(index: encodedItemsCount, explode: encoder.explode))
            defer { codingPath.removeLast() }
            return UnkeyedURLQueryItemReferencingEncoder(encoder: encoder, codingPath: codingPath, referencing: self)
        }
        
        func encodeNil() throws {
            codingPath.append(
                URLQueryItemArrayElementKey(index: encodedItemsCount, explode: encoder.explode)
            )
            defer { codingPath.removeLast() }
            try encoder.pushNil(forKey: codingPath)
            encodedItemsCount += 1
        }
        
        #warning("TODO: remove URLQueryItemArrayElementKey")
        #warning("TODO: implement explode properly")
        
        func encode<T>(_ value: T) throws where T : Encodable {
            codingPath.append(
                URLQueryItemArrayElementKey(index: encodedItemsCount, explode: encoder.explode)
            )
            defer { codingPath.removeLast() }
            try encoder.push(value, forKey: codingPath)
            encodedItemsCount += 1
        }
    }
    
    fileprivate struct SingleValueContanier: SingleValueEncodingContainer {
        let encoder: URLQueryEncoder
        var codingPath: [CodingKey]
        
        fileprivate init(encoder: URLQueryEncoder, codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
        }
        
        mutating func encodeNil() throws {
            try encoder.pushNil(forKey: codingPath)
        }
        
        public func encode(_ value: Bool) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: Int) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: Int8) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: Int16) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: Int32) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: Int64) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: UInt) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: UInt8) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: UInt16) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: UInt32) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: UInt64) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: String) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: Float) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        public func encode(_ value: Double) throws {
            try encoder.push(value, forKey: codingPath)
        }
        
        mutating func encode<T>(_ value: T) throws where T : Encodable {
            encoder.codingPath = self.codingPath
            try encoder.push(value, forKey: codingPath)
        }
    }
}

#warning("TODO: remove or refactor these")

fileprivate class URLQueryItemReferencingEncoder: URLQueryEncoder {
    fileprivate let encoder: URLQueryEncoder
    
    init(encoder: URLQueryEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        super.init()
        self.codingPath = codingPath
        // self.arrayIndexEncodingStrategy = encoder.arrayIndexEncodingStrategy
    }
    
    deinit {
        self.encoder.items.append(contentsOf: self.items)
    }
}

fileprivate class UnkeyedURLQueryItemReferencingEncoder: URLQueryItemReferencingEncoder {
    var referencedUnkeyedContainer: UnkeyedContanier
    
    init(encoder: URLQueryEncoder, codingPath: [CodingKey], referencing: UnkeyedContanier) {
        referencedUnkeyedContainer = referencing
        super.init(encoder: encoder, codingPath: codingPath)
    }
    
    deinit {
        referencedUnkeyedContainer.encodedItemsCount += items.count
    }
}
