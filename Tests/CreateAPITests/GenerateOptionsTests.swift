// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
import OpenAPIKit30
@testable import create_api

final class GenerateOptionsTests: GenerateBaseTests {
    func testPestoreOnlySchemas() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore", ext: "yaml"),
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
            pathForSpec(named: "petstore", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "petstore-change-filename",
            "--filename-template", "%0.generated.swift"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-change-filename")
    }
    
    func testPetsStoreChangeEntityname() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "petstore-change-entityname",
            "--entityname-template", "%0Generated"
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-change-entityname")
    }
    
    func testPestoreSingleThreaded() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore", ext: "yaml"),
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
            pathForSpec(named: "petstore", ext: "yaml"),
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
            pathForSpec(named: "petstore", ext: "yaml"),
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
            pathForSpec(named: "petstore", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "petstore-custom-imports",
            "--config", config("""
            {
                "paths": {
                    "imports": ["Get", "HTTPHeaders", "CoreData"]
                },
                "entities": {
                    "imports": ["CoreLocation"]
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
            pathForSpec(named: "petstore", ext: "yaml"),
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
            pathForSpec(named: "petstore", ext: "yaml"),
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
            pathForSpec(named: "petstore", ext: "yaml"),
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
            pathForSpec(named: "petstore", ext: "yaml"),
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
            pathForSpec(named: "petstore", ext: "yaml"),
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
            pathForSpec(named: "petstore", ext: "yaml"),
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
            pathForSpec(named: "petstore", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "petstore-disable-init-with-coder",
            "--config", config("""
            {
                "entities": {
                    "isGeneratingInitWithDecoder": false
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
            pathForSpec(named: "petstore", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "petstore-disable-inlining",
            "--config", config("""
            {
                "isInliningTypealiases": false
            }
            """)
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-disable-inlining")
    }
    
    func testPetstoreDisableMutableProperties() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore", ext: "yaml"),
            "--generate", "entities",
            "--output", temp.url.path,
            "--package", "petstore-disable-mutable-properties",
            "--config", config("""
            {
                "entities": {
                    "entitiesGeneratedAsClasses": ["Store"],
                    "isGeneratingMutableClassProperties": false,
                    "isGeneratingMutableStructProperties": false
                }
            }
            """)
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-disable-mutable-properties")
    }
    
    func testPetstoreEnableMutableProperties() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore", ext: "yaml"),
            "--generate", "entities",
            "--output", temp.url.path,
            "--package", "petstore-enable-mutable-properties",
            "--config", config("""
            {
                "entities": {
                    "entitiesGeneratedAsClasses": ["Store"],
                    "isGeneratingMutableClassProperties": true,
                    "isGeneratingMutableStructProperties": true
                }
            }
            """)
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-enable-mutable-properties")
    }

    func testPetstoreChangeNamespaceWhenRestStyle() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "petstore-change-namespace-when-rest-style",
            "--config", config("""
            {
                "paths": {
                    "style": "rest",
                    "namespace": "Namespace",
                }
            }
            """)
        ])

        // WHEN
        try command.run()

        // THEN
        try compare(package: "petstore-change-namespace-when-rest-style")
    }

    func testPetstoreChangeNamespaceWhenOperationsStyle() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "petstore-change-namespace-when-operations-style",
            "--config", config("""
            {
                "paths": {
                    "style": "operations",
                    "namespace": "Namespace",
                }
            }
            """)
        ])

        // WHEN
        try command.run()

        // THEN
        try compare(package: "petstore-change-namespace-when-operations-style")
    }
        
    func testEdgecasesRenamePrperties() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases", ext: "yaml"),
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
            pathForSpec(named: "edgecases", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "edgecases-yaml-config",
            "--config", config("""
            rename:
                properties:
                    id: identifier
                    Category.name: title
                    Pet.status: state
                    complete: isDone
            """, ext: "yaml")
            ])
            
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-yaml-config")
    }
    
    func testEdgecasesChangeAccessControl() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "edgecases", ext: "yaml"),
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
            pathForSpec(named: "edgecases", ext: "yaml"),
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
            pathForSpec(named: "edgecases", ext: "yaml"),
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
            pathForSpec(named: "edgecases", ext: "yaml"),
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
            pathForSpec(named: "edgecases", ext: "yaml"),
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
            pathForSpec(named: "edgecases", ext: "yaml"),
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
            pathForSpec(named: "edgecases", ext: "yaml"),
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
            pathForSpec(named: "edgecases", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "edgecases-coding-keys",
            "--config", config("""
            entities:
                isGeneratingCustomCodingKeys: false
            """, ext: "yaml")
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "edgecases-coding-keys")
    }

    func testStripNamePrefixNestedObjectsEnabled() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "strip-parent-name-nested-objects", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "strip-parent-name-nested-objects-enabled",
            "--config", config("""
            entities:
                isStrippingParentNameInNestedObjects: true
            """, ext: "yaml")
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "strip-parent-name-nested-objects-enabled")
    }  

    func testStripNamePrefixNestedObjects() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "strip-parent-name-nested-objects", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "strip-parent-name-nested-objects-default"
        ])
                
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "strip-parent-name-nested-objects-default")
    }
    
    func testPestoreIdentifiableEnabled() throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: "petstore", ext: "yaml"),
            "--output", temp.url.path,
            "--package", "petstore-identifiable",
            "--generate", "entities",
            "--config", config("""
            entities:
                isGeneratingIdentifiableConformance: true
            """, ext: "yaml")
        ])
        
        // WHEN
        try command.run()
        
        // THEN
        try compare(package: "petstore-identifiable")
    }
}
