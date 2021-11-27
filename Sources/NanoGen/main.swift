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

Nano.main()
