// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import ArgumentParser
import OpenAPIKit
import Foundation
import Yams

// TODO: parallelize
struct Generate: ParsableCommand {

    @Option(help: "The OpenAPI spec input file in either JSON or YAML format")
    var input: String
    
    // TODO: update if I change the name
    @Option(help: "The OpenAPI spec output folder")
    var output: String = "./nanogen"

    @Flag(help: "Show extra logging for debugging purposes")
    var verbose = false
    
    // TODO: pass as parameters (maybe in YML file?)
    let `import` = "APIClient"
    let namespace = "Resources"
    let access = "public"
    let model = "Decodable"
    
    // TODO: tabs/spaces + count
    
    // TODO: Add options what to generate

    func run() throws {
        if verbose {
            print("Creating a spec for file \"\(input)\"")
        }
        
        // TODO: Add JSON support
        let input = (input as NSString).expandingTildeInPath
        let data = try Data(contentsOf: URL(fileURLWithPath: input))
        let spec = try YAMLDecoder().decode(OpenAPI.Document.self, from: data)
        
        // TODO: Add a way to include/exclude paths and schemas
        // TODO: Add a way to select what to generate (e.g. only schemas
    
        let group = DispatchGroup()
        let resources = generateResources(for: spec)
        let schemas = generateSchemas(for: spec)
        
        let outputURL = URL(fileURLWithPath: (self.output as NSString).expandingTildeInPath)
        // TODO: Is this safe? Overwrite files instead?
        try? FileManager.default.removeItem(at: outputURL)
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
        try resources.data(using: .utf8)?.write(to: outputURL.appendingPathComponent("Resources.swift"))
        try schemas.data(using: .utf8)?.write(to: outputURL.appendingPathComponent("Schemas.swift"))
    }
}
