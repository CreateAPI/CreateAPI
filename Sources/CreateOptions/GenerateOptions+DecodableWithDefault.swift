// Generated using Sourcery 1.8.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


extension GenerateOptions: Decodable {
    enum CodingKeys: String, CodingKey {
        case access
        case isAddingDeprecations
        case isGeneratingEnums
        case isGeneratingSwiftyBooleanPropertyNames
        case isInliningTypealiases
        case isReplacingCommonAcronyms
        case addedAcronyms
        case ignoredAcronyms
        case indentation
        case spaceWidth
        case isPluralizationEnabled
        case isNaiveDateEnabled
        case isUsingIntegersWithPredefinedCapacity
        case isSwiftLintDisabled
        case fileHeaderComment
        case comments
        case entities
        case paths
        case rename
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        access = try container.decodeIfPresent(String.self, forKey: .access) ?? "public"
        isAddingDeprecations = try container.decodeIfPresent(Bool.self, forKey: .isAddingDeprecations) ?? true
        isGeneratingEnums = try container.decodeIfPresent(Bool.self, forKey: .isGeneratingEnums) ?? true
        isGeneratingSwiftyBooleanPropertyNames = try container.decodeIfPresent(Bool.self, forKey: .isGeneratingSwiftyBooleanPropertyNames) ?? true
        isInliningTypealiases = try container.decodeIfPresent(Bool.self, forKey: .isInliningTypealiases) ?? true
        isReplacingCommonAcronyms = try container.decodeIfPresent(Bool.self, forKey: .isReplacingCommonAcronyms) ?? true
        addedAcronyms = try container.decodeIfPresent([String].self, forKey: .addedAcronyms) ?? []
        ignoredAcronyms = try container.decodeIfPresent([String].self, forKey: .ignoredAcronyms) ?? []
        indentation = try container.decodeIfPresent(GenerateOptions.Indentation.self, forKey: .indentation) ?? .spaces
        spaceWidth = try container.decodeIfPresent(Int.self, forKey: .spaceWidth) ?? 4
        isPluralizationEnabled = try container.decodeIfPresent(Bool.self, forKey: .isPluralizationEnabled) ?? true
        isNaiveDateEnabled = try container.decodeIfPresent(Bool.self, forKey: .isNaiveDateEnabled) ?? true
        isUsingIntegersWithPredefinedCapacity = try container.decodeIfPresent(Bool.self, forKey: .isUsingIntegersWithPredefinedCapacity) ?? false
        isSwiftLintDisabled = try container.decodeIfPresent(Bool.self, forKey: .isSwiftLintDisabled) ?? true
        fileHeaderComment = try container.decodeIfPresent(String.self, forKey: .fileHeaderComment) ?? "// Generated by Create API\n// https://github.com/CreateAPI/CreateAPI"
        comments = try container.decodeIfPresent(Comments.self, forKey: .comments) ?? .init()
        entities = try container.decodeIfPresent(Entities.self, forKey: .entities) ?? .init()
        paths = try container.decodeIfPresent(Paths.self, forKey: .paths) ?? .init()
        rename = try container.decodeIfPresent(Rename.self, forKey: .rename) ?? .init()
    }
}

extension GenerateOptions.Comments: Decodable {
    enum CodingKeys: String, CodingKey {
        case isEnabled
        case isAddingTitles
        case isAddingDescription
        case isAddingExamples
        case isAddingExternalDocumentation
        case isCapitalizationEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        isAddingTitles = try container.decodeIfPresent(Bool.self, forKey: .isAddingTitles) ?? true
        isAddingDescription = try container.decodeIfPresent(Bool.self, forKey: .isAddingDescription) ?? true
        isAddingExamples = try container.decodeIfPresent(Bool.self, forKey: .isAddingExamples) ?? true
        isAddingExternalDocumentation = try container.decodeIfPresent(Bool.self, forKey: .isAddingExternalDocumentation) ?? true
        isCapitalizationEnabled = try container.decodeIfPresent(Bool.self, forKey: .isCapitalizationEnabled) ?? true
    }
}

