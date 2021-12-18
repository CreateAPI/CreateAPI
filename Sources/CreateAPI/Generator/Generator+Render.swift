// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation

extension Generator {
    func render(_ decl: Declaration) -> String {
        switch decl {
        case let decl as EnumOfStringsDeclaration: return render(decl)
        case let decl as EntityDeclaration: return render(decl)
        case let decl as AnyDeclaration: return decl.contents
        default: fatalError()
        }
    }
    
    private func render(_ decl: EnumOfStringsDeclaration) -> String {
        let comments = templates.comments(for: decl.metadata, name: decl.name.rawValue)
        let cases = decl.cases.map {
            templates.case(name: $0.name, value: $0.key)
        }.joined(separator: "\n")
        return comments + templates.enumOfStrings(name: decl.name, contents: cases)
    }
    
    private func render(_ decl: EntityDeclaration) -> String {
        let properties = decl.properties
        
        var contents: [String] = []
        contents.append(templates.properties(properties))
        contents += decl.nested.map(render)
        if options.entities.isGeneratingInitializers {
            contents.append(templates.initializer(properties: properties))
        }
        if decl.protocols.isDecodable, !properties.isEmpty, options.entities.isGeneratingInitWithCoder {
            contents.append(templates.initFromDecoder(properties: properties))
        }
        if decl.protocols.isEncodable, !properties.isEmpty, options.entities.isGeneratingDecode {
            contents.append(templates.encode(properties: properties))
        }
        
        // TODO: Add this an an options
        //        let hasCustomCodingKeys = keys.contains { PropertyName($0).rawValue != $0 }
        //        if hasCustomCodingKeys {
        //            output += "\n"
        //            output += "    private enum CodingKeys: String, CodingKey {\n"
        //            for key in keys where !skippedKeys.contains(key) {
        //                let parameter = PropertyName(key).rawValue
        //                if parameter == key {
        //                    output += "        case \(parameter)\n"
        //                } else {
        //                    output += "        case \(parameter) = \"\(key)\"\n"
        //                }
        //            }
        //            output +=  "    }\n"
        //        }
        
        return templates.comments(for: decl.metadata, name: decl.name.rawValue)
        + templates.entity(name: decl.name, contents: contents, protocols: decl.protocols)
    }
}
