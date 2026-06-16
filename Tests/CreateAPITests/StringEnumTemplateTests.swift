import XCTest
@testable import CreateOptions
@testable import create_api

final class StringEnumTemplateTests: XCTestCase {
    func testEnumOfStrings_whenUnknownCasesDisabled_shouldRenderRawValueEnum() {
        let rendered = Templates(options: GenerateOptions()).enumOfStrings(
            name: TypeName("DailyFeeType"),
            cases: [
                .init(name: "interest", key: "Interest"),
                .init(name: "custodyFee", key: "CustodyFee")
            ],
            includeUnknownCase: false
        )

        XCTAssertEqual(
            rendered,
            """
            public enum DailyFeeType: String, Codable, CaseIterable {
                case interest = "Interest"
                case custodyFee = "CustodyFee"
            }
            """
        )
    }

    func testEnumOfStrings_whenUnknownCasesEnabled_shouldPreserveKnownCasesAndCaptureUnknownRawValues() {
        let rendered = Templates(options: unknownCaseOptions()).enumOfStrings(
            name: TypeName("DailyFeeType"),
            cases: [
                .init(name: "interest", key: "Interest"),
                .init(name: "custodyFee", key: "CustodyFee")
            ],
            includeUnknownCase: true
        )

        XCTAssertEqual(
            rendered,
            """
            public enum DailyFeeType: Codable, Hashable, CaseIterable, RawRepresentable {
                case interest
                case custodyFee
                case unknown(String)

                public static var allCases: [Self] {
                    [
                        .interest,
                        .custodyFee,
                    ]
                }

                public var rawValue: String {
                    switch self {
                    case .interest:
                        return "Interest"
                    case .custodyFee:
                        return "CustodyFee"
                    case .unknown(let rawValue):
                        return rawValue
                    }
                }

                public init?(rawValue: String) {
                    switch rawValue {
                    case "Interest":
                        self = .interest
                    case "CustodyFee":
                        self = .custodyFee
                    default:
                        self = .unknown(rawValue)
                    }
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown(rawValue)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(rawValue)
                }
            }
            """
        )
    }

    func testEnumOfStrings_whenUnknownCasesEnabledButEnumIsNotEligible_shouldRenderRawValueEnum() {
        let rendered = Templates(options: unknownCaseOptions()).enumOfStrings(
            name: TypeName("DailyFeeType"),
            cases: [
                .init(name: "interest", key: "Interest"),
                .init(name: "custodyFee", key: "CustodyFee")
            ],
            includeUnknownCase: false
        )

        XCTAssertEqual(
            rendered,
            """
            public enum DailyFeeType: String, Codable, CaseIterable {
                case interest = "Interest"
                case custodyFee = "CustodyFee"
            }
            """
        )
    }

    func testEnumOfStrings_whenUnknownCasesEnabledAndKnownCaseIsNamedUnknown_shouldUseAlternateUnknownCaseName() {
        let rendered = Templates(options: unknownCaseOptions()).enumOfStrings(
            name: TypeName("Status"),
            cases: [
                .init(name: "unknown", key: "unknown")
            ],
            includeUnknownCase: true
        )

        XCTAssertTrue(rendered.contains("case unknown"))
        XCTAssertTrue(rendered.contains("case unknownValue(String)"))
        XCTAssertTrue(rendered.contains("case .unknownValue(let rawValue):"))
        XCTAssertTrue(rendered.contains("self = .unknownValue(rawValue)"))
    }

    private func unknownCaseOptions() -> GenerateOptions {
        var configOptions = ConfigOptions.default
        configOptions.includeUnknownCaseInStringEnums = true
        return GenerateOptions(configOptions: configOptions)
    }
}
