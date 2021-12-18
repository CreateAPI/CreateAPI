// Generated by Create API
// https://github.com/kean/CreateAPI
//
// swiftlint:disable all

import Foundation

public struct Order: Codable {
    public var id: Int?
    public var petID: Int?
    public var quantity: Int?
    public var shipDate: Date?
    /// Order Status
    public var status: String?
    public var isComplete: Bool?

    public init(id: Int? = nil, petID: Int? = nil, quantity: Int? = nil, shipDate: Date? = nil, status: String? = nil, isComplete: Bool? = nil) {
        self.id = id
        self.petID = petID
        self.quantity = quantity
        self.shipDate = shipDate
        self.status = status
        self.isComplete = isComplete
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: "id")
        self.petID = try values.decodeIfPresent(Int.self, forKey: "petId")
        self.quantity = try values.decodeIfPresent(Int.self, forKey: "quantity")
        self.shipDate = try values.decodeIfPresent(Date.self, forKey: "shipDate")
        self.status = try values.decodeIfPresent(String.self, forKey: "status")
        self.isComplete = try values.decodeIfPresent(Bool.self, forKey: "complete")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(id, forKey: "id")
        try values.encodeIfPresent(petID, forKey: "petId")
        try values.encodeIfPresent(quantity, forKey: "quantity")
        try values.encodeIfPresent(shipDate, forKey: "shipDate")
        try values.encodeIfPresent(status, forKey: "status")
        try values.encodeIfPresent(isComplete, forKey: "complete")
    }
}

public struct Category: Codable {
    public var id: Int?
    public var name: String?

    public init(id: Int? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: "id")
        self.name = try values.decodeIfPresent(String.self, forKey: "name")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(id, forKey: "id")
        try values.encodeIfPresent(name, forKey: "name")
    }
}

public struct User: Codable {
    public var id: Int?
    public var username: String?
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    public var password: String?
    public var phone: String?
    /// User Status
    public var userStatus: Int?

    public init(id: Int? = nil, username: String? = nil, firstName: String? = nil, lastName: String? = nil, email: String? = nil, password: String? = nil, phone: String? = nil, userStatus: Int? = nil) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.phone = phone
        self.userStatus = userStatus
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: "id")
        self.username = try values.decodeIfPresent(String.self, forKey: "username")
        self.firstName = try values.decodeIfPresent(String.self, forKey: "firstName")
        self.lastName = try values.decodeIfPresent(String.self, forKey: "lastName")
        self.email = try values.decodeIfPresent(String.self, forKey: "email")
        self.password = try values.decodeIfPresent(String.self, forKey: "password")
        self.phone = try values.decodeIfPresent(String.self, forKey: "phone")
        self.userStatus = try values.decodeIfPresent(Int.self, forKey: "userStatus")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(id, forKey: "id")
        try values.encodeIfPresent(username, forKey: "username")
        try values.encodeIfPresent(firstName, forKey: "firstName")
        try values.encodeIfPresent(lastName, forKey: "lastName")
        try values.encodeIfPresent(email, forKey: "email")
        try values.encodeIfPresent(password, forKey: "password")
        try values.encodeIfPresent(phone, forKey: "phone")
        try values.encodeIfPresent(userStatus, forKey: "userStatus")
    }
}

public struct Tag: Codable {
    public var id: Int?
    public var name: String?

    public init(id: Int? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: "id")
        self.name = try values.decodeIfPresent(String.self, forKey: "name")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(id, forKey: "id")
        try values.encodeIfPresent(name, forKey: "name")
    }
}

public struct Pet: Codable {
    public var id: Int?
    public var category: Category?
    /// Example: doggie
    public var name: String
    public var photoURLs: [String]
    public var tags: [Tag]?
    /// Pet status in the store
    public var status: String?

