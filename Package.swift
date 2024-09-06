// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

fileprivate func repo(_ repo: String) -> String {
	return "https://github.com/josephlevy222/" + repo + ".git"
}

let package = Package(
	name: "XYPlot",
	platforms: [.macOS(.v12), .iOS("15.5")],
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "XYPlot",
			targets: ["XYPlot"]),
	],
	dependencies: [.package(url: repo("Utilities"), branch: "main"),
				   .package(url: repo("NumericTextField"), branch: "main"),
				   .package(url: repo("EditableText"), branch: "main")
				   // Dependencies declare other packages that this package depends on.
				   // .package(url: /* package url */, from: "1.0.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.target(
			name: "XYPlot",
			dependencies: ["Utilities","NumericTextField","EditableText"/*,"RichTextEditor"*/]
			//,resources: [.process("Resources")]
		),
		//        .testTarget(
		//            name: "XYPlotTests",
		//            dependencies: ["XYPlot"]),
	]
)

