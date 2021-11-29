// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import XCTest

private var isGeneratingExpected = false
private var isOpeningDiff = true
private var projectPath = "~/Developer/CreateAPI/" // TODO: Find it automatically

func compare(expected: String, actual: String, file: StaticString = #file, line: UInt = #line) {
    if isGeneratingExpected {
        let projectPath = (projectPath as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: projectPath + "/Tests/CreateAPITests/Resources/Expected/\(expected).txt")
        try! actual.data(using: .utf8)!.write(to: url)
    } else {
        let expectedText = txt(named: expected)
        if expectedText != actual {
            let expectedURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".swift")
            let actualURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".swift")
            try! expectedText.data(using: .utf8)!.write(to: expectedURL)
            try! actual.data(using: .utf8)!.write(to: actualURL)
            if isOpeningDiff {
                shell("opendiff", expectedURL.path, actualURL.path)
            }
            XCTFail("Specs don't match")
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