    public init(id: Int? = nil, category: Category? = nil, name: String, photoURLs: [String], tags: [Tag]? = nil, status: String? = nil) {
        self.id = id
        self.category = category
        self.name = name
        self.photoURLs = photoURLs
        self.tags = tags
        self.status = status
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: "id")
        self.category = try values.decodeIfPresent(Category.self, forKey: "category")
        self.name = try values.decode(String.self, forKey: "name")
        self.photoURLs = try values.decode([String].self, forKey: "photoUrls")
        self.tags = try values.decodeIfPresent([Tag].self, forKey: "tags")
        self.status = try values.decodeIfPresent(String.self, forKey: "status")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(id, forKey: "id")
        try values.encodeIfPresent(category, forKey: "category")
        try values.encode(name, forKey: "name")
        try values.encode(photoURLs, forKey: "photoUrls")
        try values.encodeIfPresent(tags, forKey: "tags")
        try values.encodeIfPresent(status, forKey: "status")
    }
}

public struct APIResponse: Codable {
    public var code: Int?
    public var type: String?
    public var message: String?

    public init(code: Int? = nil, type: String? = nil, message: String? = nil) {
        self.code = code
        self.type = type
        self.message = message
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.code = try values.decodeIfPresent(Int.self, forKey: "code")
        self.type = try values.decodeIfPresent(String.self, forKey: "type")
        self.message = try values.decodeIfPresent(String.self, forKey: "message")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(code, forKey: "code")
        try values.encodeIfPresent(type, forKey: "type")
        try values.encodeIfPresent(message, forKey: "message")
    }
}

/// Model for testing reserved words
public struct Return: Codable {
    public var `return`: Int?

    public init(`return`: Int? = nil) {
        self.return = `return`
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.return = try values.decodeIfPresent(Int.self, forKey: "return")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(`return`, forKey: "return")
    }
}

/// Model for testing model name same as property name
public struct Name: Codable {
    public var name: Int
    public var snakeCase: Int?
    public var property: String?
    public var _123Number: Int?

    public init(name: Int, snakeCase: Int? = nil, property: String? = nil, _123Number: Int? = nil) {
        self.name = name
        self.snakeCase = snakeCase
        self.property = property
        self._123Number = _123Number
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.name = try values.decode(Int.self, forKey: "name")
        self.snakeCase = try values.decodeIfPresent(Int.self, forKey: "snake_case")
        self.property = try values.decodeIfPresent(String.self, forKey: "property")
        self._123Number = try values.decodeIfPresent(Int.self, forKey: "123Number")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(name, forKey: "name")
        try values.encodeIfPresent(snakeCase, forKey: "snake_case")
        try values.encodeIfPresent(property, forKey: "property")
        try values.encodeIfPresent(_123Number, forKey: "123Number")
    }
}

/// Model for testing model name starting with number
public struct _200Response: Codable {
    public var name: Int?
    public var `class`: String?

    public init(name: Int? = nil, `class`: String? = nil) {
        self.name = name
        self.class = `class`
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.name = try values.decodeIfPresent(Int.self, forKey: "name")
        self.class = try values.decodeIfPresent(String.self, forKey: "class")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(name, forKey: "name")
        try values.encodeIfPresent(`class`, forKey: "class")
    }
}

/// Model for testing model with "_class" property
public struct ClassModel: Codable {
    public var `class`: String?

    public init(`class`: String? = nil) {
        self.class = `class`
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.class = try values.decodeIfPresent(String.self, forKey: "_class")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(`class`, forKey: "_class")
    }
}

public struct Dog: Codable {
    public var animal: Animal
    public var breed: String?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.animal = try Animal(from: decoder)
        self.breed = try values.decodeIfPresent(String.self, forKey: "breed")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(animal, forKey: "animal")
        try values.encodeIfPresent(breed, forKey: "breed")
    }
}

public struct Cat: Codable {
    public var animal: Animal
    public var isDeclawed: Bool?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.animal = try Animal(from: decoder)
        self.isDeclawed = try values.decodeIfPresent(Bool.self, forKey: "declawed")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(animal, forKey: "animal")
        try values.encodeIfPresent(isDeclawed, forKey: "declawed")
    }
}

public struct Animal: Codable {
    public var className: String
    public var color: String?

