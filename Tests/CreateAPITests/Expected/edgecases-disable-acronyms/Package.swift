// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "edgecases-disable-acronyms",
    platforms: [.iOS(.v13), .macCatalyst(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "edgecases-disable-acronyms", targets: ["edgecases-disable-acronyms"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CreateAPI/Get", from: "0.3.1"), 
        .package(url: "https://github.com/CreateAPI/HTTPHeaders", from: "0.1.0"), 
        .package(url: "https://github.com/CreateAPI/NaiveDate", from: "1.0.0"), 
        .package(url: "https://github.com/CreateAPI/URLQueryEncoder", from: "0.2.0")
    ],
    targets: [
        .target(name: "edgecases-disable-acronyms", dependencies: [
            .product(name: "Get", package: "Get"), 
            .product(name: "HTTPHeaders", package: "HTTPHeaders"), 
            .product(name: "NaiveDate", package: "NaiveDate"), 
            .product(name: "URLQueryEncoder", package: "URLQueryEncoder")
        ], path: "Sources")
    ]
)