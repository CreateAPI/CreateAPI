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
    // when duplicated `- $ref: "#/components/schemas/AppCategory"` are fixed
    func testGenerateAppStoreConnect() throws {
        try testSpec(name: "app-store-connect", package: "AppStoreConnectAPI")
    }
    
    func testGenerateAsana() throws {
        try testSpec(name: "asana", package: "AsanaAPI")
    }
    
    func testJira() throws {
        try testSpec(name: "jira", package: "JiraAPI")
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
    
    func testNYTArchiveS() throws {
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
    
    func testOpenBanking() throws {
        try testSpec(name: "open-banking", package: "OpenBankingAPI")
    }
    
    func testSlack() throws {
        try testSpec(name: "slack", package: "SlackAPI")
    }
    
    // TODO: Add support for query-encoding objects and uncomment
    func _testSoundcloud() throws {
        try testSpec(name: "soundcloud", package: "SoundcloudAPI")
    }
    
    func testSpotify() throws {
        try testSpec(name: "spotify", package: "SpotifyAPI")
    }
    
    func testSquare() throws {
        try testSpec(name: "square", package: "SquareAPI")
    }
    
    func testStackExchange() throws {
        try testSpec(name: "stackexchange", package: "StackExchangeAPI")
    }
    
    // TODO: Add support for query-encoding objects and uncomment
    func _testStripe() throws {
        try testSpec(name: "stripe", package: "StripeAPI")
    }
    
    func testTelegramBot() throws {
        try testSpec(name: "telegram-bot", package: "TelegramBotPI")
    }
    
    func testTicketMaster() throws {
        try testSpec(name: "ticketmaster", package: "TicketmasterAPI")
    }
    
    func testTrello() throws {
        try testSpec(name: "trello", package: "TrelloAPI")
    }
    
    func testTwilio() throws {
        try testSpec(name: "twilio", package: "TwilioAPI")
    }
    
    func testWikimedia() throws {
        try testSpec(name: "wikimedia", package: "WikimediaAPI")
    }
    
    // TODO: Fix nested types duplication and reenable
    func _testZoom() throws {
        try testSpec(name: "zoom", package: "ZoomAPI")
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