    public init(className: String, color: String? = nil) {
        self.className = className
        self.color = color
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.className = try values.decode(String.self, forKey: "className")
        self.color = try values.decodeIfPresent(String.self, forKey: "color")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(className, forKey: "className")
        try values.encodeIfPresent(color, forKey: "color")
    }
}

public struct FormatTest: Codable {
    public var integer: Int?
    public var int32: Int?
    public var int64: Int?
    public var number: Double
    public var float: Double?
    public var double: Double?
    public var string: String?
    public var byte: String
    public var binary: String?
    public var date: String
    public var dateTime: Date?
    public var uuid: String?
    public var password: String

    public init(integer: Int? = nil, int32: Int? = nil, int64: Int? = nil, number: Double, float: Double? = nil, double: Double? = nil, string: String? = nil, byte: String, binary: String? = nil, date: String, dateTime: Date? = nil, uuid: String? = nil, password: String) {
        self.integer = integer
        self.int32 = int32
        self.int64 = int64
        self.number = number
        self.float = float
        self.double = double
        self.string = string
        self.byte = byte
        self.binary = binary
        self.date = date
        self.dateTime = dateTime
        self.uuid = uuid
        self.password = password
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.integer = try values.decodeIfPresent(Int.self, forKey: "integer")
        self.int32 = try values.decodeIfPresent(Int.self, forKey: "int32")
        self.int64 = try values.decodeIfPresent(Int.self, forKey: "int64")
        self.number = try values.decode(Double.self, forKey: "number")
        self.float = try values.decodeIfPresent(Double.self, forKey: "float")
        self.double = try values.decodeIfPresent(Double.self, forKey: "double")
        self.string = try values.decodeIfPresent(String.self, forKey: "string")
        self.byte = try values.decode(String.self, forKey: "byte")
        self.binary = try values.decodeIfPresent(String.self, forKey: "binary")
        self.date = try values.decode(String.self, forKey: "date")
        self.dateTime = try values.decodeIfPresent(Date.self, forKey: "dateTime")
        self.uuid = try values.decodeIfPresent(String.self, forKey: "uuid")
        self.password = try values.decode(String.self, forKey: "password")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(integer, forKey: "integer")
        try values.encodeIfPresent(int32, forKey: "int32")
        try values.encodeIfPresent(int64, forKey: "int64")
        try values.encode(number, forKey: "number")
        try values.encodeIfPresent(float, forKey: "float")
        try values.encodeIfPresent(double, forKey: "double")
        try values.encodeIfPresent(string, forKey: "string")
        try values.encode(byte, forKey: "byte")
        try values.encodeIfPresent(binary, forKey: "binary")
        try values.encode(date, forKey: "date")
        try values.encodeIfPresent(dateTime, forKey: "dateTime")
        try values.encodeIfPresent(uuid, forKey: "uuid")
        try values.encode(password, forKey: "password")
    }
}

public struct EnumTest: Codable {
    public var enumString: String?
    public var enumInteger: Int?
    public var enumNumber: Double?
    public var outerEnum: String?

    public init(enumString: String? = nil, enumInteger: Int? = nil, enumNumber: Double? = nil, outerEnum: String? = nil) {
        self.enumString = enumString
        self.enumInteger = enumInteger
        self.enumNumber = enumNumber
        self.outerEnum = outerEnum
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.enumString = try values.decodeIfPresent(String.self, forKey: "enum_string")
        self.enumInteger = try values.decodeIfPresent(Int.self, forKey: "enum_integer")
        self.enumNumber = try values.decodeIfPresent(Double.self, forKey: "enum_number")
        self.outerEnum = try values.decodeIfPresent(String.self, forKey: "outerEnum")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(enumString, forKey: "enum_string")
        try values.encodeIfPresent(enumInteger, forKey: "enum_integer")
        try values.encodeIfPresent(enumNumber, forKey: "enum_number")
        try values.encodeIfPresent(outerEnum, forKey: "outerEnum")
    }
}

public struct AdditionalPropertiesClass: Codable {
    public var mapProperty: [String: String]?
    public var mapOfMapProperty: [String: [String: String]]?

