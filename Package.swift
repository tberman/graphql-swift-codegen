// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "graphql-code-gen",
    dependencies: [
        .package(url: "https://github.com/kylef/Commander.git", from: "0.7.1"),
        .package(url: "https://github.com/lyft/mapper.git", from: "7.1.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.5.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "graphql-code-gen",
            dependencies: ["Commander","Mapper","Alamofire"]),
    ]
)
