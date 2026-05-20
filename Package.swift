// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OndselSolver",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
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
        .executableTarget(
            name: "ondselsolver-smoke",
            dependencies: ["OndselSolverCxx"],
            path: "Sources/ondselsolver-smoke"
        ),
    ],
    cxxLanguageStandard: .cxx17
)