    public init(mapProperty: [String: String]? = nil, mapOfMapProperty: [String: [String: String]]? = nil) {
        self.mapProperty = mapProperty
        self.mapOfMapProperty = mapOfMapProperty
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.mapProperty = try values.decodeIfPresent([String: String].self, forKey: "map_property")
        self.mapOfMapProperty = try values.decodeIfPresent([String: [String: String]].self, forKey: "map_of_map_property")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(mapProperty, forKey: "map_property")
        try values.encodeIfPresent(mapOfMapProperty, forKey: "map_of_map_property")
    }
}

public struct MixedPropertiesAndAdditionalPropertiesClass: Codable {
    public var uuid: String?
    public var dateTime: Date?
    public var map: [String: Animal]?

    public init(uuid: String? = nil, dateTime: Date? = nil, map: [String: Animal]? = nil) {
        self.uuid = uuid
        self.dateTime = dateTime
        self.map = map
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.uuid = try values.decodeIfPresent(String.self, forKey: "uuid")
        self.dateTime = try values.decodeIfPresent(Date.self, forKey: "dateTime")
        self.map = try values.decodeIfPresent([String: Animal].self, forKey: "map")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(uuid, forKey: "uuid")
        try values.encodeIfPresent(dateTime, forKey: "dateTime")
        try values.encodeIfPresent(map, forKey: "map")
    }
}

public struct List: Codable {
    public var _123List: String?

    public init(_123List: String? = nil) {
        self._123List = _123List
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self._123List = try values.decodeIfPresent(String.self, forKey: "123-list")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(_123List, forKey: "123-list")
    }
}

public struct Client: Codable {
    public var client: String?

    public init(client: String? = nil) {
        self.client = client
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.client = try values.decodeIfPresent(String.self, forKey: "client")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(client, forKey: "client")
    }
}

public struct ReadOnlyFirst: Codable {
    public var bar: String?
    public var baz: String?

    public init(bar: String? = nil, baz: String? = nil) {
        self.bar = bar
        self.baz = baz
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.bar = try values.decodeIfPresent(String.self, forKey: "bar")
        self.baz = try values.decodeIfPresent(String.self, forKey: "baz")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(bar, forKey: "bar")
        try values.encodeIfPresent(baz, forKey: "baz")
    }
}

public struct HasOnlyReadOnly: Codable {
    public var bar: String?
    public var foo: String?

    public init(bar: String? = nil, foo: String? = nil) {
        self.bar = bar
        self.foo = foo
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.bar = try values.decodeIfPresent(String.self, forKey: "bar")
        self.foo = try values.decodeIfPresent(String.self, forKey: "foo")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(bar, forKey: "bar")
        try values.encodeIfPresent(foo, forKey: "foo")
    }
}

public struct Capitalization: Codable {
    public var smallCamel: String?
    public var capitalCamel: String?
    public var smallSnake: String?
    public var capitalSnake: String?
    public var sCAETHFlowPoints: String?
    /// Name of the pet
    /// 
    public var attName: String?

    public init(smallCamel: String? = nil, capitalCamel: String? = nil, smallSnake: String? = nil, capitalSnake: String? = nil, sCAETHFlowPoints: String? = nil, attName: String? = nil) {
        self.smallCamel = smallCamel
        self.capitalCamel = capitalCamel
        self.smallSnake = smallSnake
        self.capitalSnake = capitalSnake
        self.sCAETHFlowPoints = sCAETHFlowPoints
        self.attName = attName
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.smallCamel = try values.decodeIfPresent(String.self, forKey: "smallCamel")
        self.capitalCamel = try values.decodeIfPresent(String.self, forKey: "CapitalCamel")
        self.smallSnake = try values.decodeIfPresent(String.self, forKey: "small_Snake")
        self.capitalSnake = try values.decodeIfPresent(String.self, forKey: "Capital_Snake")
        self.sCAETHFlowPoints = try values.decodeIfPresent(String.self, forKey: "SCA_ETH_Flow_Points")
        self.attName = try values.decodeIfPresent(String.self, forKey: "ATT_NAME")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(smallCamel, forKey: "smallCamel")
        try values.encodeIfPresent(capitalCamel, forKey: "CapitalCamel")
        try values.encodeIfPresent(smallSnake, forKey: "small_Snake")
        try values.encodeIfPresent(capitalSnake, forKey: "Capital_Snake")
        try values.encodeIfPresent(sCAETHFlowPoints, forKey: "SCA_ETH_Flow_Points")
        try values.encodeIfPresent(attName, forKey: "ATT_NAME")
    }
}

