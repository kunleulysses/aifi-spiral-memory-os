// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AIFiSpiralMemoryOS",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AIFiCreatureCore",
            targets: ["AIFiCreatureCore"]
        ),
        .executable(
            name: "aifi-creature-demo",
            targets: ["AIFiCreatureDemo"]
        )
    ],
    targets: [
        .target(
            name: "AIFiCreatureCore"
        ),
        .executableTarget(
            name: "AIFiCreatureDemo",
            dependencies: ["AIFiCreatureCore"]
        ),
        .testTarget(
            name: "AIFiCreatureCoreTests",
            dependencies: ["AIFiCreatureCore"]
        )
    ]
)
