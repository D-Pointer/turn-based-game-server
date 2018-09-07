// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "turn-based-server",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.8"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),

        .package(url: "https://github.com/vapor/auth.git", from: "2.0.1")
    ],
    targets: [
        .target(name: "turn-based-server", dependencies: ["FluentSQLite", "Vapor", "Authentication"], path: "Sources")
    ]
)

