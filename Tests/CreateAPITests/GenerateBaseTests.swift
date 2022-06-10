// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import XCTest
import OpenAPIKit30
@testable import create_api

class GenerateBaseTests: XCTestCase {
    var temp: TemporaryDirectory!
    
    override func setUp() {
        super.setUp()
        
        temp = TemporaryDirectory()
    }
    
    override func tearDown() {
        super.tearDown()
        
        temp.remove()
    }
    
    func testSpec(name: String, ext: String, package: String? = nil, config: String = "") throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: name, ext: ext),
            "--output", temp.url.path,
            "--package", package ?? name,
            "--config", self.config(config, ext: "yaml")
        ])

        // WHEN
        try command.run()
        
        // THEN
        try compare(package: package ?? name)
    }
    
    func compare(package: String, file: StaticString = #file, line: UInt = #line) throws {
        try create_api_tests.compare(expected: package, actual: temp.path(for: package), file: file, line: line)
    }
    
    func config(_ contents: String, ext: String = "json") -> String {
        let url = URL(fileURLWithPath: temp.path(for: "config.\(ext)"))
        try! contents.data(using: .utf8)!.write(to: url)
        return url.path
    }
}
