// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import class Foundation.Bundle
@testable import CreateAPI

final class HelpersTests: XCTestCase {    
    func testTypeName() {
        XCTAssertEqual(TypeName("app").rawValue, "App")
        XCTAssertEqual(TypeName("app-manifests").rawValue, "AppManifests")
        XCTAssertEqual(TypeName("appManifests").rawValue, "AppManifests")
    }
    
    func testPropertyName() {
        XCTAssertEqual(PropertyName("app").rawValue, "app")
        XCTAssertEqual(PropertyName("app-manifests").rawValue, "appManifests")
        XCTAssertEqual(PropertyName("{code}").rawValue, "code")
        XCTAssertEqual(PropertyName("appManifests").rawValue, "appManifests")
        XCTAssertEqual(PropertyName("avatar_url").rawValue, "avatarURL")
        XCTAssertEqual(PropertyName("node_id").rawValue, "nodeID")
    }
}

#warning("TODO:")
//
//try expect("CamelCase".lowerCamelCased()) == "camelCase"
//try expect("camelCase".lowerCamelCased()) == "camelCase"
//try expect("NSW".lowerCamelCased()) == "nsw"
//try expect("UserURL".lowerCamelCased()) == "userURL"
//try expect("user_url".lowerCamelCased()) == "userURL"
//try expect("url".lowerCamelCased()) == "url"
//try expect("event-type".lowerCamelCased()) == "eventType"
//try expect("a-z".lowerCamelCased()) == "az"
//try expect("A-Z".lowerCamelCased()) == "aZ"
//try expect("SNAKE_CASE".lowerCamelCased()) == "snakeCase"
//try expect("snake_case".lowerCamelCased()) == "snakeCase"
//try expect("UserServiceDeviceHasAccessTo".lowerCamelCased()) == "userServiceDeviceHasAccessTo"
//try expect("UserService.getCustomerDevices".lowerCamelCased()) == "userServiceGetCustomerDevices"
//}
//$0.it("upper camelcases") {
//try expect("CamelCase".upperCamelCased()) == "CamelCase"
//try expect("camelCase".upperCamelCased()) == "CamelCase"
//try expect("nsw".upperCamelCased()) == "Nsw"
//try expect("NSW".upperCamelCased()) == "NSW"
//try expect("userURL".upperCamelCased()) == "UserURL"
//try expect("url".upperCamelCased()) == "URL"
//try expect("a-z".upperCamelCased()) == "Az"
//try expect("A-Z".upperCamelCased()) == "AZ"
//try expect("user_url".upperCamelCased()) == "UserURL"
//try expect("snake_case".upperCamelCased()) == "SnakeCase"
//try expect("SNAKE_CASE".upperCamelCased()) == "SnakeCase"
//try expect("UserServiceDeviceHasAccessTo".upperCamelCased()) == "UserServiceDeviceHasAccessTo"
