import Foundation

// TODO: This needs making thread safe.
extension GenerateOptions {
    private static let defaultAcronyms: Set<String> = ["url", "id", "html", "ssl", "tls", "https", "http", "dns", "ftp", "api", "uuid", "json"]
    private static var cache: [Int: [String]] = [:]

    /// A set of all acronyms based on the default list after factoring in the `addedAcronyms` and removing `ignoredAcronyms`.
    /// Results are ordered so that the longer acronyms come first.
    public var allAcronyms: [String] {
        var hasher = Hasher()
        hasher.combine(addedAcronyms)
        hasher.combine(ignoredAcronyms)
        let hashValue = hasher.finalize()

        if let cached = Self.cache[hashValue] {
            return cached
        }

        let allAcronyms = Self.defaultAcronyms
            .union(addedAcronyms)
            .subtracting(ignoredAcronyms)
            .sorted { $0.count > $1.count }

        Self.cache[hashValue] = allAcronyms
        return allAcronyms
    }
}
