import XCTest
import class Foundation.Bundle
@testable import NanoGen

final class NanoGenTests: XCTestCase {
    func testExample() throws {
        // Mac Catalyst won't have `Process`, but it is supported for executables.
        #if !targetEnvironment(macCatalyst)

        let fooBinary = productsDirectory.appendingPathComponent("NanoGen")

        let process = Process()
        process.executableURL = fooBinary

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        XCTAssertEqual(output, "Hello, world!\n")
        #endif
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }
    
    func testMakeType() {
        XCTAssertEqual(makeType("app"), "App")
        XCTAssertEqual(makeType("app-manifests"), "AppManifests")
        XCTAssertEqual(makeType("{code}"), "WithCode")
        XCTAssertEqual(makeType("appManifests"), "AppManifests")
    }
    
    func testMakeParameter() {
        XCTAssertEqual(makeParameter("app"), "app")
        XCTAssertEqual(makeParameter("app-manifests"), "appManifests")
        XCTAssertEqual(makeParameter("{code}"), "code")
        XCTAssertEqual(makeParameter("appManifests"), "appManifests")
        XCTAssertEqual(makeParameter("avatar_url"), "avatarURL")
        XCTAssertEqual(makeParameter("node_id"), "nodeID")
        XCTAssertEqual(makeParameter("+1"), "plus1")
    }
}
