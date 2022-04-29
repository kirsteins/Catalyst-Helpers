import PackageDescription

let package = Package(
    name: "CatalystHelpers",
    products: [
        .library(name: "CatalystHelpers", targets: ["CatalystHelpers"]),
    ],
    targets: [
        .target(name: "SwiftLeePackage", dependencies: ["objc"]),
    ]
)
