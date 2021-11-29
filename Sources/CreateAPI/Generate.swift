// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import ArgumentParser
import OpenAPIKit30
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
    let namespace = "Paths"
    let access = "public"
    let model = "Decodable"
    
    // TODO: tabs/spaces + count
    
    // TODO: Add options what to generate

    func run() throws {
        if verbose {
            print("Creating a spec for file \"\(input)\"")
        }
        
        // TODO: Add JSON support
        let startTime = CFAbsoluteTimeGetCurrent()
        if verbose {
            print("Parsing the spec")
        }
        
        // TODO: Optimize spec parsing perforamnce
        let input = (input as NSString).expandingTildeInPath
        let data = try Data(contentsOf: URL(fileURLWithPath: input))
        let spec = try YAMLDecoder().decode(OpenAPI.Document.self, from: data)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        if verbose {
            print("Finished parsing the spec \(timeElapsed) s.")
        }
        
        
        // TODO: Add a way to include/exclude paths and schemas
        // TODO: Add a way to select what to generate (e.g. only schemas
    
        let resources = generatePaths(for: spec)
        let schemas = generateSchemas(for: spec)
        
        let outputPath = (self.output as NSString).expandingTildeInPath
        let outputURL = URL(fileURLWithPath: outputPath)
        if !FileManager.default.fileExists(atPath: outputPath) {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
        }
        func write(_ content: String, to name: String) throws {
            guard let data = content.data(using: .utf8) else {
                throw GeneratorError("Failed to convert output to a data blob")
            }
            try data.write(to: outputURL.appendingPathComponent("\(name).swift"))
        }
        try write(resources, to: "Paths")
        try write(schemas, to: "Schemas")
    }
}
