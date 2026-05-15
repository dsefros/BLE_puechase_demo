// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BlePaymentKit",
    platforms: [.iOS(.v13), .macOS(.v12)],
    products: [
        .library(name: "BlePaymentKit", targets: ["BlePaymentKit"]),
    ],
    targets: [
        .target(name: "BlePaymentKit"),
        .testTarget(name: "BlePaymentKitTests", dependencies: ["BlePaymentKit"]),
    ]
)