public struct MapTest: Codable {
    public var mapMapOfString: [String: [String: String]]?
    public var mapOfEnumString: [String: String]?

    public init(mapMapOfString: [String: [String: String]]? = nil, mapOfEnumString: [String: String]? = nil) {
        self.mapMapOfString = mapMapOfString
        self.mapOfEnumString = mapOfEnumString
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.mapMapOfString = try values.decodeIfPresent([String: [String: String]].self, forKey: "map_map_of_string")
        self.mapOfEnumString = try values.decodeIfPresent([String: String].self, forKey: "map_of_enum_string")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(mapMapOfString, forKey: "map_map_of_string")
        try values.encodeIfPresent(mapOfEnumString, forKey: "map_of_enum_string")
    }
}

public struct ArrayTest: Codable {
    public var arrayOfString: [String]?
    public var arrayArrayOfInteger: [[Int]]?
    public var arrayArrayOfModel: [[ReadOnlyFirst]]?

    public init(arrayOfString: [String]? = nil, arrayArrayOfInteger: [[Int]]? = nil, arrayArrayOfModel: [[ReadOnlyFirst]]? = nil) {
        self.arrayOfString = arrayOfString
        self.arrayArrayOfInteger = arrayArrayOfInteger
        self.arrayArrayOfModel = arrayArrayOfModel
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.arrayOfString = try values.decodeIfPresent([String].self, forKey: "array_of_string")
        self.arrayArrayOfInteger = try values.decodeIfPresent([[Int]].self, forKey: "array_array_of_integer")
        self.arrayArrayOfModel = try values.decodeIfPresent([[ReadOnlyFirst]].self, forKey: "array_array_of_model")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(arrayOfString, forKey: "array_of_string")
        try values.encodeIfPresent(arrayArrayOfInteger, forKey: "array_array_of_integer")
        try values.encodeIfPresent(arrayArrayOfModel, forKey: "array_array_of_model")
    }
}

public struct NumberOnly: Codable {
    public var justNumber: Double?

    public init(justNumber: Double? = nil) {
        self.justNumber = justNumber
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.justNumber = try values.decodeIfPresent(Double.self, forKey: "JustNumber")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(justNumber, forKey: "JustNumber")
    }
}

public struct ArrayOfNumberOnly: Codable {
    public var arrayNumber: [Double]?

    public init(arrayNumber: [Double]? = nil) {
        self.arrayNumber = arrayNumber
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.arrayNumber = try values.decodeIfPresent([Double].self, forKey: "ArrayNumber")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(arrayNumber, forKey: "ArrayNumber")
    }
}

public struct ArrayOfArrayOfNumberOnly: Codable {
    public var arrayArrayNumber: [[Double]]?

    public init(arrayArrayNumber: [[Double]]? = nil) {
        self.arrayArrayNumber = arrayArrayNumber
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.arrayArrayNumber = try values.decodeIfPresent([[Double]].self, forKey: "ArrayArrayNumber")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(arrayArrayNumber, forKey: "ArrayArrayNumber")
    }
}

public struct EnumArrays: Codable {
    public var justSymbol: String?
    public var arrayEnum: [String]?

    public init(justSymbol: String? = nil, arrayEnum: [String]? = nil) {
        self.justSymbol = justSymbol
        self.arrayEnum = arrayEnum
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.justSymbol = try values.decodeIfPresent(String.self, forKey: "just_symbol")
        self.arrayEnum = try values.decodeIfPresent([String].self, forKey: "array_enum")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(justSymbol, forKey: "just_symbol")
        try values.encodeIfPresent(arrayEnum, forKey: "array_enum")
    }
}

