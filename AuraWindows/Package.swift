// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AuraWindows",
    platforms: [
        .macOS(.v14) // SPM требует указать платформу, но мы будем собирать это под Windows
    ],
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
