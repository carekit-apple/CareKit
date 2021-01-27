// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "CareKit",
    defaultLocalization: "en",
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
            path: "CareKitStore/CareKitStore",
            resources: [.copy("CoreData/CareKitStore.xcdatamodel")]),

        .target(
            name: "CareKitFHIR",
            dependencies: ["CareKitStore", .product(name: "ModelsR4", package: "FHIRModels"), .product(name: "ModelsDSTU2", package: "FHIRModels")],
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
