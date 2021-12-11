// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import OpenAPIKit30
@testable import CreateAPI

#warning("TODO: make sure Package.swift and .switfpm are ignored")
#warning("TODO: test that when build fails, test-generated fails")

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
    
    func testPestoreAddCustomImport() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "petstore"),
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
            "--input", pathForSpec(named: "petstore"),
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
    
    func testPetstoreDisableCommentsGeneration() throws {
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
    
    func testPetstoreDisableInitWithCoder() throws {
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
    
    func testPetstoreDisableInlining() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "petstore"),
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
                
    func testEdgecasesDisableAcronyms() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "edgecases"),
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
            "--input", pathForSpec(named: "edgecases"),
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
            "--input", pathForSpec(named: "edgecases"),
            "--output", temp.url.path,
            "--package", "edgecases-rename",
            "--config", config("""
            {
                "schemes": {
                    "mappedTypeNames": {
                        "ApiResponse": "APIResponse",
                        "Status": "State"
                    },
                    "mappedPropertyNames": {
                        "ContainerA.Child.Child.renameMe": "onlyItRenamed"
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
            "--input", pathForSpec(named: "edgecases"),
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
            "--input", pathForSpec(named: "edgecases"),
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
    
    func testGenerateGitHub() throws {
        // GIVEN
        let command = try Generate.parse([
            "--input", pathForSpec(named: "github"),
            "--output", temp.url.path,
            "--package", "github",
            "--vendor", "github",
            "--config", config("""
            {
                "isInterpretingEmptyObjectsAsDictionary": true,
                "pluralizationExceptions": ["ConfigWas", "EventsWere"]
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "github")
    }
}

extension GenerateTests {
    func compare(package: String, file: StaticString = #file, line: UInt = #line) throws {
        try CreateAPITests.compare(expected: package, actual: temp.path(for: package), file: file, line: line)
    }
    
    func config(_ contents: String) -> String {
        let url = URL(fileURLWithPath: temp.path(for: "config"))
        try! contents.data(using: .utf8)!.write(to: url)
        return url.path
    }
}
