// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TicketmasterAPI",
    platforms: [.iOS(.v15), .macCatalyst(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)],
    products: [
        .library(name: "TicketmasterAPI", targets: ["TicketmasterAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Get", branch: "main"), 
        .package(url: "https://github.com/kean/NaiveDate", branch: "master")
    ],
    targets: [
        .target(name: "TicketmasterAPI", dependencies: [
            .product(name: "Get", package: "Get"), 
            .product(name: "NaiveDate", package: "NaiveDate")
        ], path: "Sources")
    ]
)