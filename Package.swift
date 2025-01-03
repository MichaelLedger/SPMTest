// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
/*
 x-xcode-log://B1630E03-1A90-4B16-AD71-29723E4F88C5 ignoring broken symlink /Users/gavinxiang/Downloads/SPMTest/Performance/Sources/include/OCModel.h
 x-xcode-log://B1630E03-1A90-4B16-AD71-29723E4F88C5 target at '/Users/gavinxiang/Downloads/SPMTest/Performance/Sources' contains mixed language source files; feature not supported
 */

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
        ),
        .library(name: "SPMLib", type: .dynamic, targets: ["SPMLib"])
    ],
    dependencies: [
        .package(url: "git@github.com:RxSwiftCommunity/RxGesture.git", .upToNextMajor(from: "4.0.4")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.8.0"))
    ],
    targets: [
        // Objective-C Library
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
        // Swift Library
        .target(
            name: "Performance",
            dependencies: [],
            path: "Performance/Sources",
            exclude: ["Performance/Objective-C", "include"],
            resources: [.copy("Resources/PrivacyInfo.xcprivacy")]
//            publicHeadersPath: "Performance/Sources/include",
//            cSettings: [
//                .headerSearchPath(".")
//            ]
        ),
        .testTarget(name: "PerformanceTests", dependencies: ["Performance"]),
        // Mixed Swift and Objective-C Libraries
        .target(name: "SPMLib",
                dependencies: ["MJRefresh",
                               "Performance",
                               "RxGesture",
                               "RxSwift"],
                path: "SPMTest"),
        .testTarget(name: "SPMTests", dependencies: ["SPMLib"], path: "Tests/SPMTests")
    ],
    swiftLanguageVersions: [.v5]
)
