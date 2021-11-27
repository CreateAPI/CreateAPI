// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import ArgumentParser
import OpenAPIKit
import Foundation
import Yams

struct Nano: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool to auto-generate code for Nano framework",
        subcommands: [Generate.self])

    init() { }
}

struct Generate: ParsableCommand {

    @Option(help: "The OpenAPI spec input file in either JSON or YAML format")
    var input: String

    @Flag(help: "Show extra logging for debugging purposes")
    var verbose = false

    func run() throws {
        if verbose {
            print("Creating a spec for file \"\(input)\"")
        }
        do {
            // TODO: Add JSON support
            let input = (input as NSString).expandingTildeInPath
            let data = try Data(contentsOf: URL(fileURLWithPath: input))
            let spec = try YAMLDecoder().decode(OpenAPI.Document.self, from: data)
            
            print(spec)
            
//            let generator = Generator(spec: spec)
            // TODO: write output
//            generator.generate()
        } catch {
            print("Invalid OpenAPI format: \(error)")
        }
        
        print()
    }
}

Nano.main()
