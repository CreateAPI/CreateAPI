// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import ArgumentParser
import OpenAPIKit
import Foundation
import Yams

struct OneAPI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "oneapi",
        abstract: "A Swift command-line tool to auto-generate code for OneAPI framework",
        subcommands: [Generate.self])

    init() { }
}

OneAPI.main()
