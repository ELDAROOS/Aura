// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AuraWindows",
    products: [
        .executable(name: "Aura", targets: ["Aura"])
    ],
    dependencies: [
        // Здесь в будущем будут зависимости для WinUI / WinRT
        // .package(url: "https://github.com/thebrowsercompany/swift-winrt", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "Aura",
            dependencies: [],
            path: "Sources"
        )
    ]
)
