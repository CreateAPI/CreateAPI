import ArgumentParser

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
    }
}

Nano.main()
