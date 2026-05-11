// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

// A test helper that allows us to compile all generated packages quickly and easily

import PackageDescription

let package = Package(
    name: "AllPackages",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "AllPackages", targets: ["AllPackages"])
    ],
    dependencies: [
        .package(path: "../Snapshots/cookpad"),
        .package(path: "../Snapshots/discriminator"),
        .package(path: "../Snapshots/edgecases-change-access-control"),
        .package(path: "../Snapshots/edgecases-coding-keys"),
        .package(path: "../Snapshots/edgecases-data-types"),
        .package(path: "../Snapshots/edgecases-default"),
        .package(path: "../Snapshots/edgecases-disable-acronyms"),
        .package(path: "../Snapshots/edgecases-disable-enums"),
        .package(path: "../Snapshots/edgecases-enum-protocols"),
        .package(path: "../Snapshots/edgecases-indent-with-two-width-spaces"),
        .package(path: "../Snapshots/edgecases-rename"),
        .package(path: "../Snapshots/edgecases-rename-properties"),
        .package(path: "../Snapshots/edgecases-tabs"),
        .package(path: "../Snapshots/edgecases-yaml-config"),
        .package(path: "../Snapshots/inlining-default"),
        .package(path: "../Snapshots/OctoKit"),
        .package(path: "../Snapshots/petstore-base-class"),
        .package(path: "../Snapshots/petstore-change-entityname"),
        .package(path: "../Snapshots/petstore-change-namespace-when-operations-style"),
        .package(path: "../Snapshots/petstore-change-namespace-when-rest-style"),
        .package(path: "../Snapshots/petstore-custom-imports"),
        .package(path: "../Snapshots/petstore-default"),
        .package(path: "../Snapshots/petstore-disable-comments"),
        .package(path: "../Snapshots/petstore-disable-init-with-coder"),
        .package(path: "../Snapshots/petstore-disable-inlining"),
        .package(path: "../Snapshots/petstore-disable-mutable-properties"),
        .package(path: "../Snapshots/petstore-enable-mutable-properties"),
        .package(path: "../Snapshots/petstore-entity-exclude"),
        .package(path: "../Snapshots/petstore-filename-template"),
        .package(path: "../Snapshots/petstore-generate-classes"),
        .package(path: "../Snapshots/petstore-identifiable"),
        .package(path: "../Snapshots/petstore-merge-sources"),
        .package(path: "../Snapshots/petstore-only-schemas"),
        .package(path: "../Snapshots/petstore-single-threaded"),
        .package(path: "../Snapshots/petstore-some-entities-as-classes"),
        .package(path: "../Snapshots/petstore-some-entities-as-structs"),
        .package(path: "../Snapshots/petstore-SPM-imports"),
        .package(path: "../Snapshots/petstore-SPM-imports-linux"),
        .package(path: "../Snapshots/strip-parent-name-nested-objects-default"),
        .package(path: "../Snapshots/strip-parent-name-nested-objects-enabled"),
        .package(path: "../Snapshots/test-query-parameters")
    ],
    targets: [
        .target(
            name: "AllPackages",
            dependencies: [
                "cookpad",
                "discriminator",
                "edgecases-change-access-control",
                "edgecases-coding-keys",
                "edgecases-data-types",
                "edgecases-default",
                "edgecases-disable-acronyms",
                "edgecases-disable-enums",
                "edgecases-enum-protocols",
                "edgecases-indent-with-two-width-spaces",
                "edgecases-rename",
                "edgecases-rename-properties",
                "edgecases-tabs",
                "edgecases-yaml-config",
                "inlining-default",
                "OctoKit",
                "petstore-base-class",
                "petstore-change-entityname",
                "petstore-change-namespace-when-operations-style",
                "petstore-change-namespace-when-rest-style",
                .byName(name: "petstore-custom-imports", condition: .when(platforms: [.macOS])),
                "petstore-default",
                "petstore-disable-comments",
                "petstore-disable-init-with-coder",
                "petstore-disable-inlining",
                "petstore-disable-mutable-properties",
                "petstore-enable-mutable-properties",
                "petstore-entity-exclude",
                "petstore-filename-template",
                "petstore-generate-classes",
                "petstore-identifiable",
                "petstore-merge-sources",
                "petstore-only-schemas",
                "petstore-single-threaded",
                "petstore-some-entities-as-classes",
                "petstore-some-entities-as-structs",
                .byName(name: "petstore-SPM-imports", condition: .when(platforms: [.macOS])),
                "petstore-SPM-imports-linux",
                "strip-parent-name-nested-objects-default",
                "strip-parent-name-nested-objects-enabled",
                "test-query-parameters"
            ],
            path: "Sources"
        )
    ]
)
