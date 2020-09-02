// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Pantomime",
    platforms: [
        .iOS(.v10), .tvOS(.v10)
    ],
    products: [
        .library(name: "Pantomime", targets: ["Pantomime"])
    ],
    dependencies: [],
    targets: [
        .target(name: "Pantomime", dependencies: [], path: "sources")
    ],
    swiftLanguageVersions: [.v5]
)
