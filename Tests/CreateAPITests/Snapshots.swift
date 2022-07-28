// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
import XCTest

func compare(expected: String, actual: String, file: StaticString = #file, line: UInt = #line) throws {
    let env = ProcessInfo.processInfo.environment
    let expectedURL = Bundle.module.resourceURL!
        .appendingPathComponent("Expected")
        .appendingPathComponent(expected)
    let actualURL = URL(fileURLWithPath: actual)
    
    if env["GENERATE_SNAPSHOTS"] == "true" || !FileManager.default.fileExists(atPath: expectedURL.path) {
        let testsFolderPath = #filePath
            .split(separator: "/")
            .dropLast()
            .joined(separator: "/")
        let destinationURL = URL(fileURLWithPath: "/" + testsFolderPath + "/Expected/\(actualURL.lastPathComponent)")
        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.copyItem(at: actualURL, to: destinationURL)
    } else {
        try diff(expectedURL: expectedURL, actualURL: actualURL, file: file, line: line)
    }
}

fileprivate func diff(expectedURL: URL, actualURL: URL, file: StaticString = #file, line: UInt = #line) throws {
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
fileprivate func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}
