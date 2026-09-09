// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "ChartyDocs",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "ChartyDocs", targets: ["ChartyDocs"])
    ],
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.8.0"),
        .package(name: "Charty", path: "../"),
    ],
    targets: [
        .executableTarget(
            name: "ChartyDocs",
            dependencies: [
                .product(name: "Publish", package: "publish"),
                .product(name: "Charty", package: "Charty"),
            ]
        )
    ]
)
