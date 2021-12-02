// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import ArgumentParser
import OpenAPIKit30
import Foundation
import Yams

// TODO: Add a mechanism ot pass generator option directly (--options)
struct Generate: ParsableCommand {

    @Option(help: "The OpenAPI spec input file in either JSON or YAML format")
    var input: String
    
    // TODO: update if I change the name
    @Option(help: "The output folder")
    var output: String = "./.create-api/"
    
    @Option(help: "The path to generator configuration. If not present, the command will look for .createAPI file in the current folder.")
    var config: String = "/.create-api"
    
    @Option(help: "If enabled, saturates all cores in the system. By default, enabled.")
    var parallel: Bool = true
    
    @Flag(help: "Show extra logging for debugging purposes")
    var verbose = false
    
    @Option(help: "Enabled vendor-specific logic")
    var vendor: String?
        
    // TODO: pass as parameters (maybe in YML file?)
    let `import` = "APIClient"
    let namespace = "Paths"
    let access = "public"
    
    // TODO: tabs/spaces + count
    
    // TODO: Add options what to generate

    func run() throws {
        if verbose {
            print("Creating a spec for file \"\(input)\"")
        }
        
        // TODO: Add JSON support
        
        // TODO: Optimize spec parsing perforamnce
        let input = (input as NSString).expandingTildeInPath
        let inputURL = URL(fileURLWithPath: input)
        let data = try Data(contentsOf: inputURL)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        if verbose {
            print("Parsing the spec")
        }
        
        let spec: OpenAPI.Document
        if inputURL.pathExtension == "json" {
            // JSONDecoder doesn't appear to be thread-safe.
            spec = try JSONDecoder().decode(OpenAPI.Document.self, from: data)
        } else {
            if parallel {
                spec = try YAMLDecoder().decode(ParallelDocumentParser.self, from: data).document
            } else {
                spec = try YAMLDecoder().decode(OpenAPI.Document.self, from: data)
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        if verbose {
            print("Finished parsing the spec \(timeElapsed) s.")
        }
        
        // TODO: Add a way to include/exclude paths and schemas
        // TODO: Add a way to select what to generate (e.g. only schemas
    
        let arguments = GenerateArguments(isVerbose: verbose, isParallel: parallel, vendor: vendor)
        let options = try makeOptions(at: config)
        let resources = GeneratePaths(spec: spec, options: options, arguments: arguments).run()
        let schemas = GenerateSchemas(spec: spec, options: options, arguments: arguments).run()
        
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

private func makeOptions(at configPath: String) throws -> GenerateOptions {
    let url = URL(fileURLWithPath: (configPath as NSString).expandingTildeInPath)
    if let data = try? Data(contentsOf: url) {
        do {
            let scheme = try JSONDecoder().decode(GenerateOptionsScheme.self, from: data)
            return GenerateOptions(scheme)
        } catch {
            throw GeneratorError("Failed to read configuration: \(error)")
        }
    }
    return GenerateOptions() // Use default options
}
