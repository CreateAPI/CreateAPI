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
        
        XCTAssertEqual(TypeName("CamelCase").rawValue, "CamelCase")
        XCTAssertEqual(TypeName("camelCase").rawValue, "CamelCase")
        XCTAssertEqual(TypeName("nsw").rawValue, "Nsw")
        XCTAssertEqual(TypeName("NSW").rawValue, "Nsw")
        XCTAssertEqual(TypeName("UBUNTU").rawValue, "Ubuntu")
        XCTAssertEqual(TypeName("userURL").rawValue, "UserURL")
        XCTAssertEqual(TypeName("url").rawValue, "URL")
        XCTAssertEqual(TypeName("a-z").rawValue, "AZ")
        XCTAssertEqual(TypeName("A-Z").rawValue, "AZ")
        XCTAssertEqual(TypeName("123List").rawValue, "_123List")
        XCTAssertEqual(TypeName("user_url").rawValue, "UserURL")
        XCTAssertEqual(TypeName("snake_case").rawValue, "SnakeCase")
        XCTAssertEqual(TypeName("SNAKE_CASE").rawValue, "SnakeCase")
        XCTAssertEqual(TypeName("UserServiceDeviceHasAccessTo").rawValue, "UserServiceDeviceHasAccessTo")
        XCTAssertEqual(TypeName("Won't").rawValue, "Wont")
    }
    
    func testPropertyName() {
        XCTAssertEqual(PropertyName("CamelCase").rawValue, "camelCase")
        XCTAssertEqual(PropertyName("app-manifests").rawValue, "appManifests")
        XCTAssertEqual(PropertyName("{code}").rawValue, "code")
        XCTAssertEqual(PropertyName("appManifests").rawValue, "appManifests")
        XCTAssertEqual(PropertyName("avatar_url").rawValue, "avatarURL")
        XCTAssertEqual(PropertyName("node_id").rawValue, "nodeID")
        XCTAssertEqual(PropertyName("AppManifests").rawValue, "appManifests")

        XCTAssertEqual(PropertyName("camelCase").rawValue, "camelCase")
        XCTAssertEqual(PropertyName("NSW").rawValue, "nsw")
        XCTAssertEqual(PropertyName("UserURL").rawValue, "userURL")
        XCTAssertEqual(PropertyName("user_url").rawValue, "userURL")
        XCTAssertEqual(PropertyName("url").rawValue, "url")
        XCTAssertEqual(PropertyName("event-type").rawValue, "eventType")
        XCTAssertEqual(PropertyName("a-z").rawValue, "aZ")
        XCTAssertEqual(PropertyName("A-Z").rawValue, "aZ")
        XCTAssertEqual(PropertyName("123List").rawValue, "_123List")
        XCTAssertEqual(PropertyName("SNAKE_CASE").rawValue, "snakeCase")
        XCTAssertEqual(PropertyName("snake_case").rawValue, "snakeCase")
        XCTAssertEqual(PropertyName("UserServiceDeviceHasAccessTo").rawValue, "userServiceDeviceHasAccessTo")
        XCTAssertEqual(PropertyName("UserService.getCustomerDevices").rawValue, "userServiceGetCustomerDevices")
        XCTAssertEqual(PropertyName("won't").rawValue, "wont")
    }
}
