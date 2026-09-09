// swift-tools-version:5.9

// Charty plugin for Publish
// Copyright (c) Mark Battistella 2026
// MIT license - see LICENSE for details

import PackageDescription

let package = Package(
	name: "Charty",
	platforms: [.macOS(.v10_15)],
	products: [
		.library(
			name: "Charty",
			targets: ["Charty"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/johnsundell/publish.git", from: "0.8.0")
	],
	targets: [
		.target(
			name: "Charty",
			dependencies: [
				.product(name: "Publish", package: "publish")
			],
			resources: [
				.process("Resources")
			]
		),
		.testTarget(
			name: "ChartyTests",
			dependencies: ["Charty"]
		)
	]
)
