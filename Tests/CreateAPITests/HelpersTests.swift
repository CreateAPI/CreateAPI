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

        // Abbreviations
        XCTAssertEqual(TypeName("petId").rawValue, "PetID")
        XCTAssertEqual(TypeName("pedIdentifer").rawValue, "PedIdentifer")
        XCTAssertEqual(TypeName("gistUrl").rawValue, "GistURL")
        XCTAssertEqual(TypeName("gistUrls").rawValue, "GistURLs")
        XCTAssertEqual(TypeName("urlForGists").rawValue, "URLForGists")
        XCTAssertEqual(TypeName("protocolHttpTest").rawValue, "ProtocolHTTPTest")
        XCTAssertEqual(TypeName("protocolHttpsTest").rawValue, "ProtocolHTTPSTest")
        XCTAssertEqual(TypeName("HttpTest").rawValue, "HTTPTest")
        XCTAssertEqual(TypeName("HttpsTest").rawValue, "HTTPSTest")
        
        // Keywords
        XCTAssertEqual(TypeName("Type").rawValue, "`Type`")
        XCTAssertEqual(TypeName("Self").rawValue, "`Self`")
        
        // Replacements
        XCTAssertEqual(TypeName(">=").rawValue, "GreaterThanOrEqualTo")
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
        
        // Abbreviations
        XCTAssertEqual(PropertyName("petId").rawValue, "petID")
        XCTAssertEqual(PropertyName("petIdentifer").rawValue, "petIdentifer")
        XCTAssertEqual(PropertyName("gistUrl").rawValue, "gistURL")
        XCTAssertEqual(PropertyName("gistUrls").rawValue, "gistURLs")
        XCTAssertEqual(PropertyName("urlForGists").rawValue, "urlForGists")
        XCTAssertEqual(PropertyName("protocolHttpTest").rawValue, "protocolHTTPTest")
        XCTAssertEqual(PropertyName("protocolHttpsTest").rawValue, "protocolHTTPSTest")
        
        // Keywords
        XCTAssertEqual(PropertyName("self").rawValue, "`self`")
        
        // Replacements
        XCTAssertEqual(PropertyName(">=").rawValue, "greaterThanOrEqualTo")
    }
    
    func testAsBoolean() {
        func asBoolean(_ name: String) -> String {
            PropertyName(name).asBoolean().rawValue
        }
        
        // Simple
        XCTAssertEqual(asBoolean("redelivery"), "isRedelivery")
        XCTAssertEqual(asBoolean("siteAdmin"), "isSiteAdmin")
        XCTAssertEqual(asBoolean("archived"), "isArchived")
        
        // Keywords (have ticks)
        XCTAssertEqual(asBoolean("private"), "isPrivate") // Ticks
        
        // Exceptions (first word)
        XCTAssertEqual(asBoolean("hasChanges"), "hasChanges")
        XCTAssertEqual(asBoolean("allowRebase"), "allowRebase")
        XCTAssertEqual(asBoolean("allowsRebase"), "allowsRebase")
        XCTAssertEqual(asBoolean("enableMerges"), "enableMerges")
        XCTAssertEqual(asBoolean("enablesMerges"), "enablesMerges")
        XCTAssertEqual(asBoolean("canMerge"), "canMerge")
        XCTAssertEqual(asBoolean("useLFS"), "useLFS")
        XCTAssertEqual(asBoolean("dismissStaleReviews"), "dismissStaleReviews")
        XCTAssertEqual(asBoolean("dismissesStaleReviews"), "dismissesStaleReviews")
        XCTAssertEqual(asBoolean("requireCodeOwnerReviews"), "requireCodeOwnerReviews")
        XCTAssertEqual(asBoolean("requiresCodeOwnerReviews"), "requiresCodeOwnerReviews")
        // See `booleanExceptions`, no reason to test configuration
        
        // Exceptinons (not the first word)
        XCTAssertEqual(asBoolean("changesHas"), "changesHas")
        XCTAssertEqual(asBoolean("dnsResolves"), "dnsResolves")
        XCTAssertEqual(asBoolean("activeWas"), "activeWas") // yes
        XCTAssertEqual(asBoolean("maintainerCanModify"), "maintainerCanModify")
        XCTAssertEqual(asBoolean("currentUserCanApprove"), "currentUserCanApprove")
        XCTAssertEqual(asBoolean("memberCanCreateInternalRepositories"), "memberCanCreateInternalRepositories")
        
        // Uppercasing
        XCTAssertEqual(asBoolean("httpsEnforced"), "isHTTPSEnforced")
    }
}
