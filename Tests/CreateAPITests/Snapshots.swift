// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import XCTest

// TODO: Find it automatically
var projectPath = ("~/Developer/CreateAPI/" as NSString).expandingTildeInPath

func compare(expected: String, actual: String, file: StaticString = #file, line: UInt = #line) {
    let env = ProcessInfo.processInfo.environment
    
    if env["GENERATE_SNAPSHOTS"] == "true" || !fileExists(named: expected, ext: "txt") {
        let projectPath = (projectPath as NSString).expandingTildeInPath
        // Unfortunately, I can't used `.swift` because SPM ignores these files
        let url = URL(fileURLWithPath: projectPath + "/Tests/CreateAPITests/Expected/\(expected).txt")
        try! actual.data(using: .utf8)!.write(to: url)
    } else {
        let expectedText = generated(named: expected)
        if expectedText != actual {
            let expectedURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".swift")
            let actualURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".swift")
            try! expectedText.data(using: .utf8)!.write(to: expectedURL)
            try! actual.data(using: .utf8)!.write(to: actualURL)
            if env["OPEN_DIFF"] == "true" {
                shell("opendiff", expectedURL.path, actualURL.path)
            }
            XCTFail("Specs don't match")
        }
    }
}

func compare2(expected: String, actual: String, file: StaticString = #file, line: UInt = #line) throws {
    let env = ProcessInfo.processInfo.environment
    let expectedURL = Bundle.module.resourceURL!
        .appendingPathComponent("Expected")
        .appendingPathComponent(expected)
    let actualURL = URL(fileURLWithPath: actual)
    if env["GENERATE_SNAPSHOTS"] == "true" || !FileManager.default.fileExists(atPath: expectedURL.path) {
        let projectPath = (projectPath as NSString).expandingTildeInPath
        let destinationURL = URL(fileURLWithPath: projectPath + "/Tests/CreateAPITests/Expected/\(actualURL.lastPathComponent)")
        try FileManager.default.copyItem(at: actualURL, to: destinationURL)
    } else {
        try diff(expectedURL: expectedURL, actualURL: actualURL, file: file, line: line)
    }
}

private func diff(expectedURL: URL, actualURL: URL, file: StaticString = #file, line: UInt = #line) throws {
    func contents(at url: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
    }
    let lhsContents = try contents(at: expectedURL)
    let rhsContents = try contents(at: actualURL)
    
    for lhs in lhsContents {
        if lhs.lastPathComponent == "Package.resolved" { continue }
        let rhs = try XCTUnwrap(rhsContents.first { $0.lastPathComponent == lhs.lastPathComponent })
        if (try lhs.resourceValues(forKeys: [.isDirectoryKey])).isDirectory ?? false  {
            try diff(expectedURL: lhs, actualURL: rhs)
        } else {
            if !FileManager.default.contentsEqual(atPath: lhs.path, andPath: rhs.path) {
                XCTFail("Files didn't match: \(lhs.path) and \(rhs.path)")
                if ProcessInfo.processInfo.environment["OPEN_DIFF"] == "true" {
                    shell("opendiff", lhs.path, rhs.path)
                }
            }
        }
    }
}

@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}
