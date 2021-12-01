// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import OpenAPIKit30
@testable import CreateAPI

final class GenerateSchemesTests: XCTestCase {
    func testGenerateWithDefaultOptions() {
        // GIVEN
        let spec = spec(named: "petstore")
        let options = GenerateOptions()
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-schemes-default", actual: output)
    }
    
    func testGenerateClasses() {
        // GIVEN
        let spec = spec(named: "petstore")
        let options = GenerateOptions()
        options.schemes.isGeneratingStructs = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-schemes-generate-classes", actual: output)
    }
    
    func testPetstoreOverrideGenerateAsClasses() {
        // GIVEN
        let spec = spec(named: "petstore")
        let options = GenerateOptions()
        options.schemes.entitiesGeneratedAsClasses = ["Store"]
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-schemes-entitites-generated-as-classes", actual: output)
    }
    
    func testPetstoreOverrideGenerateAsStructs() {
        // GIVEN
        let spec = spec(named: "petstore")
        let options = GenerateOptions()
        options.schemes.isGeneratingStructs = false
        options.schemes.entitiesGeneratedAsStructs = ["Error"]
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-schemes-entitites-generated-as-structs", actual: output)
    }
    
    func testPetstoreMapPropertyNames() {
        // GIVEN
        let spec = spec(named: "petstore-all")
        let options = GenerateOptions()
        options.schemes.mappedPropertyNames = [
            "id": "identifier",
            "Category.name": "title", // Only Categy.name should be affected, but not anything else, e.g. Tag.name
            "Pet.status": "state", // Check that enum name also changes
            "complete": "isDone" // Applied before boolean logic
        ]
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-schemes-mapped-property-names", actual: output)
    }
    
    func testPetstoreGenerateClassesWithBaseClass() {
        // GIVEN
        let spec = spec(named: "petstore")
        let options = GenerateOptions()
        options.schemes.isGeneratingStructs = false
        options.schemes.baseClass = "NSObject"
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-schemes-generate-classes-with-base", actual: output)
    }
    
    func testChangeAccessControl() {
        // GIVEN
        let spec = spec(named: "petstore")
        let options = GenerateOptions()
        options.access = nil
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-schemes-generate-internal-default", actual: output)
    }
    
    func testDisableCommentsGeneration() {
        // GIVEN
        let spec = spec(named: "petstore")
        let options = GenerateOptions()
        options.isGeneratingComments = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-schemes-generate-disable-comments", actual: output)
    }
    
    func testDisableInitWithCoder() {
        // GIVEN
        let spec = spec(named: "petstore")
        let options = GenerateOptions()
        options.schemes.isGeneratingInitWithCoder = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-schemes-generate-disable-init-with-code", actual: output)
    }
    
    func testPetstoreDisableInlining() {
        // GIVEN
        let spec = spec(named: "petstore")
        let options = GenerateOptions()
        options.isInliningPrimitiveTypes = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-schemes-generate-disable-inlining", actual: output)
    }
    
    func testPetstoreExpanded() {
        // GIVEN
        let spec = spec(named: "petstore-expanded")
        let options = GenerateOptions()
        options.isGeneratingComments = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
                
        // THEN
        compare(expected: "petstore-expanded-schemes-generate-default", actual: output)
    }
    
    func testPetstoreAllDefault() {
        // GIVEN
        let spec = spec(named: "petstore-all")
        let options = GenerateOptions()
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
        
        // THEN
        compare(expected: "petstore-all-schemes-generate-default", actual: output)
    }
    
    func testPetstoreAllDisableAbbreviations() {
        // GIVEN
        let spec = spec(named: "petstore-all")
        let options = GenerateOptions()
        options.isReplacingCommonAbbreviations = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
        
        // THEN
        compare(expected: "petstore-all-schemes-disable-common-abbreviations", actual: output)
    }
    
    func testPetstoreAllDisableEnumGeneration() {
        // GIVEN
        let spec = spec(named: "petstore-all")
        let options = GenerateOptions()
        options.isGeneratingEnums = false
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
        
        // THEN
        compare(expected: "petstore-all-schemes-disable-enums", actual: output)
    }
    
    func testPetstoreMappedTypeNames() {
        // GIVEN
        let spec = spec(named: "petstore-all")
        let options = GenerateOptions()
        options.schemes.mappedTypeNames = [
            "ApiResponse": "APIResponse",
            "Status": "State"
        ]
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: .default).run()
        
        // THEN
        compare(expected: "petstore-all-schemes-map-types", actual: output)
    }

    func testGenerateGitHub() {
        // GIVEN
        let spec = spec(named: "github")
        let options = GenerateOptions()
        
        let arguments = GenerateArguments(
            isVerbose: false,
            isParallel: false,
            vendor: "github"
        )
        
        // WHEN
        let output = GenerateSchemas(spec: spec, options: options, arguments: arguments).run()
        
        // THEN
        compare(expected: "github-schemes-generate-default", actual: output)
    }
}

extension GenerateArguments {
    static let `default` = GenerateArguments(isVerbose: false, isParallel: false, vendor: nil)
}
