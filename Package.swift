// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CareKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v14), .macOS(.v13), .watchOS(.v7)],
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
            targets: ["CareKitFHIR"]),

    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/FHIRModels.git",
            exact: Version(0, 4, 0)
        ),
        .package(
            url: "https://github.com/apple/swift-async-algorithms",
            exact: Version(1, 0, 1)
        )
    ],
    targets: [
        .target(
            name: "CareKit",
            dependencies: ["CareKitUI", "CareKitStore"],
            path: "CareKit/CareKit",
            exclude: ["Info.plist"]),

        .target(
            name: "CareKitUI",
            path: "CareKitUI/CareKitUI",
            exclude: ["Info.plist"]),

        .target(
            name: "CareKitStore",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ],
            path: "CareKitStore/CareKitStore",
            exclude: ["Info.plist"],
            resources: [
                .process("CoreData/Migrations/2_0To2_1/2.0_2.1_Mapping.xcmappingmodel")
            ]),

        .target(
            name: "CareKitFHIR",
            dependencies: [
                "CareKitStore",
                .product(name: "ModelsR4", package: "FHIRModels"),
                .product(name: "ModelsDSTU2", package: "FHIRModels")
            ],
            path: "CareKitFHIR/CareKitFHIR",
            exclude: ["Info.plist"]),

        .testTarget(
            name: "CareKitStoreTests",
            dependencies: ["CareKitStore"],
            path: "CareKitStore/CareKitStoreTests",
            exclude: ["Info.plist", "CareKitStore.xctestplan"],
            resources: [
                .process("CoreDataSchema/Migrations")
            ]),

        .testTarget(
            name: "CareKitUITests",
            dependencies: ["CareKitUI"],
            path: "CareKitUI/CareKitUITests",
            exclude: ["Info.plist", "CareKitUI.xctestplan"]),

        .testTarget(
            name: "CareKitFHIRTests",
            dependencies: ["CareKitFHIR"],
            path: "CareKitFHIR/CareKitFHIRTests",
            exclude: ["Info.plist", "CareKitFHIR.xctestplan"]),

        .testTarget(
            name: "CareKitTests",
            dependencies: ["CareKit"],
            path: "CareKit/CareKitTests",
            exclude: ["Info.plist"]),

    ]
)
