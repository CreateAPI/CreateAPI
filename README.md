<img width="80px" src="https://user-images.githubusercontent.com/1567433/146774765-4671c989-62c3-4418-8bdb-2773d7a26067.png">

# CreateAPI

A description of this package.

## Arguments

## Configuration

// TODO: test that when you procide default options like this , it works

You can use either YAML or JSON as configuration files. The default options the following:

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
  # Skipped entities, e.g. ["SimpleUser"]
  skip: []
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
  isAdditionalPropertiesOnByDefault: false

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
  isAddingOperationIds: true
  # The types to import, by default uses "Get" (https://github.com/kean/Get)
  imports: ["Get"]
  # Example, "- empty: Void"
  overrideResponses: {}
  # Overrides the query parameter encoders, example:
  #   - Date: "ISO8601DateFormatter().string(from: self)"
  queryParameterEncoders: null
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

  parameters: {}
```

## Adding Specs

If you are using CreateAPI and want your spec to be part of the regression testing - add it to GenerateTest with your configuration.

## OpenAPI Support

Create API supports 

- External References
- `allowReserved` and `allowEmptyValue` option in query parameters
- `spaceDelimited`, `pipeDelimited`, and `deepObject` query parameters `style` values, form encoding only supports primitive types
