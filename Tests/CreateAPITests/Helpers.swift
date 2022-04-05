// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
import XCTest
import OpenAPIKit30
import Yams

func file(named name: String, ext: String) -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: ext)
    return try! Data(contentsOf: url!)
}

func fileExists(named name: String, ext: String) -> Bool {
    Bundle.module.url(forResource: name, withExtension: ext) != nil
}

func pathForSpec(named name: String, ext: String) -> String {
    Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Specs")!.path
}

func generated(named name: String) -> String {
    let data = file(named: name, ext: "txt")
    return String(data: data, encoding: .utf8)!
}

struct TemporaryDirectory {
    let url: URL

    init() {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
    
    func path(for name: String) -> String {
        url.appendingPathComponent(name).path
    }
}
