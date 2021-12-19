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
    
    func testPestoreDefault() throws {
        try testSpec(name: "petstore", package: "petstore-default")
    }
    
    // TODO: Switch to --strict and fix multipart-form-data
    func testEdgecasesDefault() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-default"
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-default")
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
