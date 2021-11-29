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
        let output = GenerateSchemes(spec: spec, options: options, verbose: false).run()
                
        // THEN
        compare(expected: "petstore-schemes-default", actual: output)
    }
}

