# OndselSolver SwiftPM Spin-off — Design Spec

- **Date:** 2026-05-19
- **Status:** Approved (design); pending implementation plan
- **Scope:** `deps/OndselSolver`

## Context

OndselSolver is a C++ assembly-constraint and multibody-dynamics solver
(the kinematics/dynamics engine behind FreeCAD's Assembly workbench).
Machina Scribo needs a constraint/dynamics solver alongside the
already-vendored planegcs 2D geometric solver; OndselSolver fills that
role.

This effort packages OndselSolver as a stand-alone, Swift-consumable
SwiftPM package, the same treatment given to `deps/planegcs` and
`deps/eigen` on 2026-05-19.

Unlike planegcs (extracted from inside the FreeCAD tree), OndselSolver
is already a complete stand-alone repository, forked to
`github.com/elhernes/OndselSolver`. The packaging work happens on its
`swiftpm` branch.

### Why direct SwiftPM, not an OCCT-style wrap

OCCT is built with CMake and wrapped as `.xcframework`s because its
CMake configuration is large and tangled — too costly to reproduce in
SwiftPM. OndselSolver is the opposite case:

- The library `CMakeLists.txt` is a flat list of source files compiled
  into a single library target. No `find_package`, no generated
  headers, no configure-time logic.
- Sources are C++17, standard-library only — no Eigen, no Boost.
  (`EigenDecomposition.cpp` is a homegrown routine, unrelated to the
  Eigen library.)
- The only non-portable couplings are already neutralised upstream:
  `<windows.h>`/`<debugapi.h>` are commented out in `Item.cpp`,
  `<BaseTsd.h>` is `#if defined(_WIN32)`-guarded in `Numeric.h`, and the
  FreeCAD `<Mod/Assembly/App/AssemblyObject.h>` include in
  `ExternalSystem.cpp` is commented out (its `Assembly::AssemblyObject*`
  member is a forward-declared pointer, never dereferenced).

A `Package.swift` can compile the existing sources directly. A
CMake→xcframework wrap would add a build-and-package step with no
benefit.

## Goal

A buildable SwiftPM package that exposes OndselSolver as a C++ target
for macOS and iOS, consumed by Swift via C++ interop, with a placeholder
Swift facade target reserved for a future idiomatic API.

### Non-goals

- An idiomatic Swift API over the solver. A placeholder Swift target is
  reserved for it; its design is a **separate later spec**.
- machina-scribo's consumption wiring (submodule / path dependency).
- Removing or replacing the existing CMake build. CMake, the
  Google Test suite, and `OndselSolverMain` stay in place, untouched.
- Widening the exposed module-map header set beyond what the smoke test
  needs.

## Migration strategy: additive packaging on a fork branch

OndselSolver is already its own repository, so there is no extraction.
The package is built **additively** on the `elhernes/OndselSolver` fork's
`swiftpm` branch:

- No existing `.cpp` or `.h` file is moved or edited. The Windows and
  FreeCAD couplings are already commented out upstream, so no
  decoupling work is required.
- The only file added *inside* upstream's source directory is a
  `module.modulemap`. Everything else (`Package.swift`, `UPSTREAM.md`,
  `Sources/`, `Tests/`, docs) lives outside it.

Because divergence from upstream `main` is purely additive, re-syncing
is an ordinary `git merge main` — no hand-applied diff, no
conflict-prone rewritten `#include` lines.

## Package layout

```
deps/OndselSolver/                    (existing repo, branch: swiftpm)
  Package.swift                       NEW  — at repo root
  UPSTREAM.md                         NEW  — provenance + re-sync recipe
  .gitignore                          EDIT — add SwiftPM build dirs
  README.md                           EDIT — note the SwiftPM package
  LICENSE                             keep — Ondsel license, inherited
  CMakeLists.txt                      keep — SwiftPM ignores it
  OndselSolverMain/                   keep — CMake-only standalone exe
  tests/                              keep — CMake-only gtest suite
  testapp/                            keep — CMake test data
  OndselSolver/
    CMakeLists.txt                    keep — CMake-only
    OndselSolver/                     the C++ library source
      *.cpp  *.h     (~318 + ~316 files, flat)   UNTOUCHED
      module.modulemap                NEW — curated module map
  Sources/
    OndselSolver/
      OndselSolver.swift              NEW — placeholder Swift facade
    ondselsolver-smoke/
      main.cpp                        NEW — C++ link smoke
  Tests/
    OndselSolverTests/
      OndselSolverSmokeTests.swift    NEW — Swift interop smoke
  docs/superpowers/specs/
    2026-05-19-ondselsolver-swiftpm-spinoff-design.md   NEW — this spec
```

## Targets and products

Two library products, mirroring the planegcs package:

| Target | Kind | Path | Role |
|---|---|---|---|
| `OndselSolverCxx` | C++ library | `OndselSolver/OndselSolver` | The real artifact. Compiles the flat source. |
| `OndselSolver` | Swift library | `Sources/OndselSolver` | Placeholder Swift facade. Depends on `OndselSolverCxx`. |
| `ondselsolver-smoke` | C++ executable | `Sources/ondselsolver-smoke` | C++ link/run verification. Depends on `OndselSolverCxx`. |
| `OndselSolverTests` | Swift test | `Tests/OndselSolverTests` | Swift/C++ interop verification. Depends on `OndselSolverCxx`. |

Products: `.library("OndselSolverCxx", …)` and `.library("OndselSolver", …)`.

### `OndselSolverCxx` — the C++ library target

- `path: "OndselSolver/OndselSolver"` — points at the existing flat
  source directory; no files move.
- Sources are auto-discovered (all `.cpp` in that directory).
- `publicHeadersPath: "."` — the source directory doubles as the public
  header directory. This puts the directory on the include path, so
  both the `.cpp` sources and the cross-including `.h` headers resolve
  their `#include "Foo.h"` lines.
- `cxxLanguageStandard: .cxx17` — the library `CMakeLists.txt` sets
  `CMAKE_CXX_STANDARD 17`, and a scan of the sources finds C++17
  features (`std::optional`, `std::variant`, `std::filesystem`) but no
  C++20 features (`<numbers>`, `<future>`, `<span>`, `operator<=>`).
- No preprocessor defines are needed: `TEST_DATA_PATH` is referenced
  only by `OndselSolverMain` and the gtest suite, never by the library
  sources.

### `OndselSolver` — the placeholder Swift facade

- `path: "Sources/OndselSolver"`, one file `OndselSolver.swift`.
- `dependencies: ["OndselSolverCxx"]`,
  `swiftSettings: [.interoperabilityMode(.Cxx)]`.
- Contents: a single `enum OndselSolver` namespace with a static
  constant recording the vendored upstream commit — mirroring the
  planegcs facade stub. It `import`s `OndselSolverCxx` so that the
  build proves the module is importable from Swift. No public solver
  API yet; that is a later spec.

## The module map

`OndselSolverCxx` ships a **hand-written `module.modulemap`** at
`OndselSolver/OndselSolver/module.modulemap` (the publicHeadersPath
root, where SwiftPM looks for a custom module map).

Rationale: with `publicHeadersPath: "."` and no custom map, SwiftPM
auto-generates a module map with `umbrella "."`, pulling all ~316
headers into one Clang module. A flat umbrella over a large,
order-sensitive C++ header set is fragile to compile as a single module
and presents a needlessly heavy surface to Swift/C++ interop.

The hand-written map instead:

- declares `module OndselSolverCxx` (name matches the target, so
  `import OndselSolverCxx` works);
- `requires cplusplus`;
- exposes a **curated, minimal set of headers** — the entry points the
  smoke test needs (`ASMTAssembly.h` and the headers it transitively
  requires to parse), and `export *`.

The future Swift-facade spec widens this set as the idiomatic API needs
more of the solver surface. Starting minimal keeps the interop surface
small and the initial build tractable.

The `module.modulemap` is the single local addition inside upstream's
source tree; `UPSTREAM.md` records it.

## Smoke tests

Two small targets verify the package from both sides. Both call
`ASMTAssembly::runSinglePendulum()` — a static method that builds a
single-pendulum model in code and runs the solver, with **no test-data
files**. (`ASMTAssembly` also offers `runSinglePendulumSimplified()` as
a lighter fallback if the full pendulum proves too heavy for the test
environment.)

- **`ondselsolver-smoke`** — a C++ executable (`main.cpp`) that calls
  `ASMTAssembly::runSinglePendulum()` and returns 0. Proves the C++
  library compiles and links as a SwiftPM target.
- **`OndselSolverTests`** — a Swift test target (C++ interop enabled)
  that calls the same static method through the imported
  `OndselSolverCxx` module. Proves the module map is valid and the
  solver is reachable across the Swift/C++ boundary.

Purpose: prove the package builds, links, and runs the solver on macOS
and iOS — not to test solver correctness.

## Build configuration

- **Platforms:** `.macOS(.v13)`, `.iOS(.v16)` — matching the planegcs
  and eigen packages.
- **C++ standard:** `.cxx17`.
- **Swift tools:** `swift-tools-version: 5.9`.
- **Interop:** C++/Swift interoperability is the consumer's opt-in. The
  `OndselSolver` placeholder target and `OndselSolverTests` set
  `.interoperabilityMode(.Cxx)`.

## License and provenance

- OndselSolver carries Ondsel's license (`LICENSE` at the repo root);
  per-file copyright headers are preserved verbatim.
- `UPSTREAM.md` records: the upstream OndselSolver repository, the
  `elhernes/OndselSolver` fork, the `swiftpm` branch and the `main`
  commit it derives from, and the snapshot date — the deterministic
  re-sync reference.
- `UPSTREAM.md` also notes the single local addition inside the source
  tree (`module.modulemap`) and that all other additions live outside
  it, so the re-sync is a plain `git merge main`.

## Risks and open items

- **Module-map header selection** — the curated header set must parse
  cleanly as a Clang C++ module. If a chosen header pulls in something
  that does not, the set is trimmed or an intermediate header is added;
  the implementation plan resolves the exact list against a real build.
- **C++/Swift interop maturity** — `ASMTAssembly`'s API uses
  `std::shared_ptr` widely. The smoke test deliberately calls a
  *static, argument-free, void-returning* method, the simplest possible
  interop call. Broader surface is the future facade spec's concern.
- **iOS toolchain** — C++17 `std::filesystem` and threading on the iOS
  v16 SDK should be fine; the iOS build confirms it.
- **`publicHeadersPath: "."`** — pointing the public header path at a
  directory that also contains sources is a supported but less common
  SwiftPM pattern. If it misbehaves, the fallback is a generated
  `include/` of header symlinks; the implementation plan verifies the
  direct approach first.

## Verification (definition of done)

- `swift build` and `swift test` green on macOS.
- An iOS-SDK build green (`xcodebuild` or `swift build` against
  `iphoneos`).
- The existing CMake build still configures and builds (unchanged).

## Out of scope

- The idiomatic Swift API over the solver (separate later spec).
- machina-scribo's consumption wiring (submodule / path dependency).
- Widening the module map beyond the smoke-test surface.
- Any change to the CMake build, the gtest suite, or `OndselSolverMain`.