public struct ContainerA: Codable {
    public var child: Child?
    public var refChild: AnyJSON

    public struct Child: Codable {
        public var `enum`: String
        public var renameMe: String
        public var child: Child

        public struct Child: Codable {
            public var `enum`: String
            public var renameMe: String

            public init(`enum`: String, renameMe: String) {
                self.enum = `enum`
                self.renameMe = renameMe
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: StringCodingKey.self)
                self.enum = try values.decode(String.self, forKey: "enum")
                self.renameMe = try values.decode(String.self, forKey: "rename-me")
            }

            public func encode(to encoder: Encoder) throws {
                var values = encoder.container(keyedBy: StringCodingKey.self)
                try values.encode(`enum`, forKey: "enum")
                try values.encode(renameMe, forKey: "rename-me")
            }
        }

        public init(`enum`: String, renameMe: String, child: Child) {
            self.enum = `enum`
            self.renameMe = renameMe
            self.child = child
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: StringCodingKey.self)
            self.enum = try values.decode(String.self, forKey: "enum")
            self.renameMe = try values.decode(String.self, forKey: "rename-me")
            self.child = try values.decode(Child.self, forKey: "child")
        }

        public func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: StringCodingKey.self)
            try values.encode(`enum`, forKey: "enum")
            try values.encode(renameMe, forKey: "rename-me")
            try values.encode(child, forKey: "child")
        }
    }

    public init(child: Child? = nil, refChild: AnyJSON) {
        self.child = child
        self.refChild = refChild
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.child = try values.decodeIfPresent(Child.self, forKey: "child")
        self.refChild = try values.decode(AnyJSON.self, forKey: "refChild")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(child, forKey: "child")
        try values.encode(refChild, forKey: "refChild")
    }
}

public struct ContainerB: Codable {
    public var child: Child

    public struct Child: Codable {
        public var `enum`: String
        public var renameMe: String
        public var child: Child

        public struct Child: Codable {
            public var `enum`: String
            public var renameMe: String

            public init(`enum`: String, renameMe: String) {
                self.enum = `enum`
                self.renameMe = renameMe
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: StringCodingKey.self)
                self.enum = try values.decode(String.self, forKey: "enum")
                self.renameMe = try values.decode(String.self, forKey: "rename-me")
            }

            public func encode(to encoder: Encoder) throws {
                var values = encoder.container(keyedBy: StringCodingKey.self)
                try values.encode(`enum`, forKey: "enum")
                try values.encode(renameMe, forKey: "rename-me")
            }
        }

        public init(`enum`: String, renameMe: String, child: Child) {
            self.enum = `enum`
            self.renameMe = renameMe
            self.child = child
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: StringCodingKey.self)
            self.enum = try values.decode(String.self, forKey: "enum")
            self.renameMe = try values.decode(String.self, forKey: "rename-me")
            self.child = try values.decode(Child.self, forKey: "child")
        }

        public func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: StringCodingKey.self)
            try values.encode(`enum`, forKey: "enum")
            try values.encode(renameMe, forKey: "rename-me")
            try values.encode(child, forKey: "child")
        }
    }

    public init(child: Child) {
        self.child = child
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.child = try values.decode(Child.self, forKey: "child")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(child, forKey: "child")
    }
}

public struct ContainerC: Codable {
    public var child: Child

    public struct Child: Codable {
        public var `enum`: String
        public var renameMe: String

        public init(`enum`: String, renameMe: String) {
            self.enum = `enum`
            self.renameMe = renameMe
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: StringCodingKey.self)
            self.enum = try values.decode(String.self, forKey: "enum")
            self.renameMe = try values.decode(String.self, forKey: "rename-me")
        }

        public func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: StringCodingKey.self)
            try values.encode(`enum`, forKey: "enum")
            try values.encode(renameMe, forKey: "rename-me")
        }
    }

    public init(child: Child) {
        self.child = child
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.child = try values.decode(Child.self, forKey: "child")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(child, forKey: "child")
    }
}

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
