// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OndselSolver",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "OndselSolver", targets: ["OndselSolver"]),
        .library(name: "OndselSolverCxx", targets: ["OndselSolverCxx"]),
    ],
    targets: [
        .target(
            name: "OndselSolverCxx",
            path: "OndselSolver",
            // publicHeadersPath "." keeps the flat upstream layout intact —
            // every header sits beside its source; see docs/superpowers/.
            publicHeadersPath: "."
        ),
        .target(
            name: "OndselSolver",
            dependencies: ["OndselSolverCxx"],
            path: "Sources/OndselSolver",
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .executableTarget(
            name: "ondselsolver-smoke",
            dependencies: ["OndselSolverCxx"],
            path: "Sources/ondselsolver-smoke"
        ),
        .testTarget(
            name: "OndselSolverTests",
            dependencies: ["OndselSolverCxx"],
            path: "Tests/OndselSolverTests",
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
    ],
    cxxLanguageStandard: .cxx17
)
