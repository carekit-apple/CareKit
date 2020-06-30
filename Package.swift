// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "CareKit",
    platforms: [.iOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "CareKit",
            targets: ["CareKit"]),

        .library(
            name: "CareKitUI",
            targets: ["CareKitUI"]),

        .library(
            name: "CareKitStore",
            targets: ["CareKitStore"]),

        .library(
            name: "CareKitFHIR",
            targets: ["CareKitFHIR"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/FHIRModels.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "CareKit",
            dependencies: ["CareKitUI", "CareKitStore"],
            path: "CareKit/CareKit"),

        .target(
            name: "CareKitUI",
            path: "CareKitUI/CareKitUI"),

        .target(
            name: "CareKitStore",
            path: "CareKitStore/CareKitStore"),

        .target(
            name: "CareKitFHIR",
            dependencies: ["CareKitStore", "ModelsR4", "ModelsDSTU2"],
            path: "CareKitFHIR/CareKitFHIR"),

        .testTarget(
            name: "CareKitStoreTests",
            dependencies: ["CareKitStore"],
            path: "CareKitStore/CareKitStoreTests"),

        .testTarget(
            name: "CareKitFHIRTests",
            dependencies: ["CareKitFHIR"],
            path: "CareKitFHIR/CareKitFHIRTests"),

        .testTarget(
            name: "CareKitTests",
            dependencies: ["CareKit"],
            path: "CareKit/CareKitTests")
    ]
)
