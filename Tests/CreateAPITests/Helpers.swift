// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import XCTest
import OpenAPIKit30
import Yams

#warning("TODO: remove unused files")

func file(named name: String, ext: String) -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: ext)
    return try! Data(contentsOf: url!)
}

func fileExists(named name: String, ext: String) -> Bool {
    Bundle.module.url(forResource: name, withExtension: ext) != nil
}

func pathForSpec(named name: String) -> String {
    Bundle.module.url(forResource: name, withExtension: "yaml", subdirectory: "Specs")!.path
}

func spec(named name: String) -> OpenAPI.Document {
    let data = file(named: name, ext: "yaml")
    return try! YAMLDecoder().decode(OpenAPI.Document.self, from: data)
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
