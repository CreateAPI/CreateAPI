// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import ArgumentParser
import CreateOptions
import OpenAPIKit30
import Foundation
import Yams

// TODO: Generate `README.md` for package (see `info`)
// TODO: Disable sandbox
// TODO: Add OpenAPI 3.1 support

struct Generate: ParsableCommand {
    private static let supportedFileFormats: [String] = ["yml", "yaml", "json"]

    @Argument(help: "The OpenAPI spec input file in either JSON or YAML format")
    var input: String

    @Option(help: "The output folder")
    var output = "./.create-api/"
    
    @Option(help: "The path to generator configuration. If not present, the command will look for .createAPI file in the current folder.")
    var config = "/.create-api.yaml"
    
    @Flag(name: .shortAndLong, help: "Split output into separate files")
    var split = false

    @Flag(name: .shortAndLong, help: "Print additional logging information")
    var verbose = false
    
    @Flag(help: "Turns all warnings into errors")
    var strict = false
    
    @Flag(name: .shortAndLong, help: "Removes the output folder before continuing")
    var clean = false
    
    @Flag(help: "Ignore any errors that happen during code generation")
    var allowErrors = false
    
    #if os(macOS)
    @Flag(help: "Monitor changes to both the spec and the configuration file and automatically re-generated input")
    var watch = false
    #endif
        
    @Option(help: "Generates a complete package with a given name")
    var package: String?
    
    @Option(help: "Use the following name as a module name")
    var module: String?
        
    @Option(help: "Enabled vendor-specific logic (supported values: \"github\")")
    var vendor: String?
    
    @Option(help: "Specifies what to generate", completion: .list(["paths", "entities"]))
    var generate = ["paths", "entities"]

    @Option(help: "Example: \"%0.generated.swift\" will produce files with the following names: \"Paths.generated.swift\".")
    var filenameTemplate: String = "%0.swift"

    @Option(help: "Example: \"%0Generated\" will produce entities with the following names: \"EntityGenerated\".")
    var entitynameTemplate: String = "%0"

    @Flag(help: "By default, saturates all available threads. Pass this option to turn all parallelization off.")
    var singleThreaded = false
    
    @Flag(help: "Measure performance of individual operations")
    var measure = false

    func run() throws {
        Benchmark.isEnabled = measure
        #if os(macOS)
        if watch {
            _ = try Watcher(paths: [config, input], run: _run)
            RunLoop.main.run()
            return
        }
        #endif

        try _run()
    }
    
    private func _run() throws {
        print("Generating code for \(input.filename)...")
        let benchmark = Benchmark(name: "Generation")
        try actuallyRun()
        benchmark.stop()
    }
        
    private func actuallyRun() throws {
        let spec = try parseInputSpec()
        let options = try readOptions()
        try validateOptions(options: options)
        
        let generator = Generator(spec: spec, options: options, arguments: arguments)
        // IMPORTANT: Paths needs to be generated before schemes.
        let paths = generate.contains("paths") ? try generator.paths() : nil
        let schemas = generate.contains("entities") ? try generator.schemas() : nil
        
        let outputURL = URL(filePath: output)
        if clean { try? FileManager.default.removeItem(at: outputURL) }
        let sourceURL = package.map { outputURL.appending(path: "\($0)/Sources/") } ?? outputURL
        
        let benchmark = Benchmark(name: "Write output files")
        if let package = package {
            let packageURL = outputURL.appending(path: package)
            try? packageURL.remove()
            try packageURL.createDirectoryIfNeeded()
            try generator.makePackageFile(name: package).write(to: packageURL.appending(path: "Package.swift"))
        }
        try sourceURL.createDirectoryIfNeeded()
        try write(output: paths, name: "Paths", outputURL: sourceURL, options: options)
        try write(output: schemas, name: "Entities", outputURL: sourceURL, options: options)
        benchmark.stop()
    }
        
