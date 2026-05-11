import XCTest
@testable import create_api

final class GenerateOptionsTests: GenerateTestCase {
    func testPetstoreReadsOverridesFromArguments() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-reads-overrides-from-arguments",
            arguments: [
                "--config-option", "entities.include=[Pet]",
                "--config-option", "entities.mutableProperties=false",
                "--config-option", "entities.filenameTemplate=Models.swift",
                "--config-option", "access=internal",
                "--config-option", "module=PetstoreKit"
            ],
            configuration: """
            generate: [entities]
            module: NotPetstoreKit
            mergeSources: true
            """
        )
    }

    func testPestoreOnlySchemas() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-only-schemas",
            configuration: """
            generate: [entities, package]
            """
        )
    }
    
    func testPetsStoreChangeEntityname() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-change-entityname",
            configuration: """
            entities:
              nameTemplate: "%0Generated"
            """
        )
    }
    
    func testPestoreSingleThreaded() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-single-threaded",
            arguments: [
                "--single-threaded"
            ]
        )
    }
    
    func testPetstoreDisablePackages() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-no-package",
            arguments: [
                "--config-option", "module=Petstore",
                "--config-option", "generate=[entities, paths]"
            ]
        )
    }
    
    func testPetstoreMergeSources() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-merge-sources",
            configuration: """
            mergeSources: true
            """
        )
    }
    
    func testPestoreAddCustomImport() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-custom-imports",
            testCompilationOnLinux: false, // custom imports aren't available there.
            configuration: """
            {
                "paths": {
                    "imports": ["Get", "HTTPHeaders", "CoreData"]
                },
                "entities": {
                    "imports": ["CoreLocation"]
                }
            }
            """
        )
    }
        
    func testPestoreGenerateClasses() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-generate-classes",
            configuration: """
            {
                "entities": {
                    "defaultType": "finalClass"
                }
            }
            """
        )
    }
    
    func testPestoreSomeEntitiesAsClasses() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-some-entities-as-classes",
            configuration: """
            {
                "entities": {
                    "typeOverrides": {
                        "Store": "finalClass"
                    }
                }
            }
            """
        )
    }
    
    func testPetstoreOverrideGenerateAsStructs() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-some-entities-as-structs",
            configuration: """
            {
                "entities": {
                    "defaultType": "finalClass",
                    "typeOverrides": {
                        "Error": "struct"
                    }
                }
            }
            """
        )
    }
    
    func testPetstoreBaseClass() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-base-class",
            configuration: """
            {
                "entities": {
                    "defaultType": "finalClass",
                    "baseClass": "NSObject"
                }
            }
            """
        )
    }
    
    func testPetstoreDisableCommentsGeneration() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-disable-comments",
            configuration: """
            {
                "commentOptions": false
            }
            """
        )
    }
    
    func testPetstoreDisableInitWithCoder() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-disable-init-with-coder",
            configuration: """
            {
                "entities": {
                    "alwaysIncludeDecodableImplementation": false
                }
            }
            """
        )
    }
    
    func testPetstoreDisableInlining() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-disable-inlining",
            configuration: """
            {
                "inlineTypealiases": false
            }
            """
        )
    }
    
    func testPetstoreDisableMutableProperties() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-disable-mutable-properties",
            configuration: """
            {
                "generate": ["entities", "package"],
                "entities": {
                    "typeOverrides": {
                        "Store": "finalClass"
                    },
                    "mutableProperties": false
                }
            }
            """
        )
    }
    
    func testPetstoreEnableMutableProperties() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-enable-mutable-properties",
            configuration: """
            {
                "generate": ["entities", "package"],
                "entities": {
                    "typeOverrides": {
                        "Store": "finalClass"
                    },
                    "mutableProperties": ["classes", "structs"],
                }
            }
            """
        )
    }

    func testPetstoreChangeNamespaceWhenRestStyle() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-change-namespace-when-rest-style",
            configuration: """
            {
                "paths": {
                    "style": "rest",
                    "namespace": "Namespace",
                }
            }
            """
        )
    }

    func testPetstoreChangeNamespaceWhenOperationsStyle() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-change-namespace-when-operations-style",
            configuration: """
            {
                "paths": {
                    "style": "operations",
                    "namespace": "Namespace",
                }
            }
            """
        )
    }
    
    func testPetstoreInternalAccessControl() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-change-access-control",
            configuration: """
            access: internal
            """
        )
    }
        
    func testEdgecasesRenameProperties() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-rename-properties",
            configuration: """
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
            """
        )
    }
    
    
    func testEdgecasesPassYAMLConfiguration() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-yaml-config",
            configuration: """
            rename:
                properties:
                    id: identifier
                    Category.name: title
                    Pet.status: state
                    complete: done
            """
        )
    }
                    
    func testEdgecasesDisableAcronyms() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-disable-acronyms",
            configuration: """
            {
                "acronyms": []
            }
            """
        )
    }
    
    func testEdgecasesDisableEnumGeneration() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-disable-enums",
            configuration: """
            {
                "generate": ["entities", "paths", "package"]
            }
            """
        )
    }

    func testEdgecasesEnumProtocols() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-enum-protocols",
            configuration: """
            {
                "enums": {
                    "protocols": ["Codable", "Hashable", "Sendable"]
                }
            }
            """
        )
    }
    
    func testEdgecasesRename() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-rename",
            configuration: """
            {
                "rename": {
                    "properties": {
                        "ContainerA.Child.Child.rename-me": "onlyItRenamed"
                    },
                    "entities": {
                        "ApiResponse": "APIResponse",
                        "Status": "State"
                    }
                }
            }
            """
        )
    }
    
    func testEdgecasesIndentWithTabs() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-tabs",
            configuration: """
            {
                "indentation": "tabs"
            }
            """
        )
    }
    
    func testEdgecasesIndentWithTwoWidthSpaces() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-indent-with-two-width-spaces",
            configuration: """
            {
                "spaceWidth": 2
            }
            """
        )
    }
    
    func testEdgecasesDataTypes() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-data-types",
            configuration: """
            useNativeDate: false
            dataTypes:
              string:
                date-time: AnyJSON
                byte: String
              integer:
                int32: Double
                int64: Int
            paths:
              includeResponseHeaders: false
            """
        )
    }

    func testEdgecasesMultipartFormdata() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-multipart-formdata",
            configuration: """
            generate: ["paths"]
            paths:
              useDataForMultipartFormDataRequestBody: false
            """
        )
    }

    
    func testEdgecasesGenerateCodingKeys() throws {
        try snapshot(
            spec: .edgecases,
            name: "edgecases-coding-keys",
            configuration: """
            entities:
                optimizeCodingKeys: false
            """
        )
    }

    func testStripNamePrefixNestedObjectsEnabled() throws {
        try snapshot(
            spec: .stripParentNameNestedObjects,
            name: "strip-parent-name-nested-objects-enabled",
            configuration: """
            entities:
                stripParentNameInNestedObjects: true
            """
        )
    }  

    func testStripNamePrefixNestedObjects() throws {
        try snapshot(
            spec: .stripParentNameNestedObjects,
            name: "strip-parent-name-nested-objects-default"
        )
    }
    
    func testPetstoreIdentifiableEnabled() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-identifiable",
            configuration: """
            generate:
            - entities
            - package
            entities:
                includeIdentifiableConformance: true
            rename:
                properties:
                    Error.code: id
            """
        )
    }
    
    func testPetstoreFilenameTemplate() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-filename-template",
            configuration: """
            entities:
                filenameTemplate: "%0Model.swift"
            paths:
                filenameTemplate: "%0API.swift"
            """
        )
    }
    
    func testPetstoreEntityExclude() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-entity-exclude",
            configuration: """
            generate: [entities, package]
            entities:
                exclude:
                - Error
                - Pet.id
                - Store.pets
            rename:
                properties:
                    Pet.id: not_id
                    Pet.name: id
            """
        )
    }
    
    func testPetstoreSPMImports() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-SPM-imports",
            testCompilationOnLinux: false, // custom imports aren't available there.
            arguments: [],
            configuration: """
            package:
                dependencies:
                - url: https://github.com/apple/swift-argument-parser
                  products:
                  - ArgumentParser
                  requirement:
                      exact:
                          version: 1.1.1
                - url: https://github.com/apple/swift-algorithms
                  products:
                  - Algorithms
                  requirement:
                      range:
                          from: 1.0.0
                          to: 2.0.0
                - url: https://github.com/apple/swift-metrics.git
                  products:
                  - Metrics
                  requirement:
                      closedRange:
                          from: 2.0.0
                          to: 2.9.1
                - url: https://github.com/apple/swift-log
                  products:
                  - Logging
                  requirement:
                      branch:
                          name: main
                - url: https://github.com/apple/swift-numerics
                  products:
                  - RealModule
                  - ComplexModule
                  requirement:
                      commit:
                          hash: 7f2d022d3d9b55bf812814f5d01896cbfa0fd4da
                - url: https://github.com/apple/swift-system
                  products:
                  - SystemPackage
                  requirement:
                      from:
                          version: 1.2.1
            """
        )
    }
    
    func testPetstoreSPMImportsLinux() throws {
        try snapshot(
            spec: .petstore,
            name: "petstore-SPM-imports-linux",
            arguments: [],
            configuration: """
            package:
                dependencies:
                - url: https://github.com/apple/swift-log
                  products:
                  - Logging
                  requirement:
                      branch:
                          name: main
                - url: https://github.com/apple/swift-numerics
                  products:
                  - RealModule
                  - ComplexModule
                  requirement:
                      commit:
                          hash: 7f2d022d3d9b55bf812814f5d01896cbfa0fd4da
            """
            )
    }

    func testFileHeaderComment() throws {
        try snapshot(
            spec: .petstore,
            name: "file-header-comment",
            configuration: """
            fileHeaderComment: |
              // Generated by Create API
              // https://github.com/CreateAPI/CreateAPI
              //
              // swiftformat:disable all
            generate: [entities]
            mergeSources: true
            entities:
              include:
              - Pet
            """
        )
    }
}
