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
    
    func testPestoreDetault() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-default"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-default")
    }
    
    func testPestoreGenerateClasses() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-generate-classes",
            "--config", config("""
            {
                "schemes": {
                    "isGeneratingStructs": false
                }
            }
            """)
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-generate-classes")
    }
    
    func testPestoreSomeEntitiesAsClasses() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-some-entities-as-classes",
            "--config", config("""
            {
                "schemes": {
                    "entitiesGeneratedAsClasses": ["Store"]
                }
            }
            """)
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-some-entities-as-classes")
    }
    
    func testPetstoreOverrideGenerateAsStructs() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-some-entities-as-structs",
            "--config", config("""
            {
                "schemes": {
                    "isGeneratingStructs": false,
                    "entitiesGeneratedAsStructs": ["Error"]
                }
            }
            """)
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-some-entities-as-structs")
    }
    
    func testPetstoreBaseClass() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-base-class",
            "--config", config("""
            {
                "schemes": {
                    "isGeneratingStructs": false,
                    "baseClass": "NSObject"
                }
            }
            """)
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-base-class")
    }
    
    func testBasicDisableCommentsGeneration() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-disable-comments",
            "--config", config("""
            {
                "comments": {
                    "isEnabled": false
                }
            }
            """)
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-disable-comments")
    }
    
    func testBasicDisableInitWithCoder() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-disable-init-with-coder",
            "--config", config("""
            {
                "schemes": {
                    "isGeneratingInitWithCoder": false
                }
            }
            """)
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-disable-init-with-coder")
    }
    
    func testEdgecasesDefault() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-default"
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-default")
    }
        
    func testEdgecasesRenamePrperties() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-rename-properties",
            "--config", config("""
            {
                "schemes": {
                    "mappedPropertyNames": {
                        "id": "identifier",
                        "Category.name": "title",
                        "Pet.status": "state",
                        "complete": "isDone",
                    }
                }
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        //
        // 1) "Category.name": "title",
        // Only Categy.name should be affected, but not anything else, e.g. Tag.name
        //
        // 2) "Pet.status": "state"
        // Check that enum name also changes
        //
        // 3) "complete": "isDone"
        // // Applied before boolean logic
        
        try compare(package: "edgecases-rename-properties")
    }
    
    func testEdgecasesChangeAccessControl() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-change-access-control",
            "--config", config("""
            {
                "access": ""
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-change-access-control")
    }
    
    func testBasicDisableInlining() {
        // GIVEN
        let spec = spec(named: "petstore")
        let options = GenerateOptions()
        options.isInliningPrimitiveTypes = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        CreateAPITests.compare(expected: "petstore-schemes-generate-disable-inlining", actual: output)
    }
        
    func testPetstoreExpanded() {
        // GIVEN
        let spec = spec(named: "petstore-expanded")
        let options = GenerateOptions()
        options.comments.isEnabled = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        CreateAPITests.compare(expected: "petstore-expanded-schemes-generate-default", actual: output)
    }
        
    func testPetstoreAllDisableAbbreviations() {
        // GIVEN
        let spec = spec(named: "petstore-all")
        let options = GenerateOptions()
        options.isReplacingCommonAcronyms = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
        
        // THEN
        CreateAPITests.compare(expected: "petstore-all-schemes-disable-common-abbreviations", actual: output)
    }
    
    func testPetstoreAllDisableEnumGeneration() {
        // GIVEN
        let spec = spec(named: "petstore-all")
        let options = GenerateOptions()
        options.isGeneratingEnums = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
        
        // THEN
        CreateAPITests.compare(expected: "petstore-all-schemes-disable-enums", actual: output)
    }
    
    func testPetstoreAllRename() {
        // GIVEN
        let spec = spec(named: "petstore-all")
        let options = GenerateOptions()
        options.schemes.mappedTypeNames = [
            "ApiResponse": "APIResponse",
            "Status": "State"
        ]
        options.schemes.mappedPropertyNames = [
            "ContainerA.Child.Child.renameMe": "onlyItRenamed"
        ]
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
        
        // THEN
        CreateAPITests.compare(expected: "petstore-all-schemes-map-types", actual: output)
    }
    
    func testPetstoreAllIndentWithTabs() {
        // GIVEN
        let spec = spec(named: "petstore-all")
        let options = GenerateOptions()
        options.indentation = .tabs
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
        
        // THEN
        CreateAPITests.compare(expected: "petstore-all-schemes-indent-with-tabs", actual: output)
    }
    
    func testPetstoreAllIndentWithTwoWidthSpaces() {
        // GIVEN
        let spec = spec(named: "petstore-all")
        let options = GenerateOptions()
        options.spaceWidth = 2
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
        
        // THEN
        CreateAPITests.compare(expected: "petstore-all-schemes-indent-with-two-width-spaces", actual: output)
    }
    
    func testGenerateGitHub() {
        // GIVEN
        let spec = spec(named: "github")
        let options = GenerateOptions()
        options.isInterpretingEmptyObjectsAsDictionary = true
        
        let arguments = GenerateArguments(
            isVerbose: false,
            isParallel: false,
            vendor: "github"
        )
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: arguments).run()
        
        // THEN
        CreateAPITests.compare(expected: "github-schemes-generate-default", actual: output)
    }
}

extension GenerateTests {
    func compare(package: String, file: StaticString = #file, line: UInt = #line) throws {
        try compare2(expected: package, actual: temp.path(for: package), file: file, line: line)
    }
    
    func config(_ contents: String) -> String {
        let url = URL(fileURLWithPath: temp.path(for: "config"))
        try! contents.data(using: .utf8)!.write(to: url)
        return url.path
    }
}

extension GenerateArguments {
    static let `default` = GenerateArguments(isVerbose: false, isParallel: false, vendor: nil)
}
