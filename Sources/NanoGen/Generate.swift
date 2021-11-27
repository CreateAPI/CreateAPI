// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import ArgumentParser
import OpenAPIKit
import Foundation
import Yams

struct Generate: ParsableCommand {

    @Option(help: "The OpenAPI spec input file in either JSON or YAML format")
    var input: String
    
    // TODO: update if I change the name
    @Option(help: "The OpenAPI spec output folder")
    var output: String = "./nanogen"

    @Flag(help: "Show extra logging for debugging purposes")
    var verbose = false
    
    // TODO: pass as parameters (maybe in YML file?)
    private let `import` = "APIClient"
    private let namespace = "Resources"
    private let access = "public"
    
    // TODO: Add options what to generate

    func run() throws {
        if verbose {
            print("Creating a spec for file \"\(input)\"")
        }
        
        // TODO: Add JSON support
        let input = (input as NSString).expandingTildeInPath
        let data = try Data(contentsOf: URL(fileURLWithPath: input))
        let spec = try YAMLDecoder().decode(OpenAPI.Document.self, from: data)
        
        // TODO: Add a way to filter out paths
    

        var output = """
            import Foundation
            import \(`import`)
            
            \(access) struct \(namespace) {}
            """
        
        // TODO: Only generate for one path
        
        output.append("\n\n")

        var generated = Set<OpenAPI.Path>()
        
        // TODO: Add description and everything
        
        for path in spec.paths {
            guard !path.key.components.isEmpty else {
                continue
            }
            
            var components: [String] = []
            for (index, component) in path.key.components.enumerated() {
                components.append(component)
                let subpath = OpenAPI.Path(components)
                guard !generated.contains(subpath) else { continue }
                generated.insert(subpath)
                
                let component = components.last!
                let isLast = index == path.key.components.endIndex - 1
                let isTopLevel = components.count == 1
                let type = makeType(component)
                let isParameter = component.starts(with: "{")
                let stat = isTopLevel ? " static" : ""
                
                let extensionOf = ([namespace] + components.dropLast().map(makeType)).joined(separator: ".")
                let fullPathRaw = "\"/\(component)\""
                
                // TODO: percent-encode path?
                
                // TODO: Reuse type generation code
                
                if !isLast && spec.paths.contains(key: subpath) {
                    continue // Will be generated when the path is encountered
                }
                
                // TODO: refactor and add remaining niceness
                var generatedType = """
                    \(access) struct \(type) {
                        // \(path.key.rawValue)
                        \(access) let path: String\n
                """
                
                if isLast {
                    generatedType += """
                    \n\(makeMethods(for: path.value))\n
                    """
                }
                
                generatedType += """
                    }
                """
                
                if isParameter {
                    let parameter = makeParameter(component)
                    output += """
                    extension \(extensionOf) {
                        \(access)\(stat) func \(parameter)(_ \(parameter): String) -> \(type) {
                            \(type)(path: \(isTopLevel ? "\"/\(component)/\"" : "path + \"/\"") + \(parameter))
                        }
                    
                    \(generatedType)
                    }\n\n
                    """
                } else {
                    output += """
                    extension \(extensionOf) {
                        \(access)\(stat) var \(type.lowercasedFirstLetter().escaped): \(type) {
                            \(type)(path: \(isTopLevel ? "\"/\(component)\"" : ("path + \"/\(components.last!)\"")))
                        }
                        
                    \(generatedType)
                    }\n\n
                    """
                }
            }
        }
        
        let outputURL = URL(fileURLWithPath: (self.output as NSString).expandingTildeInPath)
        // TODO: Is this safe? Overwrite files instead?
        try? FileManager.default.removeItem(at: outputURL)
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
        try output.data(using: .utf8)?.write(to: outputURL.appendingPathComponent("Resources.swift"))
    }
    
    // TODO: Add remaining methods
    private func makeMethods(for item: OpenAPI.PathItem) -> String {
        [
            item.get.map { makeMethod(for: $0, method: "get") },
//            item.put.map { makeMethod(for: $0, method: "put") },
//            item.post.map { makeMethod(for: $0, method: "post") },
//            item.delete.map { makeMethod(for: $0, method: "delete") },
//            item.options.map { makeMethod(for: $0, method: "options") },
//            item.head.map { makeMethod(for: $0, method: "head") },
//            item.patch.map { makeMethod(for: $0, method: "patch") },
//            item.trace.map { makeMethod(for: $0, method: "trace") },
        ]
            .compactMap { $0 }
            .joined(separator: "\n\n")
    }
    
    // TODO: Inject offset as a parameter
    private func makeMethod(for operation: OpenAPI.Operation, method: String) -> String {
        """
                \(access) func \(method)() -> Request<Void> {
                    .\(method)(path)
                }
        """
    }
}


func makeType(_ string: String) -> String {
    let name = string.toCamelCase
    return string.isParameter ? "With\(name)" : name
}

func makeParameter(_ string: String) -> String {
    string.toCamelCase.lowercasedFirstLetter().escaped
}

private extension String {
    var isParameter: Bool {
        starts(with: "{")
    }
    
    // Starting with capitalized first letter.
    var toCamelCase: String {
        components(separatedBy: badCharacters)
            .filter { !$0.isEmpty }
            .map { $0.capitalizingFirstLetter() }
            .joined(separator: "")
    }
}

private let keywords = Set(["public", "private", "open", "fileprivate", "default", "extension", "import", "init", "deinit", "typealias", "let", "var", "in", "return", "for", "switch", "enum", "struct", "class", "if", "self"])

private extension String {
    var escaped: String {
        guard keywords.contains(self) else { return self }
        return "`\(self)`"
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }
}

private extension String {
    func lowercasedFirstLetter() -> String {
        prefix(1).lowercased() + dropFirst()
    }
}

private let badCharacters = CharacterSet.alphanumerics.inverted
