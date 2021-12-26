// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import OpenAPIKit30
@testable import CreateAPI

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
    
    func testSpec(name: String, package: String? = nil, config: String = "") throws {
        // GIVEN
        let command = try Generate.parse([
            pathForSpec(named: name),
            "--output", temp.url.path,
            "--strict",
            // "--single-threaded",
            "--package", package ?? name,
            "--config", self.config(config, ext: "yml")
        ])

        // WHEN
        try command.run()
        
        // THEN
        try compare(package: package ?? name)
    }
    
    func compare(package: String, file: StaticString = #file, line: UInt = #line) throws {
        try CreateAPITests.compare(expected: package, actual: temp.path(for: package), file: file, line: line)
    }
    
    func config(_ contents: String, ext: String = "json") -> String {
        let url = URL(fileURLWithPath: temp.path(for: "config.\(ext)"))
        try! contents.data(using: .utf8)!.write(to: url)
        return url.path
    }
}
