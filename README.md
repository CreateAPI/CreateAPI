<img width="80px" src="https://user-images.githubusercontent.com/1567433/146774765-4671c989-62c3-4418-8bdb-2773d7a26067.png">

# Create API

Delightful code generation for OpenAPI specs for Swift written in Swift. 

- **Fast**: processes specs with 100K lines of YAML in less than a second
- **Smart**: generates Swift code that looks like it's carefully written by hand
- **Reliable**: tested on 1KK lines of publicly available OpenAPI specs producing correct code every time
- **Customizable**: offers a ton of customization options

> Powered by [OpenAPIKit](https://github.com/mattpolzin/OpenAPIKit)

## Arguments

```
ARGUMENTS:
  <input>                 The OpenAPI spec input file in either JSON or YAML format

OPTIONS:
  --output <output>       The output folder (default: ./.create-api/)
  --config <config>       The path to configuration. If not present, the command will look
                          for .createAPI file in the current folder. (default: /.create-api.yaml)
  -s, --split             Split output into separate files
  -v, --verbose           Print additional logging information
  --strict                Turns all warnings into errors
  --allowErrors           Ignore any errors that happen during code generation
  --watch                 Monitor changes to both the spec and the configuration file and
                          automatically re-generated input
  --package <package>     Generates a complete package with a given name
  --module <module>       Use the following name as a module name
  --vendor <vendor>       Enabled vendor-specific logic (supported values: "github")
  --generate <generate>   Specifies what to generate (default: paths, entities)
  --filename-template <filename-template>
                          Example: "%0.generated.swift" will produce files with the following names:
                          "Paths.generated.swift". (default: %0.swift)
  --single-threaded       By default, saturates all available threads. Pass this option
                          to turn all parallelization off.
  --measure               Measure performance of individual operations
  -h, --help              Show help information.
```

## Configuration

CreateAPI supports a massive number of customization options with more to come. You can use either YAML or JSON as configuration files.

An example configuration file featuring all available options set to the default parameters.

```yaml
# Modifier for all generated declarations
access: public
# Add @available(*, deprecated) attributed
isAddingDeprecations: true
# Generate enums for strings
isGeneratingEnums: true
# Example: "enabled" -> "isEnabled"
isGeneratingSwiftyBooleanPropertyNames: true
# Any schema that can be conveted to a type identifier.
# Example: "typealias Pets = [Pet], is inlined as "[Pet]".
isInliningTypealiases: true
# Example: "var sourcelUrl" becomes "var sourceURL"
isReplacingCommonAcronyms: true
# Acronyms to add to the default list
addedAcronyms: []
# Acronyms to remove from the default list
ignoredAcronyms: []
# Example: "var file: [File]" becomes "var files: [File]"
isPluralizationEnabled: true
# Available values: ["spaces", "tabs"]
indentation: spaces
# By default, 4
spaceWidth: 4
# Parses dates (e.g. "2021-09-29") using `NaiveDate` (https://github.com/kean/NaiveDate)
isNaiveDateEnabled: true
# If enabled, uses `Int64` or `Int32` when specified.
isUsingIntegersWithPredefinedCapacity: false
# Disableds SwiftLint
isSwiftLintDisabled: true
# Overrides file
fileHeader: null

entities:
  # Excluded entities, e.g. ["SimpleUser"]
  # `exclude` and `include` can't be used together
  exclude: []
  # Included entities, e.g. ["SimpleUser"]
  include: []
  # Generates entities as structs
  isGeneratingStructs: true
  # Generate the following entities as classes
  entitiesGeneratedAsClasses: []
  # Generate the following entities as structs
  entitiesGeneratedAsClasses: []
  # Makes classes final
  isMakingClassesFinal: true
  # Base class for entities generated as classes
  baseClass: null
  # Protocols adopted by entities
  protocols: ["Codable"]
  # Generate initializers for all entities
  isGeneratingInitializers: true
  # If disabled, will use strings as coding keys
  isGeneratingCustomCodingKeys: true
  # By default, the order matches the order in the spec
  isSortingPropertiesAlphabetically: false
  # Add defaults values for booleans and other types when specified
  isAddingDefaultValues: true
  # For `allOf` inline properties from references
  isInliningPropertiesFromReferencedSchemas: false
  # Changes how unspecified additional properties are interpreted
  isAdditionalPropertiesOnByDefault: true

paths:
  # Skipped paths, e.g. ["/gists/{gist_id}/commits"]
  skip: []
  # Available options:
  #   - "rest" - generate structs to represent path components
  #   - "operations" - generate a plain list of operatinos
  style: rest
  # Namespace for all generated paths
  namespace: "Paths"
  # Generate response headers using https://github.com/kean/HTTPHeaders
  isGeneratingResponseHeaders: true
  # Add operation id to each request
  isAddingOperationIds: false
  # The types to import, by default uses "Get" (https://github.com/kean/Get)
  imports: ["Get"]
  # Example, "- empty: Void"
  overrideResponses: {}
  # Inline simple requests, like the ones with a single parameter 
  isInliningSimpleRequests: true
  # Inline simple parametesr with few arguments.
  isInliningSimpleQueryParameters: true
  # Threshold from which to start inlining query parameters
  simpleQueryParametersThreshold: 2
  # Tries to remove redundant paths
  isRemovingRedundantPaths: true

rename:
  # Rename properties, example:
  #   - name: firstName
  #   - SimpleUser.name: firstName
  properties: {}
  # Rename query parameters
  parameters: {}
  # Rename enum cases
  enumCases: {}
  # Rename entities
  entities: {}
  # Rename operation when "paths.style: operations" is used
  operations: {}
  # Rename anynomous collection elements. By default, use
  # a singularized form of the property name
  collectionElements: {}

comments:
  # Generate comments
  isEnabled: true
  # Generate titles
  isAddingTitles: true
  # Generate description 
  isAddingDescription: true
  # Generate examples
  isAddingExamples: true
  # Add links to the external documenatation
  isAddingExternalDocumentation: true
  # Auto-capitalizes comments
  isCapitalizationEnabled: true
```

## OpenAPI Support

The goal is to completely cover OpenAPI 3.x spec. 

Currently, the following features are **not** supported:

- External References

Some discrepancies with the OpenAPI spec are by design:

- `allowReserved` keyword in parameters is ignored and all parameter values are percent-encoded
- `allowEmptyValue` keyword in parameters is ignored as it's not recommended to be used

Upcoming:

- An improved way to generate patch parameters. Support for [JSON Patch](http://jsonpatch.com).
- OpenAPI 3.1 support.

## Installation

### [Mint](https://github.com/yonaskolb/Mint)

```bash
mint install kean/CreateAPI
```

Usage:

```bash
mint run CreateAPI create-api generate -h
```

### Make

```bash
git clone https://github.com/kean/CreateAPI.git
cd CreateAPI
make install
```

Usage:

```bash
create-api generate -h
```

