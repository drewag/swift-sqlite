// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SQLite",
    platforms: [.iOS(.v9), .macOS(.v10_11), .tvOS(.v9)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SQLite",
            targets: ["SQLite"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/drewag/swift-sql.git", from: "5.0.0"),
        .package(url: "https://github.com/stephencelis/CSQLite.git", from: "0.0.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SQLite",
            dependencies: ["SQL"]),
        .testTarget(
            name: "SQLiteTests",
            dependencies: ["SQLite"]),
    ]
)
