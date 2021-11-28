// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit
import Foundation

// TODO: Add root "/" support (for GitHub)

extension Generate {
    func generatePaths(for spec: OpenAPI.Document) -> String {
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

                // TODO: percent-encode path?
                
                // TODO: Reuse type generation code
                
                if !isLast && spec.paths.contains(key: subpath) {
                    continue // Will be generated when the path is encountered
                }
                
                // TODO: refactor and add remaining niceness
                var generatedType = """
                    \(access) struct \(type) {
                        // \(subpath.rawValue)
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
        
        return output
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
