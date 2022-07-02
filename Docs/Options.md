

# Options


CreateAPI supports a massive number of customization options to generate the most appropriate source code.
To take advantage of this, define a **create-api.yaml** (or json) file and use the `--config` option when running the generate command.

Below you can find documentation for all of the valid options:

- [access](#access)
- [isAddingDeprecations](#isaddingdeprecations)
- [isGeneratingEnums](#isgeneratingenums)
- [isGeneratingSwiftyBooleanPropertyNames](#isgeneratingswiftybooleanpropertynames)
- [isInliningTypealiases](#isinliningtypealiases)
- [isReplacingCommonAcronyms](#isreplacingcommonacronyms)
- [addedAcronyms](#addedacronyms)
- [ignoredAcronyms](#ignoredacronyms)
- [indentation](#indentation)
- [spaceWidth](#spacewidth)
- [isPluralizationEnabled](#ispluralizationenabled)
- [isNaiveDateEnabled](#isnaivedateenabled)
- [isUsingIntegersWithPredefinedCapacity](#isusingintegerswithpredefinedcapacity)
- [isSwiftLintDisabled](#isswiftlintdisabled)
- [fileHeaderComment](#fileheadercomment)
- [comments](#comments)
  - [isEnabled](#commentsisenabled)
  - [isAddingTitles](#commentsisaddingtitles)
  - [isAddingDescription](#commentsisaddingdescription)
  - [isAddingExamples](#commentsisaddingexamples)
  - [isAddingExternalDocumentation](#commentsisaddingexternaldocumentation)
  - [isCapitalizationEnabled](#commentsiscapitalizationenabled)
- [entities](#entities)
  - [isGeneratingStructs](#entitiesisgeneratingstructs)
  - [entitiesGeneratedAsClasses](#entitiesentitiesgeneratedasclasses)
  - [entitiesGeneratedAsStructs](#entitiesentitiesgeneratedasstructs)
  - [imports](#entitiesimports)
  - [isMakingClassesFinal](#entitiesismakingclassesfinal)
  - [isGeneratingMutableClassProperties](#entitiesisgeneratingmutableclassproperties)
  - [isGeneratingMutableStructProperties](#entitiesisgeneratingmutablestructproperties)
  - [baseClass](#entitiesbaseclass)
  - [protocols](#entitiesprotocols)
  - [isSkippingRedundantProtocols](#entitiesisskippingredundantprotocols)
  - [isGeneratingInitializers](#entitiesisgeneratinginitializers)
  - [isSortingPropertiesAlphabetically](#entitiesissortingpropertiesalphabetically)
  - [isGeneratingCustomCodingKeys](#entitiesisgeneratingcustomcodingkeys)
  - [isAddingDefaultValues](#entitiesisaddingdefaultvalues)
  - [isInliningPropertiesFromReferencedSchemas](#entitiesisinliningpropertiesfromreferencedschemas)
  - [isAdditionalPropertiesOnByDefault](#entitiesisadditionalpropertiesonbydefault)
  - [isStrippingParentNameInNestedObjects](#entitiesisstrippingparentnameinnestedobjects)
  - [exclude](#entitiesexclude)
  - [include](#entitiesinclude)
- [paths](#paths)
  - [style](#pathsstyle)
  - [namespace](#pathsnamespace)
  - [isGeneratingResponseHeaders](#pathsisgeneratingresponseheaders)
  - [isAddingOperationIds](#pathsisaddingoperationids)
  - [imports](#pathsimports)
  - [overridenResponses](#pathsoverridenresponses)
  - [overridenBodyTypes](#pathsoverridenbodytypes)
  - [isInliningSimpleRequests](#pathsisinliningsimplerequests)
  - [isInliningSimpleQueryParameters](#pathsisinliningsimplequeryparameters)
  - [simpleQueryParametersThreshold](#pathssimplequeryparametersthreshold)
  - [isRemovingRedundantPaths](#pathsisremovingredundantpaths)
  - [exclude](#pathsexclude)
  - [include](#pathsinclude)
- [rename](#rename)
  - [properties](#renameproperties)
  - [parameters](#renameparameters)
  - [enumCases](#renameenumcases)
  - [entities](#renameentities)
  - [operations](#renameoperations)
  - [collectionElements](#renamecollectionelements)

### access

**Type:** String<br />
**Default:** `"public"`

Access level modifier for all generated declarations


### isAddingDeprecations

**Type:** Bool<br />
**Default:** `true`

Add `@available(*, deprecated)` attribute to deprecated types and properties


### isGeneratingEnums

**Type:** Bool<br />
**Default:** `true`

Generate enums for strings


### isGeneratingSwiftyBooleanPropertyNames

**Type:** Bool<br />
**Default:** `true`

Prefixes booleans with `is` ("enabled" -> "isEnabled")


### isInliningTypealiases

**Type:** Bool<br />
**Default:** `true`

Any schema that can be converted to a type identifier.
For example, `typealias Pets = [Pet]` is inlined as `[Pet]`.


### isReplacingCommonAcronyms

**Type:** Bool<br />
**Default:** `true`

For example, `var sourcelUrl` becomes `var sourceURL`.


### addedAcronyms

**Type:** [String]<br />
**Default:** `[]`

Acronyms to add to the default list


### ignoredAcronyms

**Type:** [String]<br />
**Default:** `[]`

Acronyms to remove from the default list


### indentation

**Type:** GenerateOptions.Indentation<br />
**Default:** `.spaces`

Change the style of indentation. Supported values:
- `spaces`
- `tabs`


### spaceWidth

**Type:** Int<br />
**Default:** `4`

Number of spaces to use when `indentation` is set to `spaces`.


### isPluralizationEnabled

**Type:** Bool<br />
**Default:** `true`

For example, `public var file: [File]` becomes `public var files: [File]`


### isNaiveDateEnabled

**Type:** Bool<br />
**Default:** `true`

Parses dates (e.g. `"2021-09-29"`) using [`NaiveDate`](https://github.com/CreateAPI/NaiveDate)


### isUsingIntegersWithPredefinedCapacity

**Type:** Bool<br />
**Default:** `false`

If enabled, uses `Int64` or `Int32` when specified.


### isSwiftLintDisabled

**Type:** Bool<br />
**Default:** `true`

Appends the `swiftlint:disable all` annotation beneath the header in generated files


### fileHeaderComment

**Type:** String<br />
**Default:** `"// Generated by Create API\n// https://github.com/CreateAPI/CreateAPI"`

Overrides file header comment



## Comments

Customize specific behaviors when generating comments on entities/paths/properties.


### comments.isEnabled

**Type:** Bool<br />
**Default:** `true`

Set to false to disable the generation of comments, for example:

```yaml
comments:
  isEnabled: false
```


### comments.isAddingTitles

**Type:** Bool<br />
**Default:** `true`

Include the schema title when generating comments


### comments.isAddingDescription

**Type:** Bool<br />
**Default:** `true`

Include the schema description when generating comments


### comments.isAddingExamples

**Type:** Bool<br />
**Default:** `true`

Include the schema example when generating comments


### comments.isAddingExternalDocumentation

**Type:** Bool<br />
**Default:** `true`

Include a link to external documentation when generating comments


### comments.isCapitalizationEnabled

**Type:** Bool<br />
**Default:** `true`

Auto-capitalize comments



## Entities

Options specifically related to generating entities


### entities.isGeneratingStructs

**Type:** Bool<br />
**Default:** `true`

When true, generates entities as `struct` types. Otherwise generates them as `class` types.


### entities.entitiesGeneratedAsClasses

**Type:** Set<String><br />
**Default:** `[]`

Explicitly generate the following entities as `class` types


### entities.entitiesGeneratedAsStructs

**Type:** Set<String><br />
**Default:** `[]`

Explicitly generate the given entities as `struct` types


### entities.imports

**Type:** Set<String><br />
**Default:** `[]`

Modules to be imported within the source files for generated entities


### entities.isMakingClassesFinal

**Type:** Bool<br />
**Default:** `true`

When generating `class` types, marks them as `final`


### entities.isGeneratingMutableClassProperties

**Type:** Bool<br />
**Default:** `false`

When generating `class` types, generate the properties as `public var`


### entities.isGeneratingMutableStructProperties

**Type:** Bool<br />
**Default:** `true`

When generating `struct` types, generate the properties as `public var`


### entities.baseClass

**Type:** String<br />
**Default:** `nil`

Base class used when generating `class` types


### entities.protocols

**Type:** Set<String><br />
**Default:** `["Codable"]`

Protocols to be adopted by each generated entity


### entities.isSkippingRedundantProtocols

**Type:** Bool<br />
**Default:** `true`

Automatically removes `Encodable` or `Decodable` conformance when it is not required


### entities.isGeneratingInitializers

**Type:** Bool<br />
**Default:** `true`

Generate an initializer for each entity


### entities.isSortingPropertiesAlphabetically

**Type:** Bool<br />
**Default:** `false`

Orders properties of an entity alphabetically instead of the order defined in the schema


### entities.isGeneratingCustomCodingKeys

**Type:** Bool<br />
**Default:** `true`

If disabled, will use strings as as `CodingKey` values


### entities.isAddingDefaultValues

**Type:** Bool<br />
**Default:** `true`

If defined, uses the `default` value from the schema for the generated property for booleans


### entities.isInliningPropertiesFromReferencedSchemas

**Type:** Bool<br />
**Default:** `false`

For `allOf` inline properties from references


### entities.isAdditionalPropertiesOnByDefault

**Type:** Bool<br />
**Default:** `true`

Changes how unspecified additional properties are interpreted


### entities.isStrippingParentNameInNestedObjects

**Type:** Bool<br />
**Default:** `false`

Strips the parent name of enum cases within objects that are `oneOf` / `allOf` / `anyOf` of nested references


### entities.exclude

**Type:** Set<String><br />
**Default:** `[]`

When set to a non-empty value, entities with the given names will be ignored during generation.
Cannot be used in conjunction with `include`.


### entities.include

**Type:** Set<String><br />
**Default:** `[]`

When set to a non-empty value, only entities matching the given names will be generated.
This cannot be used in conjunction with `exclude`.



## Paths

Options specifically related to generating paths


### paths.style

**Type:** GenerateOptions.PathsStyle<br />
**Default:** `.rest`

The style used when generating path definitions

- `rest` - Generates nest structs to represent path components
- `operations` - Generates a plain list of request operations


### paths.namespace

**Type:** String<br />
**Default:** `"Paths"`

The namespace type for all generated paths


### paths.isGeneratingResponseHeaders

**Type:** Bool<br />
**Default:** `true`

Generate response headers using [HTTPHeaders](https://github.com/CreateAPI/HTTPHeaders)


### paths.isAddingOperationIds

**Type:** Bool<br />
**Default:** `false`

Adds the operation id to each request


### paths.imports

**Type:** Set<String><br />
**Default:** `["Get"]`

Modules to be imported within the source files for generated requests


### paths.overridenResponses

**Type:** [String: String]<br />
**Default:** `[:]`

Allows you to override mapping of specific response types to a custom (or generated) type instead.

For example:

```yaml
paths:
  overridenResponses:
    MyApiResponseType: MyCustomDecodableType
```


### paths.overridenBodyTypes

**Type:** [String: String]<br />
**Default:** `[:]`

Tell CreateAPI how to map an unknown request or response content types to a Swift type used in the path generation.

For example:

```yaml
paths:
  overridenBodyTypes:
    application/octocat-stream: String
```


### paths.isInliningSimpleRequests

**Type:** Bool<br />
**Default:** `true`

Inline simple requests, like the ones with a single parameter


### paths.isInliningSimpleQueryParameters

**Type:** Bool<br />
**Default:** `true`

Inline query parameters for simple requests instead of generating a Parameter type


### paths.simpleQueryParametersThreshold

**Type:** Int<br />
**Default:** `2`

The threshold of query parameters to inline when using `isInliningSimpleQueryParameters`.


### paths.isRemovingRedundantPaths

**Type:** Bool<br />
**Default:** `true`

Remove redundant paths if possible


### paths.exclude

**Type:** Set<String><br />
**Default:** `[]`

When set to a non-empty value, the given paths will be ignored during generation.
Cannot be used in conjunction with `include`.


### paths.include

**Type:** Set<String><br />
**Default:** `[]`

When set to a non-empty value, only the given paths will be generated.
This cannot be used in conjunction with `exclude`.



## Rename

Options used to configure detailed renaming rules for all aspects of the generated code.


### rename.properties

**Type:** [String: String]<br />
**Default:** `[:]`

Rename rules for properties specific to a given type, or all properties with a matching name.

```yaml
rename:
  properties:
    name: firstName # renames any property called 'name' to 'firstName'
    SimpleUser.name: firstName # renames only the 'name' property on the 'SimpleUser' entity
```


### rename.parameters

**Type:** [String: String]<br />
**Default:** `[:]`

Rename query parameters


### rename.enumCases

**Type:** [String: String]<br />
**Default:** `[:]`

Rename enum cases


### rename.entities

**Type:** [String: String]<br />
**Default:** `[:]`

Rename entities


### rename.operations

**Type:** [String: String]<br />
**Default:** `[:]`

Rename operations when using the `"operations"` style for path generation


### rename.collectionElements

**Type:** [String: String]<br />
**Default:** `[:]`

Rename anynomous collection elements. By default, use a singularized form of the property name



> **Note**:
> Want to contribute to the documentation? [Edit it here](../Sources/CreateOptions/GenerateOptions.swift).
