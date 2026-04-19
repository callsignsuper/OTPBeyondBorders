// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OTPKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13)
    ],
    products: [
        .library(name: "OTPKit", targets: ["OTPKit"])
    ],
    targets: [
        .target(
            name: "OTPKit",
            path: "Sources/OTPKit",
            resources: [
                .copy("Resources/timelines"),
                .copy("Resources/data")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "OTPKitTests",
            dependencies: ["OTPKit"],
            path: "Tests/OTPKitTests",
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
