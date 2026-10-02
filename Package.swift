// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HowdyKit",
    platforms: [
        // The apps target iOS 27, so the floor follows them. Observation
        // (`@Observable`) is what makes `OnboardingFlow` itself reactive,
        // not just the views reading it.
        .iOS("27.0"),
        .macOS("27.0"),
        .watchOS("27.0"),
        .tvOS("27.0"),
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
        .testTarget(name: "HowdyKitUITests", dependencies: ["HowdyKitUI"]),
    ]
)
