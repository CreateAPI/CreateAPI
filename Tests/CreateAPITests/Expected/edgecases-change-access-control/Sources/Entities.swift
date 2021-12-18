// Generated by Create API
// https://github.com/kean/CreateAPI
//
// swiftlint:disable all

import Foundation

 struct Order: Codable {
    var id: Int?
    var petID: Int?
    var quantity: Int?
    var shipDate: Date?
    /// Order Status
    var status: Status?
    var isComplete: Bool?

    /// Order Status
    enum Status: String, Codable, CaseIterable {
        case placed
        case approved
        case delivered
    }

    init(id: Int? = nil, petID: Int? = nil, quantity: Int? = nil, shipDate: Date? = nil, status: Status? = nil, isComplete: Bool? = nil) {
        self.id = id
        self.petID = petID
        self.quantity = quantity
        self.shipDate = shipDate
        self.status = status
        self.isComplete = isComplete
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: "id")
        self.petID = try values.decodeIfPresent(Int.self, forKey: "petId")
        self.quantity = try values.decodeIfPresent(Int.self, forKey: "quantity")
        self.shipDate = try values.decodeIfPresent(Date.self, forKey: "shipDate")
        self.status = try values.decodeIfPresent(Status.self, forKey: "status")
        self.isComplete = try values.decodeIfPresent(Bool.self, forKey: "complete")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(id, forKey: "id")
        try values.encodeIfPresent(petID, forKey: "petId")
        try values.encodeIfPresent(quantity, forKey: "quantity")
        try values.encodeIfPresent(shipDate, forKey: "shipDate")
        try values.encodeIfPresent(status, forKey: "status")
        try values.encodeIfPresent(isComplete, forKey: "complete")
    }
}

 struct Category: Codable {
    var id: Int?
    var name: String?

    init(id: Int? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: "id")
        self.name = try values.decodeIfPresent(String.self, forKey: "name")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(id, forKey: "id")
        try values.encodeIfPresent(name, forKey: "name")
    }
}

 struct User: Codable {
    var id: Int?
    var username: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var password: String?
    var phone: String?
    /// User Status
    var userStatus: Int?

    init(id: Int? = nil, username: String? = nil, firstName: String? = nil, lastName: String? = nil, email: String? = nil, password: String? = nil, phone: String? = nil, userStatus: Int? = nil) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.phone = phone
        self.userStatus = userStatus
    }

    init(from decoder: Decoder) throws {
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

    func encode(to encoder: Encoder) throws {
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

 struct Tag: Codable {
    var id: Int?
    var name: String?

    init(id: Int? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: "id")
        self.name = try values.decodeIfPresent(String.self, forKey: "name")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(id, forKey: "id")
        try values.encodeIfPresent(name, forKey: "name")
    }
}

 struct Pet: Codable {
    var id: Int?
    var category: Category?
    /// Example: doggie
    var name: String
    var photoURLs: [String]
    var tags: [Tag]?
    /// Pet status in the store
    var status: Status?

    /// Pet status in the store
    enum Status: String, Codable, CaseIterable {
        case available
        case pending
        case sold
    }

    init(id: Int? = nil, category: Category? = nil, name: String, photoURLs: [String], tags: [Tag]? = nil, status: Status? = nil) {
        self.id = id
        self.category = category
        self.name = name
        self.photoURLs = photoURLs
        self.tags = tags
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: "id")
        self.category = try values.decodeIfPresent(Category.self, forKey: "category")
        self.name = try values.decode(String.self, forKey: "name")
        self.photoURLs = try values.decode([String].self, forKey: "photoUrls")
        self.tags = try values.decodeIfPresent([Tag].self, forKey: "tags")
        self.status = try values.decodeIfPresent(Status.self, forKey: "status")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(id, forKey: "id")
        try values.encodeIfPresent(category, forKey: "category")
        try values.encode(name, forKey: "name")
        try values.encode(photoURLs, forKey: "photoUrls")
        try values.encodeIfPresent(tags, forKey: "tags")
        try values.encodeIfPresent(status, forKey: "status")
    }
}

 struct APIResponse: Codable {
    var code: Int?
    var type: String?
    var message: String?

    init(code: Int? = nil, type: String? = nil, message: String? = nil) {
        self.code = code
        self.type = type
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.code = try values.decodeIfPresent(Int.self, forKey: "code")
        self.type = try values.decodeIfPresent(String.self, forKey: "type")
        self.message = try values.decodeIfPresent(String.self, forKey: "message")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(code, forKey: "code")
        try values.encodeIfPresent(type, forKey: "type")
        try values.encodeIfPresent(message, forKey: "message")
    }
}

