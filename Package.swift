// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CatalystHelpers",
    products: [
        .library(name: "CatalystHelpers", targets: ["CatalystHelpers"]),
    ],
    targets: [
        .target(name: "CatalystHelpers", dependencies: ["objc"]),
    ]
)
