// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "dependency-appstorage-TCA",
    platforms: [
      .iOS(.v13),
      .macOS(.v10_15),
      .tvOS(.v13),
      .watchOS(.v6),
    ],
    products: [
        .library(
            name: "DependencyAppStorageTCA",
            targets: ["DependencyAppStorageTCA"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tgrapperon/swift-dependencies-additions.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DependencyAppStorageTCA",
            dependencies: [
                .product(name: "_AppStorageDependency", package: "swift-dependencies-additions"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]),
        .testTarget(
            name: "DependencyAppStorageTCATests",
            dependencies: ["DependencyAppStorageTCA"]),
    ]
)