/// Model for testing reserved words
 struct Return: Codable {
    var `return`: Int?

    init(`return`: Int? = nil) {
        self.return = `return`
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.return = try values.decodeIfPresent(Int.self, forKey: "return")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(`return`, forKey: "return")
    }
}

/// Model for testing model name same as property name
 struct Name: Codable {
    var name: Int
    var snakeCase: Int?
    var property: String?
    var _123Number: Int?

    init(name: Int, snakeCase: Int? = nil, property: String? = nil, _123Number: Int? = nil) {
        self.name = name
        self.snakeCase = snakeCase
        self.property = property
        self._123Number = _123Number
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.name = try values.decode(Int.self, forKey: "name")
        self.snakeCase = try values.decodeIfPresent(Int.self, forKey: "snake_case")
        self.property = try values.decodeIfPresent(String.self, forKey: "property")
        self._123Number = try values.decodeIfPresent(Int.self, forKey: "123Number")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(name, forKey: "name")
        try values.encodeIfPresent(snakeCase, forKey: "snake_case")
        try values.encodeIfPresent(property, forKey: "property")
        try values.encodeIfPresent(_123Number, forKey: "123Number")
    }
}

/// Model for testing model name starting with number
 struct _200Response: Codable {
    var name: Int?
    var `class`: String?

    init(name: Int? = nil, `class`: String? = nil) {
        self.name = name
        self.class = `class`
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.name = try values.decodeIfPresent(Int.self, forKey: "name")
        self.class = try values.decodeIfPresent(String.self, forKey: "class")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(name, forKey: "name")
        try values.encodeIfPresent(`class`, forKey: "class")
    }
}

