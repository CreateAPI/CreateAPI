// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit30
import Foundation
import GrammaticalNumber

// TODO: Fix AnyJSON and StringCodingKeys layout
// TODO: Add option to hide AnyJSON
// TODO: testEdgecasesRename "Status": "State" is not working
// TODO: New APIs in spec for renams
// TODO: Rename enums as separate properrty
// TODO: Add an option to add to namespace

// TODO: Add not support and fix warnings
// TODO: Add File (Data) support (see FormatTest.date)
// TODO: Add Date(Day) support (NaiveDate?) (see FormatTest.date)
// TODO: Add UUID support (and test it!)
// TODO: Review OpenAPI spec for -all
// TODO: Add int32/int64 support (optional) (and a way to disable)
// TODO: Check why public struct ConfigItem: Decodable { is empty
// TODO: Get rid of typealiases where a custom type is generated public typealias SearchResultTextMatches = [SearchResultTextMatchesItem]
// TODO: Final imporvementes to OctoKit
// TODO: anyOf should be class or struct?
// TODO: Add an option to skip types

// TODO: Add Encodable support
// TODO: Test remaining String formats https://swagger.io/docs/specification/data-models/data-types/ AND add options to disable some of tem
// TODO: More concise examples if it's just array of plain types
// TODO: Add an option to use CodingKeys instead of custom init
// TODO: Option to just use automatic CodingKeys (if you backend is perfect)
// TODO: Add an option to generate an initializer
// TODO: See what needs to be fixed in petstore-all
// TODO: Add support for default values
// TODO: Option to disable custom key generation
// TODO: Add support for deprecated fields
// TODO: Better naming for inline/nested objects
// TODO: Print more in verbose mode
// TODO: Add warnings for unsupported features
// TODO: Add Linux support
// TODO: Add SwiftLint disable all
// TODO: Remove remainig dereferencing
// TODO: Add JSON tests
// TODO: Add OpenAPI 3.1 support
// TODO: Autocapitilize description/title
// TODO: Add an option to ignore errors in arrays
// TODO: Rename to GenerateEntities
// TODO: Add an option to set a custom header

// TODO: Add an obeserver for a file (and keep tool running)

// TODO: Separate mapped* dictionary for enums
// TODO: entitiesGeneratedAsClasses - add support for nesting
// TODO: Add an option how allOf is generated (inline properties, create protocols)
// TODO: Add nesting support for "entitiesGeneratedAsStructs(classes)"

extension Generator {

    func schemes() -> String {
        startMeasuring("generating schemes (\(spec.components.schemas.count))")
        
        var output = templates.fileHeader
        output += "\n\n"
        
        let schemas = Array(spec.components.schemas)
        var generated = Array<String?>(repeating: nil, count: schemas.count)
        let context = Context(parents: [])
        let lock = NSLock()
        concurrentPerform(on: schemas, parallel: arguments.isParallel) { index, item in
            let (key, schema) = schemas[index]
            
            guard let name = makeTypeNameFor(key: key, schema: schema) else {
                if arguments.isVerbose {
                    print("Skipping generation for \(key.rawValue)")
                }
                return
            }
                        
            do {
                if let entry = try makeTopDeclaration(name: name, schema: schema, context: context), !entry.isEmpty {
                    lock.lock()
                    generated[index] = entry
                    lock.unlock()
                }
            } catch {
                print("ERROR: Failed to generate entity for \(key.rawValue): \(error)")
            }
        }

        var generatedCount = 0
        for entry in generated where entry != nil {
            generatedCount += 1
            output += entry!
            output += "\n\n"
        }
        
        stopMeasuring("generating schemes (\(generatedCount))")
        
        if isAnyJSONUsed {
            output += "\n"
            output += anyJSON
            output += "\n"
        }

        output += stringCodingKey
        output += "\n"
    
        return output.indent(using: options)
    }
    
    /// Return `nil` to skip generation.
    private func makeTypeNameFor(key: OpenAPI.ComponentKey, schema: JSONSchema) -> TypeName? {
        if arguments.vendor == "github" {
            // This makes sense only for the GitHub API spec where types like
            // `simple-user` and `nullable-simple-user` exist which are duplicate
            // and the only different is that the latter is nullable.
            if key.rawValue.hasPrefix("nullable-") {
                let counterpart = key.rawValue.replacingOccurrences(of: "nullable-", with: "")
                if let counterpartKey = OpenAPI.ComponentKey(rawValue: counterpart),
                   spec.components.schemas[counterpartKey] != nil {
                    return nil
                } else {
                    // Some types in GitHub specs are only defined once as Nullable
                    return makeTypeName(counterpart)
                }
            }
        }
        let name = makeTypeName(key.rawValue)
        if !options.schemes.mappedTypeNames.isEmpty {
            if let mapped = options.schemes.mappedTypeNames[name.rawValue] {
                return TypeName(processedRawValue: mapped)
            }
        }
        return makeTypeName(key.rawValue)
    }
}
