// swift-tools-version:6.1

import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_CONCISE_MAGIC_FILE"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_DEPRECATE_APPLICATION_MAIN"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_DISABLE_OUTWARD_ACTOR_ISOLATION"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_DYNAMIC_ACTOR_ISOLATION"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_FORWARD_TRAILING_CLOSURES"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_GLOBAL_ACTOR_ISOLATED_TYPES_USABILITY"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_IMPLICIT_OPEN_EXISTENTIALS"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_IMPORT_OBJC_FORWARD_DECLS"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_ISOLATED_DEFAULT_VALUES"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_GLOBAL_CONCURRENCY"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_NONFROZEN_ENUM_EXHAUSTIVITY"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_REGION_BASED_ISOLATION"),
    .enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES"),
    .enableExperimentalFeature("StrictConcurrency=complete")
]

let package = Package(
    name: "CareKit",
    defaultLocalization: "en",
    platforms: [.iOS("18.0"), .macOS("15.0"), .watchOS("11.0")],
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
            .upToNextMajor(from: Version(0, 5, 0))
        ),
        .package(
            url: "https://github.com/apple/swift-async-algorithms",
            .upToNextMajor(from: Version(1, 0, 1))
        )
    ],
    targets: [
        .target(
            name: "CareKit",
            dependencies: ["CareKitUI", "CareKitStore"],
            path: "CareKit/CareKit",
            exclude: ["Info.plist"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "CareKitUI",
            path: "CareKitUI/CareKitUI",
            exclude: ["Info.plist"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "CareKitStore",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ],
            path: "CareKitStore/CareKitStore",
            exclude: ["Info.plist"],
            resources: [
                .process("CoreData/Migrations/2_0To2_1/2.0_2.1_Mapping.xcmappingmodel"),
                .process("CoreData/Migrations/2_1To3_0/2.1_3.0_Mapping.xcmappingmodel")
            ],
            swiftSettings: sharedSwiftSettings,
        ),
        .target(
            name: "CareKitFHIR",
            dependencies: [
                "CareKitStore",
                .product(name: "ModelsR4", package: "FHIRModels"),
                .product(name: "ModelsDSTU2", package: "FHIRModels")
            ],
            path: "CareKitFHIR/CareKitFHIR",
            exclude: ["Info.plist"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "CareKitStoreTests",
            dependencies: ["CareKitStore"],
            path: "CareKitStore/CareKitStoreTests",
            exclude: ["Info.plist", "CareKitStore.xctestplan"],
            resources: [
                .process("CoreDataSchema/Migrations")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "CareKitUITests",
            dependencies: ["CareKitUI"],
            path: "CareKitUI/CareKitUITests",
            exclude: ["Info.plist", "CareKitUI.xctestplan"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "CareKitFHIRTests",
            dependencies: ["CareKitFHIR"],
            path: "CareKitFHIR/CareKitFHIRTests",
            exclude: ["Info.plist", "CareKitFHIR.xctestplan"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "CareKitTests",
            dependencies: ["CareKit"],
            path: "CareKit/CareKitTests",
            exclude: ["Info.plist"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
    ]
)
