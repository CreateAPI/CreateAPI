// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import OpenAPIKit30
@testable import CreateAPI

final class GeneratePathsTests: XCTestCase {
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
        let output = GeneratePaths(spec: spec, options: options, arguments: arguments).run()
        
        // THEN
        compare(expected: "github-paths-default", actual: output)
    }
}

