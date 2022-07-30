import Foundation

struct GenerateArguments {
    let isVerbose: Bool
    let isParallel: Bool
    let isStrict: Bool
    let isIgnoringErrors: Bool
    let vendor: String?
    let module: ModuleName
    let entityNameTemplate: String
}