extension GenerateOptions.Entities: Decodable {
    enum CodingKeys: String, CodingKey {
        case isGeneratingStructs
        case entitiesGeneratedAsClasses
        case entitiesGeneratedAsStructs
        case imports
        case isMakingClassesFinal
        case isGeneratingMutableClassProperties
        case isGeneratingMutableStructProperties
        case isGeneratingInitializers
        case baseClass
        case protocols
        case isSkippingRedundantProtocols
        case isGeneratingInitWithDecoder
        case isGeneratingEncodeWithEncoder
        case isSortingPropertiesAlphabetically
        case isGeneratingCustomCodingKeys
        case isAddingDefaultValues
        case isInliningPropertiesFromReferencedSchemas
        case isAdditionalPropertiesOnByDefault
        case isStrippingParentNameInNestedObjects
        case exclude
        case include
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isGeneratingStructs = try container.decodeIfPresent(Bool.self, forKey: .isGeneratingStructs) ?? true
        entitiesGeneratedAsClasses = try container.decodeIfPresent(Set<String>.self, forKey: .entitiesGeneratedAsClasses) ?? []
        entitiesGeneratedAsStructs = try container.decodeIfPresent(Set<String>.self, forKey: .entitiesGeneratedAsStructs) ?? []
        imports = try container.decodeIfPresent(Set<String>.self, forKey: .imports) ?? []
        isMakingClassesFinal = try container.decodeIfPresent(Bool.self, forKey: .isMakingClassesFinal) ?? true
        isGeneratingMutableClassProperties = try container.decodeIfPresent(Bool.self, forKey: .isGeneratingMutableClassProperties) ?? false
        isGeneratingMutableStructProperties = try container.decodeIfPresent(Bool.self, forKey: .isGeneratingMutableStructProperties) ?? false
        isGeneratingInitializers = try container.decodeIfPresent(Bool.self, forKey: .isGeneratingInitializers) ?? true
        baseClass = try container.decodeIfPresent(String.self, forKey: .baseClass) ?? nil
        protocols = try container.decodeIfPresent(Set<String>.self, forKey: .protocols) ?? ["Codable"]
        isSkippingRedundantProtocols = try container.decodeIfPresent(Bool.self, forKey: .isSkippingRedundantProtocols) ?? true
        isGeneratingInitWithDecoder = try container.decodeIfPresent(Bool.self, forKey: .isGeneratingInitWithDecoder) ?? true
        isGeneratingEncodeWithEncoder = try container.decodeIfPresent(Bool.self, forKey: .isGeneratingEncodeWithEncoder) ?? true
        isSortingPropertiesAlphabetically = try container.decodeIfPresent(Bool.self, forKey: .isSortingPropertiesAlphabetically) ?? false
        isGeneratingCustomCodingKeys = try container.decodeIfPresent(Bool.self, forKey: .isGeneratingCustomCodingKeys) ?? true
        isAddingDefaultValues = try container.decodeIfPresent(Bool.self, forKey: .isAddingDefaultValues) ?? true
        isInliningPropertiesFromReferencedSchemas = try container.decodeIfPresent(Bool.self, forKey: .isInliningPropertiesFromReferencedSchemas) ?? false
        isAdditionalPropertiesOnByDefault = try container.decodeIfPresent(Bool.self, forKey: .isAdditionalPropertiesOnByDefault) ?? true
        isStrippingParentNameInNestedObjects = try container.decodeIfPresent(Bool.self, forKey: .isStrippingParentNameInNestedObjects) ?? false
        exclude = try container.decodeIfPresent(Set<String>.self, forKey: .exclude) ?? []
        include = try container.decodeIfPresent(Set<String>.self, forKey: .include) ?? []
    }
}

extension GenerateOptions.Paths: Decodable {
    enum CodingKeys: String, CodingKey {
        case style
        case namespace
        case isGeneratingResponseHeaders
        case isAddingOperationIds
        case imports
        case overridenResponses
        case overridenBodyTypes
        case isInliningSimpleRequests
        case isInliningSimpleQueryParameters
        case simpleQueryParametersThreshold
        case isMakingOptionalPatchParametersDoubleOptional
        case isRemovingRedundantPaths
        case exclude
        case include
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        style = try container.decodeIfPresent(GenerateOptions.PathsStyle.self, forKey: .style) ?? .rest
        namespace = try container.decodeIfPresent(String.self, forKey: .namespace) ?? "Paths"
        isGeneratingResponseHeaders = try container.decodeIfPresent(Bool.self, forKey: .isGeneratingResponseHeaders) ?? true
        isAddingOperationIds = try container.decodeIfPresent(Bool.self, forKey: .isAddingOperationIds) ?? false
        imports = try container.decodeIfPresent(Set<String>.self, forKey: .imports) ?? ["Get"]
        overridenResponses = try container.decodeIfPresent([String: String].self, forKey: .overridenResponses) ?? [:]
        overridenBodyTypes = try container.decodeIfPresent([String: String].self, forKey: .overridenBodyTypes) ?? [:]
        isInliningSimpleRequests = try container.decodeIfPresent(Bool.self, forKey: .isInliningSimpleRequests) ?? true
        isInliningSimpleQueryParameters = try container.decodeIfPresent(Bool.self, forKey: .isInliningSimpleQueryParameters) ?? true
        simpleQueryParametersThreshold = try container.decodeIfPresent(Int.self, forKey: .simpleQueryParametersThreshold) ?? 2
        isMakingOptionalPatchParametersDoubleOptional = try container.decodeIfPresent(Bool.self, forKey: .isMakingOptionalPatchParametersDoubleOptional) ?? false
        isRemovingRedundantPaths = try container.decodeIfPresent(Bool.self, forKey: .isRemovingRedundantPaths) ?? true
        exclude = try container.decodeIfPresent(Set<String>.self, forKey: .exclude) ?? []
        include = try container.decodeIfPresent(Set<String>.self, forKey: .include) ?? []
    }
}

extension GenerateOptions.Rename: Decodable {
    enum CodingKeys: String, CodingKey {
        case properties
        case parameters
        case enumCases
        case entities
        case operations
        case collectionElements
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        properties = try container.decodeIfPresent([String: String].self, forKey: .properties) ?? [:]
        parameters = try container.decodeIfPresent([String: String].self, forKey: .parameters) ?? [:]
        enumCases = try container.decodeIfPresent([String: String].self, forKey: .enumCases) ?? [:]
        entities = try container.decodeIfPresent([String: String].self, forKey: .entities) ?? [:]
        operations = try container.decodeIfPresent([String: String].self, forKey: .operations) ?? [:]
        collectionElements = try container.decodeIfPresent([String: String].self, forKey: .collectionElements) ?? [:]
    }
}

