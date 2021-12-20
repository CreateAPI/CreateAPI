// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import OpenAPIKit30
@testable import CreateAPI

final class GenerateTests: XCTestCase {
    var temp: TemporaryDirectory!
    
    override func setUp() {
        super.setUp()
        
        temp = TemporaryDirectory()
    }
    
    override func tearDown() {
        super.tearDown()
        
        temp.remove()
    }
    
    func testPestore() throws {
        try testSpec(name: "petstore", package: "petstore-default")
    }
    
    func testEdgecases() throws {
        try testSpec(name: "edgecases", package: "edgecases-default")
    }

    func testGenerateGitHub() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "github"),
            "--output", temp.url.path,
            "--strict",
            "--package", "OctoKit",
            "--vendor", "github",
            "--config", config("""
            isInterpretingEmptyObjectsAsDictionaries: true
            pluralizationExceptions: ["ConfigWas", "EventsWere"]
            paths:
              overrideResponses:
                accepted: "Void"
            rename:
              enumCaseNames:
                reactions-+1: "reactionsPlusOne"
                reactions--1: "reactionsMinusOne"
            """, ext: "yml")
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "OctoKit")
    }
    
    func testGenerateGoogleBooks() throws {
        try testSpec(name: "googlebooks", package: "GoogleBooksAPI")
    }
    
    func testGenerateTomTom() throws {
        try testSpec(name: "tomtom", package: "TomTomAPI")
    }
    
    func testGeneratePostman() throws {
        try testSpec(name: "postman", package: "PostmanAPI")
    }
    
    func testGenerateSimpleCart() throws {
        try testSpec(name: "simplecart", package: "SimpleCartAPI")
    }
    
    func testGenerateTwitter() throws {
        try testSpec(name: "twitter", package: "TwitterAPI")
    }
    
    func testGenerateOnePasswordConnect() throws {
        try testSpec(name: "onepassword", package: "OnePasswordAPI")
    }
    
    func testGenerateAuthentiq() throws {
        try testSpec(name: "authentiq", package: "AuthentiqAPI")
    }
    
    func testGeneratePlatform() throws {
        try testSpec(name: "platform", package: "PlatformAPI")
    }
    
    func testGenerateEbayFinances() throws {
        try testSpec(name: "ebay-finances", package: "EbayFinancesAPI")
    }
    
    // TODO: Update with the latest version (https://developer.apple.com/documentation/appstoreconnectapi)
    // when `gzip` and duplicated `- $ref: "#/components/schemas/AppCategory"` are fixed
    func testGenerateAppStoreConnect() throws {
        try testSpec(name: "app-store-connect", package: "AppStoreConnectAPI")
    }
    
    func testGenerateAsana() throws {
        try testSpec(name: "asana", package: "AsanaAPI")
    }
    
    // TODO: Update when https://github.com/mattpolzin/OpenAPIKit/issues/239 is addressed
    // TODO: Upadte when https://github.com/jpsim/Yams/issues/337 is addressed
    // Spec URL: https://developer.atlassian.com/cloud/jira/platform/swagger-v3.v3.json
    func testJira() throws {
        try testSpec(name: "jira", package: "Jira")
    }
    
    // TODO: Can we automatically resolve these conflicts?
    // - "/repositories/{workspace}/{repo_slug}/pipelines-config/
    // - "/repositories/{workspace}/{repo_slug}/pipelines_config/
    func _testGenerateBitbucket() throws {
        try testSpec(name: "bitbucket", package: "BitbucketAPI")
    }
    
    // TODO: Add application/json-patch+json support
    func _testGenerateBox() throws {
        try testSpec(name: "box", package: "BoxAPI")
    }
    
    func testCircleCI() throws {
        try testSpec(name: "circle-ci", package: "CircleCIAPI")
    }
    
    func testCrucible() throws {
        try testSpec(name: "crucible", package: "CrucibleAPI")
    }
    
    func testInstagram() throws {
        try testSpec(name: "instagram", package: "InstagramAPI")
    }
    
    func testNYTArchive() throws {
        try testSpec(name: "nyt-archive", package: "NYTArchiveAPI")
    }
    
    func testNYTArticleSearch() throws {
        try testSpec(name: "nyt-article-search", package: "NYTArticleSearchAPI")
    }
    
    func testNYTBooks() throws {
        try testSpec(name: "nyt-books", package: "NYTBooksAPI")
    }
    
    func testNYTCommunity() throws {
        try testSpec(name: "nyt-community", package: "NYTCommunityAPI")
    }
    
    func testSpec(name: String, package: String, config: String = "") throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: name),
            "--output", temp.url.path,
            "--strict",
            "--package", package,
            "--config", self.config(config, ext: "yml")
        ])

        // WHEN
        try command.run()
        
        // THEN
        try compare(package: package)
    }
}

extension GenerateTests {
    func compare(package: String, file: StaticString = #file, line: UInt = #line) throws {
        try CreateAPITests.compare(expected: package, actual: temp.path(for: package), file: file, line: line)
    }
    
    func config(_ contents: String, ext: String = "json") -> String {
        let url = URL(fileURLWithPath: temp.path(for: "config.\(ext)"))
        try! contents.data(using: .utf8)!.write(to: url)
        return url.path
    }
}