/// Model for testing model with "_class" property
 struct ClassModel: Codable {
    var `class`: String?

    init(`class`: String? = nil) {
        self.class = `class`
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.class = try values.decodeIfPresent(String.self, forKey: "_class")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(`class`, forKey: "_class")
    }
}

 struct Dog: Codable {
    var animal: Animal
    var breed: String?

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.animal = try Animal(from: decoder)
        self.breed = try values.decodeIfPresent(String.self, forKey: "breed")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(animal, forKey: "animal")
        try values.encodeIfPresent(breed, forKey: "breed")
    }
}

 struct Cat: Codable {
    var animal: Animal
    var isDeclawed: Bool?

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.animal = try Animal(from: decoder)
        self.isDeclawed = try values.decodeIfPresent(Bool.self, forKey: "declawed")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(animal, forKey: "animal")
        try values.encodeIfPresent(isDeclawed, forKey: "declawed")
    }
}

 struct Animal: Codable {
    var className: String
    var color: String?

    init(className: String, color: String? = nil) {
        self.className = className
        self.color = color
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.className = try values.decode(String.self, forKey: "className")
        self.color = try values.decodeIfPresent(String.self, forKey: "color")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(className, forKey: "className")
        try values.encodeIfPresent(color, forKey: "color")
    }
}

 struct FormatTest: Codable {
    var integer: Int?
    var int32: Int?
    var int64: Int?
    var number: Double
    var float: Double?
    var double: Double?
    var string: String?
    var byte: String
    var binary: String?
    var date: String
    var dateTime: Date?
    var uuid: String?
    var password: String

    init(integer: Int? = nil, int32: Int? = nil, int64: Int? = nil, number: Double, float: Double? = nil, double: Double? = nil, string: String? = nil, byte: String, binary: String? = nil, date: String, dateTime: Date? = nil, uuid: String? = nil, password: String) {
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

    init(from decoder: Decoder) throws {
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

    func encode(to encoder: Encoder) throws {
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

enum EnumClass: String, Codable, CaseIterable {
    case abc = "_abc"
    case minusefg = "-efg"
    case xyz = "(xyz)"
}

 struct EnumTest: Codable {
    var enumString: EnumString?
    var enumInteger: Int?
    var enumNumber: Double?
    var outerEnum: OuterEnum?

    enum EnumString: String, Codable, CaseIterable {
        case upper = "UPPER"
        case lower
    }

    init(enumString: EnumString? = nil, enumInteger: Int? = nil, enumNumber: Double? = nil, outerEnum: OuterEnum? = nil) {
        self.enumString = enumString
        self.enumInteger = enumInteger
        self.enumNumber = enumNumber
        self.outerEnum = outerEnum
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.enumString = try values.decodeIfPresent(EnumString.self, forKey: "enum_string")
        self.enumInteger = try values.decodeIfPresent(Int.self, forKey: "enum_integer")
        self.enumNumber = try values.decodeIfPresent(Double.self, forKey: "enum_number")
        self.outerEnum = try values.decodeIfPresent(OuterEnum.self, forKey: "outerEnum")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(enumString, forKey: "enum_string")
        try values.encodeIfPresent(enumInteger, forKey: "enum_integer")
        try values.encodeIfPresent(enumNumber, forKey: "enum_number")
        try values.encodeIfPresent(outerEnum, forKey: "outerEnum")
    }
}

 struct AdditionalPropertiesClass: Codable {
    var mapProperty: [String: String]?
    var mapOfMapProperty: [String: [String: String]]?

    init(mapProperty: [String: String]? = nil, mapOfMapProperty: [String: [String: String]]? = nil) {
        self.mapProperty = mapProperty
        self.mapOfMapProperty = mapOfMapProperty
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.mapProperty = try values.decodeIfPresent([String: String].self, forKey: "map_property")
        self.mapOfMapProperty = try values.decodeIfPresent([String: [String: String]].self, forKey: "map_of_map_property")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(mapProperty, forKey: "map_property")
        try values.encodeIfPresent(mapOfMapProperty, forKey: "map_of_map_property")
    }
}

 struct MixedPropertiesAndAdditionalPropertiesClass: Codable {
    var uuid: String?
    var dateTime: Date?
    var map: [String: Animal]?

    init(uuid: String? = nil, dateTime: Date? = nil, map: [String: Animal]? = nil) {
        self.uuid = uuid
        self.dateTime = dateTime
        self.map = map
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.uuid = try values.decodeIfPresent(String.self, forKey: "uuid")
        self.dateTime = try values.decodeIfPresent(Date.self, forKey: "dateTime")
        self.map = try values.decodeIfPresent([String: Animal].self, forKey: "map")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(uuid, forKey: "uuid")
        try values.encodeIfPresent(dateTime, forKey: "dateTime")
        try values.encodeIfPresent(map, forKey: "map")
    }
}

 struct List: Codable {
    var _123List: String?

    init(_123List: String? = nil) {
        self._123List = _123List
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self._123List = try values.decodeIfPresent(String.self, forKey: "123-list")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(_123List, forKey: "123-list")
    }
}

 struct Client: Codable {
    var client: String?

    init(client: String? = nil) {
        self.client = client
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.client = try values.decodeIfPresent(String.self, forKey: "client")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(client, forKey: "client")
    }
}

 struct ReadOnlyFirst: Codable {
    var bar: String?
    var baz: String?

    init(bar: String? = nil, baz: String? = nil) {
        self.bar = bar
        self.baz = baz
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.bar = try values.decodeIfPresent(String.self, forKey: "bar")
        self.baz = try values.decodeIfPresent(String.self, forKey: "baz")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(bar, forKey: "bar")
        try values.encodeIfPresent(baz, forKey: "baz")
    }
}

 struct HasOnlyReadOnly: Codable {
    var bar: String?
    var foo: String?

    init(bar: String? = nil, foo: String? = nil) {
        self.bar = bar
        self.foo = foo
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.bar = try values.decodeIfPresent(String.self, forKey: "bar")
        self.foo = try values.decodeIfPresent(String.self, forKey: "foo")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(bar, forKey: "bar")
        try values.encodeIfPresent(foo, forKey: "foo")
    }
}

 struct Capitalization: Codable {
    var smallCamel: String?
    var capitalCamel: String?
    var smallSnake: String?
    var capitalSnake: String?
    var sCAETHFlowPoints: String?
    /// Name of the pet
    /// 
    var attName: String?

    init(smallCamel: String? = nil, capitalCamel: String? = nil, smallSnake: String? = nil, capitalSnake: String? = nil, sCAETHFlowPoints: String? = nil, attName: String? = nil) {
        self.smallCamel = smallCamel
        self.capitalCamel = capitalCamel
        self.smallSnake = smallSnake
        self.capitalSnake = capitalSnake
        self.sCAETHFlowPoints = sCAETHFlowPoints
        self.attName = attName
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.smallCamel = try values.decodeIfPresent(String.self, forKey: "smallCamel")
        self.capitalCamel = try values.decodeIfPresent(String.self, forKey: "CapitalCamel")
        self.smallSnake = try values.decodeIfPresent(String.self, forKey: "small_Snake")
        self.capitalSnake = try values.decodeIfPresent(String.self, forKey: "Capital_Snake")
        self.sCAETHFlowPoints = try values.decodeIfPresent(String.self, forKey: "SCA_ETH_Flow_Points")
        self.attName = try values.decodeIfPresent(String.self, forKey: "ATT_NAME")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(smallCamel, forKey: "smallCamel")
        try values.encodeIfPresent(capitalCamel, forKey: "CapitalCamel")
        try values.encodeIfPresent(smallSnake, forKey: "small_Snake")
        try values.encodeIfPresent(capitalSnake, forKey: "Capital_Snake")
        try values.encodeIfPresent(sCAETHFlowPoints, forKey: "SCA_ETH_Flow_Points")
        try values.encodeIfPresent(attName, forKey: "ATT_NAME")
    }
}

 struct MapTest: Codable {
    var mapMapOfString: [String: [String: String]]?
    var mapOfEnumString: [String: MapOfEnumStringItem]?

    enum MapOfEnumStringItem: String, Codable, CaseIterable {
        case upper = "UPPER"
        case lower
    }

    init(mapMapOfString: [String: [String: String]]? = nil, mapOfEnumString: [String: MapOfEnumStringItem]? = nil) {
        self.mapMapOfString = mapMapOfString
        self.mapOfEnumString = mapOfEnumString
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.mapMapOfString = try values.decodeIfPresent([String: [String: String]].self, forKey: "map_map_of_string")
        self.mapOfEnumString = try values.decodeIfPresent([String: MapOfEnumStringItem].self, forKey: "map_of_enum_string")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(mapMapOfString, forKey: "map_map_of_string")
        try values.encodeIfPresent(mapOfEnumString, forKey: "map_of_enum_string")
    }
}

 struct ArrayTest: Codable {
    var arrayOfString: [String]?
    var arrayArrayOfInteger: [[Int]]?
    var arrayArrayOfModel: [[ReadOnlyFirst]]?

    init(arrayOfString: [String]? = nil, arrayArrayOfInteger: [[Int]]? = nil, arrayArrayOfModel: [[ReadOnlyFirst]]? = nil) {
        self.arrayOfString = arrayOfString
        self.arrayArrayOfInteger = arrayArrayOfInteger
        self.arrayArrayOfModel = arrayArrayOfModel
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.arrayOfString = try values.decodeIfPresent([String].self, forKey: "array_of_string")
        self.arrayArrayOfInteger = try values.decodeIfPresent([[Int]].self, forKey: "array_array_of_integer")
        self.arrayArrayOfModel = try values.decodeIfPresent([[ReadOnlyFirst]].self, forKey: "array_array_of_model")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(arrayOfString, forKey: "array_of_string")
        try values.encodeIfPresent(arrayArrayOfInteger, forKey: "array_array_of_integer")
        try values.encodeIfPresent(arrayArrayOfModel, forKey: "array_array_of_model")
    }
}

 struct NumberOnly: Codable {
    var justNumber: Double?

    init(justNumber: Double? = nil) {
        self.justNumber = justNumber
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.justNumber = try values.decodeIfPresent(Double.self, forKey: "JustNumber")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(justNumber, forKey: "JustNumber")
    }
}

 struct ArrayOfNumberOnly: Codable {
    var arrayNumber: [Double]?

    init(arrayNumber: [Double]? = nil) {
        self.arrayNumber = arrayNumber
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.arrayNumber = try values.decodeIfPresent([Double].self, forKey: "ArrayNumber")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(arrayNumber, forKey: "ArrayNumber")
    }
}

 struct ArrayOfArrayOfNumberOnly: Codable {
    var arrayArrayNumber: [[Double]]?

    init(arrayArrayNumber: [[Double]]? = nil) {
        self.arrayArrayNumber = arrayArrayNumber
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.arrayArrayNumber = try values.decodeIfPresent([[Double]].self, forKey: "ArrayArrayNumber")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(arrayArrayNumber, forKey: "ArrayArrayNumber")
    }
}

 struct EnumArrays: Codable {
    var justSymbol: JustSymbol?
    var arrayEnum: [ArrayEnumItem]?

    enum JustSymbol: String, Codable, CaseIterable {
        case greaterThanOrEqualTo = ">="
        case dollar = "$"
    }

    enum ArrayEnumItem: String, Codable, CaseIterable {
        case fish
        case crab
    }

    init(justSymbol: JustSymbol? = nil, arrayEnum: [ArrayEnumItem]? = nil) {
        self.justSymbol = justSymbol
        self.arrayEnum = arrayEnum
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.justSymbol = try values.decodeIfPresent(JustSymbol.self, forKey: "just_symbol")
        self.arrayEnum = try values.decodeIfPresent([ArrayEnumItem].self, forKey: "array_enum")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(justSymbol, forKey: "just_symbol")
        try values.encodeIfPresent(arrayEnum, forKey: "array_enum")
    }
}

enum OuterEnum: String, Codable, CaseIterable {
    case placed
    case approved
    case delivered
}

 struct ContainerA: Codable {
    var child: Child?
    var refChild: AnyJSON

     struct Child: Codable {
        var `enum`: Enum
        var renameMe: String
        var child: Child

        enum Enum: String, Codable, CaseIterable {
            case a
            case b
        }

         struct Child: Codable {
            var `enum`: Enum
            var renameMe: String

            enum Enum: String, Codable, CaseIterable {
                case a
                case b
            }

            init(`enum`: Enum, renameMe: String) {
                self.enum = `enum`
                self.renameMe = renameMe
            }

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: StringCodingKey.self)
                self.enum = try values.decode(Enum.self, forKey: "enum")
                self.renameMe = try values.decode(String.self, forKey: "rename-me")
            }

            func encode(to encoder: Encoder) throws {
                var values = encoder.container(keyedBy: StringCodingKey.self)
                try values.encode(`enum`, forKey: "enum")
                try values.encode(renameMe, forKey: "rename-me")
            }
        }

        init(`enum`: Enum, renameMe: String, child: Child) {
            self.enum = `enum`
            self.renameMe = renameMe
            self.child = child
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: StringCodingKey.self)
            self.enum = try values.decode(Enum.self, forKey: "enum")
            self.renameMe = try values.decode(String.self, forKey: "rename-me")
            self.child = try values.decode(Child.self, forKey: "child")
        }

        func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: StringCodingKey.self)
            try values.encode(`enum`, forKey: "enum")
            try values.encode(renameMe, forKey: "rename-me")
            try values.encode(child, forKey: "child")
        }
    }

    init(child: Child? = nil, refChild: AnyJSON) {
        self.child = child
        self.refChild = refChild
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.child = try values.decodeIfPresent(Child.self, forKey: "child")
        self.refChild = try values.decode(AnyJSON.self, forKey: "refChild")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encodeIfPresent(child, forKey: "child")
        try values.encode(refChild, forKey: "refChild")
    }
}

 struct ContainerB: Codable {
    var child: Child

     struct Child: Codable {
        var `enum`: Enum
        var renameMe: String
        var child: Child

        enum Enum: String, Codable, CaseIterable {
            case a
            case b
        }

         struct Child: Codable {
            var `enum`: Enum
            var renameMe: String

            enum Enum: String, Codable, CaseIterable {
                case a
                case b
            }

            init(`enum`: Enum, renameMe: String) {
                self.enum = `enum`
                self.renameMe = renameMe
            }

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: StringCodingKey.self)
                self.enum = try values.decode(Enum.self, forKey: "enum")
                self.renameMe = try values.decode(String.self, forKey: "rename-me")
            }

            func encode(to encoder: Encoder) throws {
                var values = encoder.container(keyedBy: StringCodingKey.self)
                try values.encode(`enum`, forKey: "enum")
                try values.encode(renameMe, forKey: "rename-me")
            }
        }

        init(`enum`: Enum, renameMe: String, child: Child) {
            self.enum = `enum`
            self.renameMe = renameMe
            self.child = child
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: StringCodingKey.self)
            self.enum = try values.decode(Enum.self, forKey: "enum")
            self.renameMe = try values.decode(String.self, forKey: "rename-me")
            self.child = try values.decode(Child.self, forKey: "child")
        }

        func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: StringCodingKey.self)
            try values.encode(`enum`, forKey: "enum")
            try values.encode(renameMe, forKey: "rename-me")
            try values.encode(child, forKey: "child")
        }
    }

    init(child: Child) {
        self.child = child
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.child = try values.decode(Child.self, forKey: "child")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(child, forKey: "child")
    }
}

 struct ContainerC: Codable {
    var child: Child

     struct Child: Codable {
        var `enum`: Enum
        var renameMe: String

        enum Enum: String, Codable, CaseIterable {
            case a
            case b
        }

        init(`enum`: Enum, renameMe: String) {
            self.enum = `enum`
            self.renameMe = renameMe
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: StringCodingKey.self)
            self.enum = try values.decode(Enum.self, forKey: "enum")
            self.renameMe = try values.decode(String.self, forKey: "rename-me")
        }

        func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: StringCodingKey.self)
            try values.encode(`enum`, forKey: "enum")
            try values.encode(renameMe, forKey: "rename-me")
        }
    }

    init(child: Child) {
        self.child = child
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.child = try values.decode(Child.self, forKey: "child")
    }

    func encode(to encoder: Encoder) throws {
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
