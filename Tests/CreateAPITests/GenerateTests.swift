// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import OpenAPIKit30
@testable import CreateAPI

final class GenerateTests: GenerateBaseTests {
    func testPestore() throws {
        try testSpec(name: "petstore", package: "petstore-default")
    }
    
    func testEdgecases() throws {
        try testSpec(name: "edgecases", package: "edgecases-default")
    }
    
    func testGitHub() throws {
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
              enumCases:
                reactions-+1: "reactionsPlusOne"
                reactions--1: "reactionsMinusOne"
            """, ext: "yml")
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "OctoKit")
    }
    
    func testGoogleBooks() throws {
        try testSpec(name: "googlebooks", package: "GoogleBooksAPI")
    }
    
    func testTomTom() throws {
        try testSpec(name: "tomtom", package: "TomTomAPI")
    }
    
    func testPostman() throws {
        try testSpec(name: "postman", package: "PostmanAPI")
    }
    
    func testSimpleCart() throws {
        try testSpec(name: "simplecart", package: "SimpleCartAPI")
    }
    
    func testTwitter() throws {
        try testSpec(name: "twitter", package: "TwitterAPI")
    }
    
    func testOnePasswordConnect() throws {
        try testSpec(name: "onepassword", package: "OnePasswordAPI")
    }
    
    func testAuthentiq() throws {
        try testSpec(name: "authentiq", package: "AuthentiqAPI")
    }
    
    func testPlatform() throws {
        try testSpec(name: "platform", package: "PlatformAPI")
    }
    
    func testEbayFinances() throws {
        try testSpec(name: "ebay-finances", package: "EbayFinancesAPI")
    }
    
    func testAppStoreConnect() throws {
        try testSpec(name: "app-store-connect", package: "AppStoreConnectAPI")
    }
    
    func testAsana() throws {
        try testSpec(name: "asana", package: "AsanaAPI")
    }
    
    func testJira() throws {
        try testSpec(name: "jira", package: "JiraAPI")
    }

    func testBitbucket() throws {
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
    
    func testNYTArchives() throws {
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
    
    func testSoundcloud() throws {
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
}
