// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import class Foundation.Bundle
@testable import CreateAPI
import Yams

final class HelpersTests: XCTestCase {    
    func testTypeName() {
        let options = GenerateOptions()

        func typeName(_ rawString: String) -> String {
            TypeName(processing: rawString, options: options).rawValue
        }
        
        XCTAssertEqual(typeName("app"), "App")
        XCTAssertEqual(typeName("app-manifests"), "AppManifests")
        XCTAssertEqual(typeName("appManifests"), "AppManifests")
        
        XCTAssertEqual(typeName("CamelCase"), "CamelCase")
        XCTAssertEqual(typeName("camelCase"), "CamelCase")
        XCTAssertEqual(typeName("nsw"), "Nsw")
        XCTAssertEqual(typeName("NSW"), "Nsw")
        XCTAssertEqual(typeName("UBUNTU"), "Ubuntu")
        XCTAssertEqual(typeName("userURL"), "UserURL")
        XCTAssertEqual(typeName("url"), "URL")
        XCTAssertEqual(typeName("a-z"), "AZ")
        XCTAssertEqual(typeName("A-Z"), "AZ")
        XCTAssertEqual(typeName("123List"), "__123List")
        XCTAssertEqual(typeName("user_url"), "UserURL")
        XCTAssertEqual(typeName("snake_case"), "SnakeCase")
        XCTAssertEqual(typeName("SNAKE_CASE"), "SnakeCase")
        XCTAssertEqual(typeName("UserServiceDeviceHasAccessTo"), "UserServiceDeviceHasAccessTo")
        XCTAssertEqual(typeName("Won't"), "Wont")

        // Acronyms
        XCTAssertEqual(typeName("petId"), "PetID")
        XCTAssertEqual(typeName("pedIdentifer"), "PedIdentifer")
        XCTAssertEqual(typeName("gistUrl"), "GistURL")
        XCTAssertEqual(typeName("gistUrls"), "GistURLs")
        XCTAssertEqual(typeName("urlForGists"), "URLForGists")
        XCTAssertEqual(typeName("protocolHttpTest"), "ProtocolHTTPTest")
        XCTAssertEqual(typeName("protocolHttpsTest"), "ProtocolHTTPSTest")
        XCTAssertEqual(typeName("HttpTest"), "HTTPTest")
        XCTAssertEqual(typeName("HttpsTest"), "HTTPSTest")
        
        // Additional acronyms
        do {
            let options = GenerateOptions()
            options.addedAcronyms = ["nft"]
            XCTAssertEqual(TypeName(processing: "myNft", options: options).rawValue, "MyNFT")
        }
        
        // Keywords
        XCTAssertEqual(typeName("Type"), "`Type`")
        XCTAssertEqual(typeName("Self"), "`Self`")
        
        // Replacements
        XCTAssertEqual(typeName(">="), "GreaterThanOrEqualTo")
    }
    
    func testPropertyName() {
        let options = GenerateOptions()

        func propertyName(_ rawString: String) -> String {
            PropertyName(processing: rawString, options: options).rawValue
        }
        
        XCTAssertEqual(propertyName("CamelCase"), "camelCase")
        XCTAssertEqual(propertyName("app-manifests"), "appManifests")
        XCTAssertEqual(propertyName("{code}"), "code")
        XCTAssertEqual(propertyName("appManifests"), "appManifests")
        XCTAssertEqual(propertyName("avatar_url"), "avatarURL")
        XCTAssertEqual(propertyName("node_id"), "nodeID")
        XCTAssertEqual(propertyName("AppManifests"), "appManifests")

        XCTAssertEqual(propertyName("camelCase"), "camelCase")
        XCTAssertEqual(propertyName("NSW"), "nsw")
        XCTAssertEqual(propertyName("UserURL"), "userURL")
        XCTAssertEqual(propertyName("user_url"), "userURL")
        XCTAssertEqual(propertyName("url"), "url")
        XCTAssertEqual(propertyName("event-type"), "eventType")
        XCTAssertEqual(propertyName("a-z"), "aZ")
        XCTAssertEqual(propertyName("A-Z"), "aZ")
        XCTAssertEqual(propertyName("123List"), "_123List")
        XCTAssertEqual(propertyName("SNAKE_CASE"), "snakeCase")
        XCTAssertEqual(propertyName("snake_case"), "snakeCase")
        XCTAssertEqual(propertyName("UserServiceDeviceHasAccessTo"), "userServiceDeviceHasAccessTo")
        XCTAssertEqual(propertyName("UserService.getCustomerDevices"), "userServiceGetCustomerDevices")
        XCTAssertEqual(propertyName("won't"), "wont")
        
        // Abbreviations
        XCTAssertEqual(propertyName("petId"), "petID")
        XCTAssertEqual(propertyName("petIdentifer"), "petIdentifer")
        XCTAssertEqual(propertyName("gistUrl"), "gistURL")
        XCTAssertEqual(propertyName("gistUrls"), "gistURLs")
        XCTAssertEqual(propertyName("urlForGists"), "urlForGists")
        XCTAssertEqual(propertyName("protocolHttpTest"), "protocolHTTPTest")
        XCTAssertEqual(propertyName("protocolHttpsTest"), "protocolHTTPSTest")
        
        // Keywords
        XCTAssertEqual(propertyName("self"), "this")
        
        // Replacements
        XCTAssertEqual(propertyName(">="), "greaterThanOrEqualTo")
    }
    
    func testAsBoolean() {
        let options = GenerateOptions()
        
        func asBoolean(_ name: String) -> String {
            PropertyName(processing: name, options: options).asBoolean(options).rawValue
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
