import Foundation

@dynamicMemberLookup
public final class GenerateOptions {
    /// The options loaded from a **create-api.yaml** configuration file (or the default options)
    public let configOptions: ConfigOptions

    /// Acronyms used for replacement when `isReplacingCommonAcronyms` is `true`.
    ///
    /// A set of all acronyms based on the default list after factoring in the `addedAcronyms` and removing `ignoredAcronyms`.
    /// Results are ordered so that the longer acronyms come first.
    public let allAcronyms: [String]

    public init(configOptions: ConfigOptions = .default) {
        self.configOptions = configOptions
        self.allAcronyms = Self.allAcronyms(including: configOptions.addedAcronyms, excluding: configOptions.ignoredAcronyms)
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<ConfigOptions, T>) -> T {
        configOptions[keyPath: keyPath]
    }
}

// MARK: - Acronyms
private extension GenerateOptions {
    static let defaultAcronyms: Set<String> = ["url", "id", "html", "ssl", "tls", "https", "http", "dns", "ftp", "api", "uuid", "json"]

    static func allAcronyms(including: [String], excluding: [String]) -> [String] {
        Self.defaultAcronyms
            .union(including)
            .subtracting(excluding)
            .sorted { $0.count > $1.count }
    }
}
