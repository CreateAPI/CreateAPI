// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import class Foundation.Bundle
@testable import CreateAPI

//final class GenerateSchemesTests: XCTestCase {
//    let binary = productsDirectory.appendingPathComponent("create-api")
//
//    let process = Process()
//    process.executableURL = binary
//
//    let pipe = Pipe()
//    process.standardOutput = pipe
//
//    try process.run()
//    process.waitUntilExit()
//
//    let data = pipe.fileHandleForReading.readDataToEndOfFile()
//    let output = String(data: data, encoding: .utf8)
//
//    XCTAssertEqual(output, "Hello, world!\n")
//}
//
///// Returns path to the built products directory.
//var productsDirectory: URL {
//    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
//        return bundle.bundleURL.deletingLastPathComponent()
//    }
//    fatalError("couldn't find the products directory")
//}
