// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

#warning("TODO: Update to latest releases")
extension Generator {
    func makePackageFile(name: String) -> String {
        let packages: String = [
            #".package(url: "https://github.com/kean/Get", branch: "main")"#,
            isHTTPHeadersDependencyNeeded ? #".package(url: "https://github.com/kean/HTTPHeaders", branch: "main")"# : nil,
            isNaiveDateNeeded ? #".package(url: "https://github.com/kean/NaiveDate", branch: "master")"# : nil
        ].compactMap { $0 }.joined(separator: ", \n")
        
        let dependencies: String = [
            #".product(name: "Get", package: "Get")"#,
            isHTTPHeadersDependencyNeeded ? #".product(name: "HTTPHeaders", package: "HTTPHeaders")"# : nil,
            isNaiveDateNeeded ? #".product(name: "NaiveDate", package: "NaiveDate")"# : nil,
        ].compactMap { $0 }.joined(separator: ", \n")
        
        
        return """
        // swift-tools-version:5.5
        // The swift-tools-version declares the minimum version of Swift required to build this package.
        
        import PackageDescription
        
        let package = Package(
            name: "\(name)",
            platforms: [.iOS(.v15), .macCatalyst(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)],
            products: [
                .library(name: "\(name)", targets: ["\(name)"]),
            ],
            dependencies: [
        \(packages.indented(count: 2))
            ],
            targets: [
                .target(name: "\(name)", dependencies: [
        \(dependencies.indented(count: 3))
                ], path: "Sources")
            ]
        )
        """
    }
}
