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
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-default"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-default")
    }
    
    func testPestoreOnlySchemas() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-only-schemas",
            "--generate", "entities"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-only-schemas")
    }
    
    func testPestoreChangeFilename() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-change-filename",
            "--filename-template", "%0.generated.swift"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-change-filename")
    }
    
    func testPestoreSingleThreaded() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-single-threaded",
            "--single-threaded"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-single-threaded")
    }
    
    func testPetstoreDisablePackages() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path.appending("/petstore-no-package"),
            "--module", "Petstore"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-no-package")
    }
    
    func testPetstoreSplit() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-split",
            "--split"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-split")
    }
    
    func testPestoreAddCustomImport() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-custom-imports",
            "--config", config("""
            {
                "paths": {
                    "imports": ["APIClient", "HTTPHeaders", "CoreData"]
                }
            }
            """)
        ])

        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-custom-imports")
    }
    
    func testPestoreAddOperationId() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-operation-id",
            "--config", config("""
            {
                "paths": {
                    "isAddingOperationIds": true
                }
            }
            """)
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-operation-id")
    }
        
    func testPestoreGenerateClasses() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-generate-classes",
            "--config", config("""
            {
                "entities": {
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
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-some-entities-as-classes",
            "--config", config("""
            {
                "entities": {
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
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-some-entities-as-structs",
            "--config", config("""
            {
                "entities": {
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
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-base-class",
            "--config", config("""
            {
                "entities": {
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
    
    func testPetstoreDisableCommentsGeneration() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
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
    
    func testPetstoreDisableInitWithCoder() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-disable-init-with-coder",
            "--config", config("""
            {
                "entities": {
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
    
    func testPetstoreDisableInlining() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore"),
            "--output", temp.url.path,
            "--package", "petstore-disable-inlining",
            "--config", config("""
            {
                "isInliningPrimitiveTypes": false
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-disable-inlining")
    }
    
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
        
    func testEdgecasesRenamePrperties() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-rename-properties",
            "--config", config("""
            {
                "rename": {
                    "properties": {
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
    
    
    func testEdgecasesPassYAMLConfiguration() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-yaml-config",
            "--config", config("""
            rename:
                properties:
                    id: identifier
                    Category.name: title
                    Pet.status: state
                    complete: isDone
            """, ext: "yml")
            ])
            
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-yaml-config")
    }
    
    func testEdgecasesChangeAccessControl() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
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
                    
    func testEdgecasesDisableAcronyms() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-disable-acronyms",
            "--config", config("""
            {
                "isReplacingCommonAcronyms": false
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-disable-acronyms")
    }
    
    func testEdgecasesDisableEnumGeneration() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-disable-enums",
            "--config", config("""
            {
                "isGeneratingEnums": false
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-disable-enums")
    }
    
    func testEdgecasesRename() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-rename",
            "--config", config("""
            {
                "rename": {
                    "properties": {
                        "ContainerA.Child.Child.renameMe": "onlyItRenamed"
                    },
                    "entities": {
                        "ApiResponse": "APIResponse",
                        "Status": "State"
                    }
                }
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        // "Status" is not affected because it's an enum
        try compare(package: "edgecases-rename")
    }
    
    func testEdgecasesIndentWithTabs() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-tabs",
            "--config", config("""
            {
                "indentation": "tabs"
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-tabs")
    }
    
    func testEdgecasesIndentWithTwoWidthSpaces() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-indent-with-two-width-spaces",
            "--config", config("""
            {
                "spaceWidth": 2
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-indent-with-two-width-spaces")
    }
    
    func testEdgecasesEnableIntegerCapacity() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-int32-int64",
            "--config", config("""
            {
                "isUsingIntegersWithPredefinedCapacity": true
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-int32-int64")
    }
    
    func testEdgecasesGenerateCodingKeys() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-coding-keys",
            "--config", config("""
            entities:
                isUsingCustomCodingKeys: false
            """, ext: "yml")
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-coding-keys")
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
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "googlebooks"),
            "--output", temp.url.path,
            "--strict",
            "--package", "GoogleBooksAPI"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "GoogleBooksAPI")
    }
    
    func testGenerateTomTom() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "tomtom"),
            "--output", temp.url.path,
            "--strict",
            "--package", "TomTomAPI"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "TomTomAPI")
    }
    
    func testGeneratePostman() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "postman"),
            "--output", temp.url.path,
            "--strict",
            "--package", "PostmanAPI"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "PostmanAPI")
    }
    
    func testGenerateSimpleCart() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "simplecart"),
            "--output", temp.url.path,
            "--strict",
            "--package", "SimpleCartAPI"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "SimpleCartAPI")
    }
    
    func testGenerateTwitter() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "twitter"),
            "--output", temp.url.path,
            "--strict",
            "--package", "TwitterAPI"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "TwitterAPI")
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
