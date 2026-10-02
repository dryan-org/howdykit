// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HowdyKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15),
    ],
    products: [
        // Storage only: step identity, tri-state records, flow queries. No
        // SwiftUI import, so a watch target that only needs the completion
        // check doesn't pull in a UI module it never uses.
        .library(name: "HowdyKit", targets: ["HowdyKit"]),
        // The step view: theme, header, actions. Separate product so a
        // watchOS target never needs to compile this; only consumers that
        // explicitly link it do.
        .library(name: "HowdyKitUI", targets: ["HowdyKitUI"]),
    ],
    targets: [
        .target(name: "HowdyKit"),
        .testTarget(name: "HowdyKitTests", dependencies: ["HowdyKit"]),
        .target(name: "HowdyKitUI", dependencies: ["HowdyKit"]),
    ]
)
