// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation

extension Generator {
    func makePackageFile(name: String) -> String {
        let packages: String = [
            #".package(url: "https://github.com/kean/Get", from: "0.3.1")"#,
            isHTTPHeadersDependencyNeeded ? #".package(url: "https://github.com/kean/HTTPHeaders", from: "0.1.0")"# : nil,
            isNaiveDateNeeded ? #".package(url: "https://github.com/kean/NaiveDate", from: "1.0.0")"# : nil,
            isQueryEncoderNeeded ? #".package(url: "https://github.com/kean/URLQueryEncoder", branch: "0.2.0")"# : nil,
                
        ].compactMap { $0 }.joined(separator: ", \n")
        
        let dependencies: String = [
            #".product(name: "Get", package: "Get")"#,
            isHTTPHeadersDependencyNeeded ? #".product(name: "HTTPHeaders", package: "HTTPHeaders")"# : nil,
            isNaiveDateNeeded ? #".product(name: "NaiveDate", package: "NaiveDate")"# : nil,
            isQueryEncoderNeeded ? #".product(name: "URLQueryEncoder", package: "URLQueryEncoder")"# : nil,
        ].compactMap { $0 }.joined(separator: ", \n")
        
        
        return """
        // swift-tools-version:5.5
        // The swift-tools-version declares the minimum version of Swift required to build this package.
        
        import PackageDescription
        
        let package = Package(
            name: "\(name)",
            platforms: [.iOS(.v13), .macCatalyst(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
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
