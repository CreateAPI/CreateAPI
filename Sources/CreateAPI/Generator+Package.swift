// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import Foundation

extension Generator {
    func makePackageFile(name: String) -> String {
        let packages: String = [
            #".package(url: "https://github.com/kean/APIClient", branch: "main")"#,
            isHTTPHeadersDependencyNeeded ? #".package(url: "https://github.com/kean/HTTPHeaders", branch: "main")"# : nil,
        ].compactMap { $0 }.joined(separator: ", \n")
        
        let dependencies: String = [
            #".product(name: "APIClient", package: "APIClient")"#,
            isHTTPHeadersDependencyNeeded ? #".product(name: "HTTPHeaders", package: "HTTPHeaders")"# : nil
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
