// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
import OpenAPIKit30
@testable import create_api

final class GenerateFeaturesTests: GenerateBaseTests {    
    func testQueryParameters() throws {
        try testSpec(name: "test-query-parameters")
    }
}
