// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import ArgumentParser

@main
struct CreateAPI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-api",
        abstract: "A Swift command-line tool to auto-generate code for OpenAPI specs",
        subcommands: [Generate.self]
    )
}
