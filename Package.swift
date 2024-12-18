// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMTest",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "MJRefresh", targets: ["MJRefresh"]),
        .library(
            name: "Performance",
            targets: ["Performance"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MJRefresh",
            dependencies: [],
            path: "MJRefresh",
            exclude: ["Info.plist"],
            resources: [.process("MJRefresh.bundle"), .copy("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [
                //Config header path
                .headerSearchPath("."),
            ]
        ),
        .testTarget(name: "MJRefreshExampleTests", dependencies: ["MJRefresh"], path: "Examples/MJRefreshExample/MJRefreshExampleTests"),
        .target(
            name: "Performance",
            path: "Sources",
            resources: [.copy("Resources/PrivacyInfo.xcprivacy")]
        ),
        .testTarget(name: "PerformanceTests", dependencies: ["Performance"])
    ],
    swiftLanguageVersions: [.v5]
)
