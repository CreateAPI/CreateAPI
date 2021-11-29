// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import XCTest
import OpenAPIKit30
import Yams

func file(named name: String, ext: String) -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: ext)
    return try! Data(contentsOf: url!)
}

func spec(named name: String) -> OpenAPI.Document {
    let data = file(named: name, ext: "yaml")
    return try! YAMLDecoder().decode(OpenAPI.Document.self, from: data)
}

func txt(named name: String) -> String {
    let data = file(named: name, ext: "txt")
    return String(data: data, encoding: .utf8)!
}
