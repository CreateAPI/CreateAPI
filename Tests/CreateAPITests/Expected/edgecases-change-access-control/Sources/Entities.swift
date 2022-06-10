// Generated by Create API
// https://github.com/CreateAPI/CreateAPI
//
// swiftlint:disable all

import Foundation
import NaiveDate

 struct Order: Codable {
    var id: Int?
    var petID: Int?
    var quantity: Int?
    var shipDate: Date?
    /// Order Status
    var status: Status?
    var isComplete: Bool

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
        self.isComplete = isComplete ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case petID = "petId"
        case quantity
        case shipDate
        case status
        case isComplete = "complete"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: .id)
        self.petID = try values.decodeIfPresent(Int.self, forKey: .petID)
        self.quantity = try values.decodeIfPresent(Int.self, forKey: .quantity)
        self.shipDate = try values.decodeIfPresent(Date.self, forKey: .shipDate)
        self.status = try values.decodeIfPresent(Status.self, forKey: .status)
        self.isComplete = try values.decodeIfPresent(Bool.self, forKey: .isComplete) ?? false
    }
}

 struct Category: Codable {
    var id: Int?
    var name: String?

    init(id: Int? = nil, name: String? = nil) {
        self.id = id
        self.name = name
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
}

 struct Tag: Codable {
    var id: Int?
    var name: String?

    init(id: Int? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

 struct Pet: Codable {
    var id: Int?
    var category: Category?
    /// Example: "doggie"
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

    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case name
        case photoURLs = "photoUrls"
        case tags
        case status
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
}

/// Model for testing reserved words
 struct Return: Codable {
    var `return`: Int?

    init(`return`: Int? = nil) {
        self.return = `return`
    }

    private enum CodingKeys: String, CodingKey {
        case `return`
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

    private enum CodingKeys: String, CodingKey {
        case name
        case snakeCase = "snake_case"
        case property
        case _123Number = "123Number"
    }
}

/// Model for testing model name starting with number
 struct __200Response: Codable {
    var name: Int?
    var `class`: String?

    init(name: Int? = nil, `class`: String? = nil) {
        self.name = name
        self.class = `class`
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case `class`
    }
}

/// Model for testing model with "_class" property
 struct ClassModel: Codable {
    var `class`: String?

    init(`class`: String? = nil) {
        self.class = `class`
    }

    private enum CodingKeys: String, CodingKey {
        case `class` = "_class"
    }
}

 struct Dog: Codable {
    var animal: Animal
    var breed: Breed?
    var image: Image?

    enum Breed: String, Codable, CaseIterable {
        case large = "Large"
        case medium = "Medium"
        case small = "Small"
    }

    init(animal: Animal, breed: Breed? = nil, image: Image? = nil) {
        self.animal = animal
        self.breed = breed
        self.image = image
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.animal = try Animal(from: decoder)
        self.breed = try values.decodeIfPresent(Breed.self, forKey: "breed")
        self.image = try values.decodeIfPresent(Image.self, forKey: "image")
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(animal, forKey: "animal")
        try values.encodeIfPresent(breed, forKey: "breed")
        try values.encodeIfPresent(image, forKey: "image")
    }
}

 struct Cat: Codable {
    var animal: Animal
    var isDeclawed: Bool?

    init(animal: Animal, isDeclawed: Bool? = nil) {
        self.animal = animal
        self.isDeclawed = isDeclawed
    }

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
}

 struct Image: Codable {
    var id: String
    var url: String

    init(id: String, url: String) {
        self.id = id
        self.url = url
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
    var byte: Data
    var binary: String?
    var date: NaiveDate
    var dateTime: Date?
    var uuid: UUID?
    var password: String

    init(integer: Int? = nil, int32: Int? = nil, int64: Int? = nil, number: Double, float: Double? = nil, double: Double? = nil, string: String? = nil, byte: Data, binary: String? = nil, date: NaiveDate, dateTime: Date? = nil, uuid: UUID? = nil, password: String) {
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
        case empty = ""
    }

    init(enumString: EnumString? = nil, enumInteger: Int? = nil, enumNumber: Double? = nil, outerEnum: OuterEnum? = nil) {
        self.enumString = enumString
        self.enumInteger = enumInteger
        self.enumNumber = enumNumber
        self.outerEnum = outerEnum
    }

    private enum CodingKeys: String, CodingKey {
        case enumString = "enum_string"
        case enumInteger = "enum_integer"
        case enumNumber = "enum_number"
        case outerEnum
    }
}

 struct AdditionalPropertiesClass: Codable {
    var mapProperty: [String: String]?
    var mapOfMapProperty: [String: [String: String]]?

    init(mapProperty: [String: String]? = nil, mapOfMapProperty: [String: [String: String]]? = nil) {
        self.mapProperty = mapProperty
        self.mapOfMapProperty = mapOfMapProperty
    }

    private enum CodingKeys: String, CodingKey {
        case mapProperty = "map_property"
        case mapOfMapProperty = "map_of_map_property"
    }
}

 struct MixedPropertiesAndAdditionalPropertiesClass: Codable {
    var uuid: UUID?
    var dateTime: Date?
    var map: [String: Animal]?

    init(uuid: UUID? = nil, dateTime: Date? = nil, map: [String: Animal]? = nil) {
        self.uuid = uuid
        self.dateTime = dateTime
        self.map = map
    }
}

 struct List: Codable {
    var _123List: String?

    init(_123List: String? = nil) {
        self._123List = _123List
    }

    private enum CodingKeys: String, CodingKey {
        case _123List = "123-list"
    }
}

 struct Client: Codable {
    var client: String?

    init(client: String? = nil) {
        self.client = client
    }
}

 struct ReadOnlyFirst: Codable {
    var bar: String?
    var baz: String?

    init(bar: String? = nil, baz: String? = nil) {
        self.bar = bar
        self.baz = baz
    }
}

 struct HasOnlyReadOnly: Codable {
    var bar: String?
    var foo: String?

    init(bar: String? = nil, foo: String? = nil) {
        self.bar = bar
        self.foo = foo
    }
}

 struct Capitalization: Codable {
    var smallCamel: String?
    var capitalCamel: String?
    var smallSnake: String?
    var capitalSnake: String?
    var sCAETHFlowPoints: String?
    /// Name of the pet
    var attName: String?

    init(smallCamel: String? = nil, capitalCamel: String? = nil, smallSnake: String? = nil, capitalSnake: String? = nil, sCAETHFlowPoints: String? = nil, attName: String? = nil) {
        self.smallCamel = smallCamel
        self.capitalCamel = capitalCamel
        self.smallSnake = smallSnake
        self.capitalSnake = capitalSnake
        self.sCAETHFlowPoints = sCAETHFlowPoints
        self.attName = attName
    }

    private enum CodingKeys: String, CodingKey {
        case smallCamel
        case capitalCamel = "CapitalCamel"
        case smallSnake = "small_Snake"
        case capitalSnake = "Capital_Snake"
        case sCAETHFlowPoints = "SCA_ETH_Flow_Points"
        case attName = "ATT_NAME"
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

    private enum CodingKeys: String, CodingKey {
        case mapMapOfString = "map_map_of_string"
        case mapOfEnumString = "map_of_enum_string"
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

    private enum CodingKeys: String, CodingKey {
        case arrayOfString = "array_of_string"
        case arrayArrayOfInteger = "array_array_of_integer"
        case arrayArrayOfModel = "array_array_of_model"
    }
}

 struct NumberOnly: Codable {
    var justNumber: Double?

    init(justNumber: Double? = nil) {
        self.justNumber = justNumber
    }

    private enum CodingKeys: String, CodingKey {
        case justNumber = "JustNumber"
    }
}

 struct ArrayOfNumberOnly: Codable {
    var arrayNumber: [Double]?

    init(arrayNumber: [Double]? = nil) {
        self.arrayNumber = arrayNumber
    }

    private enum CodingKeys: String, CodingKey {
        case arrayNumber = "ArrayNumber"
    }
}

 struct ArrayOfArrayOfNumberOnly: Codable {
    var arrayArrayNumber: [[Double]]?

    init(arrayArrayNumber: [[Double]]? = nil) {
        self.arrayArrayNumber = arrayArrayNumber
    }

    private enum CodingKeys: String, CodingKey {
        case arrayArrayNumber = "ArrayArrayNumber"
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

    private enum CodingKeys: String, CodingKey {
        case justSymbol = "just_symbol"
        case arrayEnum = "array_enum"
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

            private enum CodingKeys: String, CodingKey {
                case `enum`
                case renameMe = "rename-me"
            }
        }

        init(`enum`: Enum, renameMe: String, child: Child) {
            self.enum = `enum`
            self.renameMe = renameMe
            self.child = child
        }

        private enum CodingKeys: String, CodingKey {
            case `enum`
            case renameMe = "rename-me"
            case child
        }
    }

    init(child: Child? = nil, refChild: AnyJSON) {
        self.child = child
        self.refChild = refChild
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

            private enum CodingKeys: String, CodingKey {
                case `enum`
                case renameMe = "rename-me"
            }
        }

        init(`enum`: Enum, renameMe: String, child: Child) {
            self.enum = `enum`
            self.renameMe = renameMe
            self.child = child
        }

        private enum CodingKeys: String, CodingKey {
            case `enum`
            case renameMe = "rename-me"
            case child
        }
    }

    init(child: Child) {
        self.child = child
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

        private enum CodingKeys: String, CodingKey {
            case `enum`
            case renameMe = "rename-me"
        }
    }

    init(child: Child) {
        self.child = child
    }
}

enum AnyJSON: Equatable, Codable {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .array(array): try container.encode(array)
        case let .object(object): try container.encode(object)
        case let .string(string): try container.encode(string)
        case let .number(number): try container.encode(number)
        case let .bool(bool): try container.encode(bool)
        }
    }

    init(from decoder: Decoder) throws {
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