    private func validateOptions(options: GenerateOptions) throws {
        if module != nil && package != nil {
            throw GeneratorError("`module` and `package` parameters are mutually exclusive")
        }
        if package == nil && module == nil {
            throw GeneratorError("You must provide either `module` or `package`")
        }
        if !options.entities.exclude.isEmpty && !options.entities.include.isEmpty {
            throw GeneratorError("`exclude` and `include` can't be used together")
        }
        if !options.paths.exclude.isEmpty && !options.paths.include.isEmpty {
            throw GeneratorError("`exclude` and `include` can't be used together")
        }
    }
    
    private func readOptions() throws -> GenerateOptions {
        let url = URL(filePath: config)

        guard Self.supportedFileFormats.contains(url.pathExtension) else {
            let extensions = Self.supportedFileFormats.map({ "`\($0)`" }).joined(separator: ", ")
            throw GeneratorError("The file must have one of the following extensions: \(extensions).")
        }

        guard let data = try? Data(contentsOf: url), !data.isEmpty else {
            return GenerateOptions() // Use default options
        }

        do {
            var options = try YAMLDecoder().decode(ConfigOptions.self, from: data)
            options.entities.include = Set(options.entities.include.map { Template(arguments.entityNameTemplate).substitute($0) })
            options.entities.exclude = Set(options.entities.exclude.map { Template(arguments.entityNameTemplate).substitute($0) })
            return GenerateOptions(configOptions: options)
        } catch {
            throw GeneratorError("Failed to read configuration. \(error)")
        }
    }
    private func parseInputSpec() throws -> OpenAPI.Document {
        VendorExtensionsConfiguration.isEnabled = false
        
        let inputURL = URL(filePath: input)

        guard Self.supportedFileFormats.contains(inputURL.pathExtension) else {
            let extensions = Self.supportedFileFormats.map({ "`\($0)`" }).joined(separator: ", ")
            throw GeneratorError("The file must have one of the following extensions: \(extensions).")
        }
        
        var bench = Benchmark(name: "Read spec data")
        let data = try Data(contentsOf: inputURL)
        bench.stop()

        bench = Benchmark(name: "Parse spec")
        let spec: OpenAPI.Document
        do {
            if !singleThreaded {
                spec = try YAMLDecoder().decode(ParallelDocumentParser.self, from: data).document
            } else {
                spec = try YAMLDecoder().decode(OpenAPI.Document.self, from: data)
            }
        } catch {
            throw GeneratorError("ERROR! The spec is missing or invalid. \(OpenAPI.Error(from: error))")
        }
        bench.stop()
        return spec
    }
    
    private func write(output: GeneratorOutput?, name: String, outputURL: URL, options: GenerateOptions) throws {
        guard let output = output else {
            return
        }
        func process(_ contents: String) -> String {
            contents.indent(using: options).appending("\n")
        }
        if split {
            let outputURL = outputURL.appending(path: name)
            try outputURL.createDirectoryIfNeeded()
            for file in output.files {
                try process(output.header + "\n\n" + file.contents).write(to: outputURL.appending(path: makeFilename(for: file.name)))
            }
            if let file = output.extensions {
                try process(output.header + "\n\n" + file.contents).write(to: outputURL.appending(path: makeFilename(for: "\(name)+Extensions")))
            }
        } else {
            let contents = ([output.header] + output.files.map(\.contents) + [output.extensions?.contents])
                .compactMap { $0 }
                .joined(separator: "\n\n")
            try process(contents).write(to: outputURL.appending(path: makeFilename(for: name)))
        }
    }
    
    private func makeFilename(for name: String) -> String {
        Template(filenameTemplate).substitute(name)
    }
    
    private var arguments: GenerateArguments {
        guard let module = (package ?? module).map(ModuleName.init(processing:)) else {
            fatalError("You must provide either `module` or `package`")
        }
        return GenerateArguments(isVerbose: verbose, isParallel: !singleThreaded, isStrict: strict, isIgnoringErrors: allowErrors, vendor: vendor, module: module, entityNameTemplate: entitynameTemplate)
    }
}
