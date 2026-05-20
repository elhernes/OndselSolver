# OndselSolver SwiftPM Spin-off Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package the vendored OndselSolver C++ multibody-dynamics solver as a SwiftPM package — a C++ library target plus a placeholder Swift facade — buildable for macOS and iOS.

**Architecture:** Additive packaging on the `swiftpm` branch of the `elhernes/OndselSolver` fork. A `Package.swift` at the repo root compiles the existing flat C++ source *in place* (no files move, no source edits). A hand-written `module.modulemap` exposes a curated entry point to Swift via C++ interop. The existing CMake build, gtest suite, and `OndselSolverMain` are left untouched.

**Tech Stack:** SwiftPM (swift-tools 5.9), Swift/C++ interoperability, C++17, Xcode 26 / Swift 6.3 toolchain.

---

## Preconditions

- All commands run from the package root: `deps/OndselSolver/`.
- Git branch is `swiftpm`; working tree is clean (the design spec commit `eb3bb97` is already present).
- The design spec is `docs/superpowers/specs/2026-05-19-ondselsolver-swiftpm-spinoff-design.md` — read it for rationale.

## File Structure

Files created or modified by this plan, and what each is responsible for:

| Path | Action | Responsibility |
|---|---|---|
| `.gitignore` | Modify | Ignore SwiftPM build directories. |
| `Package.swift` | Create | The package manifest — declares targets, products, platforms, C++ standard. |
| `OndselSolver/module.modulemap` | Create | Curated Clang module map exposing `ASMTAssembly.h` as the `OndselSolverCxx` module. The only file added inside upstream's source tree. |
| `Sources/OndselSolver/OndselSolver.swift` | Create | Placeholder Swift facade — compiles, imports the C++ module, no public API yet. |
| `Sources/ondselsolver-smoke/main.cpp` | Create | C++ executable that builds and solves a model in code — proves the C++ library links. |
| `Tests/OndselSolverTests/OndselSolverSmokeTests.swift` | Create | Swift test that calls the solver across the C++ interop boundary. |
| `UPSTREAM.md` | Create | Provenance: upstream repo, fork, branch base commit, re-sync recipe. |
| `README.md` | Modify | Note the SwiftPM package alongside the existing CMake build. |

Untouched: `CMakeLists.txt`, `OndselSolver/*.cpp` and `*.h`, `OndselSolverMain/`, `tests/`, `testapp/`.

---

### Task 1: Package manifest + C++ library target

**Files:**
- Modify: `.gitignore`
- Create: `Package.swift`

- [ ] **Step 1: Ignore SwiftPM build directories**

Append this block to the end of the existing `.gitignore` (it already contains upstream entries — add, do not replace):

```gitignore

# SwiftPM
.build/
.build-ios/
.swiftpm/
*.xcodeproj
.DS_Store
```

- [ ] **Step 2: Create the package manifest with only the C++ library target**

Create `Package.swift`:

```swift
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
    ],
    cxxLanguageStandard: .cxx17
)
```

Notes: `path` points at the existing flat source directory — SwiftPM auto-discovers all `.cpp` there. `publicHeadersPath: "."` makes that directory the public header path, so the `.cpp` sources and cross-including `.h` headers resolve their `#include "Foo.h"` lines, and dependents see the headers. No preprocessor defines are needed (`TEST_DATA_PATH` is used only by `OndselSolverMain` and the gtest suite, never the library).

- [ ] **Step 3: Build the C++ library**

Run: `swift build`
Expected: SwiftPM compiles ~318 `.cpp` files for `OndselSolverCxx` and prints `Build complete!`. This is the longest step in the plan — allow several minutes. Warnings from the C++ sources are acceptable; errors are not.

- [ ] **Step 4: Commit**

```bash
git add .gitignore Package.swift
git commit -m "$(cat <<'EOF'
Add SwiftPM manifest with OndselSolverCxx C++ target

Compiles the existing flat C++ source in place via SwiftPM; no source
files move or change.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: C++ smoke executable

Proves the C++ library links and runs by building and solving a single-pendulum model entirely in code — `ASMTAssembly::runSinglePendulum()` is a `static void` method that needs no test-data files.

**Files:**
- Create: `Sources/ondselsolver-smoke/main.cpp`
- Modify: `Package.swift`

- [ ] **Step 1: Create the C++ smoke source**

Create `Sources/ondselsolver-smoke/main.cpp`:

```cpp
/* C++ smoke test for the OndselSolver SwiftPM package.
 *
 * Builds and solves a single-pendulum model entirely in code (no
 * test-data files), proving the OndselSolverCxx target compiles and
 * links as a SwiftPM library. Not a correctness test.
 */
#include "ASMTAssembly.h"

int main() {
    MbD::ASMTAssembly::runSinglePendulum();
    return 0;
}
```

`#include "ASMTAssembly.h"` resolves because `ondselsolver-smoke` depends on `OndselSolverCxx`, whose `publicHeadersPath` is on the include path of dependents.

- [ ] **Step 2: Add the executable target to the manifest**

Replace `Package.swift` with:

```swift
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
```

- [ ] **Step 3: Build and run the smoke executable**

Run: `swift run ondselsolver-smoke; echo "exit: $?"`
Expected: the build succeeds, the solver prints iteration/log output to stdout, and the last line is `exit: 0`. A non-zero exit (an uncaught C++ exception from the solver) is a failure to surface at the review checkpoint.

- [ ] **Step 4: Commit**

```bash
git add Package.swift Sources/ondselsolver-smoke/main.cpp
git commit -m "$(cat <<'EOF'
Add ondselsolver-smoke C++ executable target

Builds and solves a single-pendulum model in code, verifying the
OndselSolverCxx target links.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Module map + placeholder Swift facade

Adds the hand-written module map and the placeholder Swift facade target. Building the Swift facade exercises `import OndselSolverCxx`, which forces Clang to compile the curated module — this is what verifies the module map.

**Files:**
- Create: `OndselSolver/module.modulemap`
- Create: `Sources/OndselSolver/OndselSolver.swift`
- Modify: `Package.swift`

- [ ] **Step 1: Create the curated module map**

Create `OndselSolver/module.modulemap`:

```modulemap
// ONDSEL-LOCAL: SwiftPM module map — the only file added inside
// upstream's source tree. Exposes a curated entry point for Swift/C++
// interop. Widen the header list as the Swift facade needs more of the
// solver surface; see docs/superpowers/specs/.
module OndselSolverCxx {
    requires cplusplus
    header "ASMTAssembly.h"
    export *
}
```

A single `header` line is deliberate: Clang builds the module from `ASMTAssembly.h` and the headers it `#include`s, with no `umbrella` directive — so the ~316-header directory is not required to compile as one monolithic module.

- [ ] **Step 2: Create the placeholder Swift facade**

Create `Sources/OndselSolver/OndselSolver.swift`:

```swift
// OndselSolver — placeholder for the idiomatic Swift facade over the
// OndselSolver multibody-dynamics solver.
//
// The C++ solver lives in the `OndselSolverCxx` module and is usable
// today via Swift/C++ interop. A Swift-friendly API will be designed
// and built here in a later effort (its own spec).
//
// This file exists so the `OndselSolver` target compiles and the
// `OndselSolverCxx` module is importable from Swift; it intentionally
// has no public surface yet. Vendoring provenance is in `UPSTREAM.md`.

import OndselSolverCxx

enum OndselSolver {}
```

- [ ] **Step 3: Add the facade target and library product to the manifest**

Replace `Package.swift` with:

```swift
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
    ],
    cxxLanguageStandard: .cxx17
)
```

- [ ] **Step 4: Build — verify the module imports from Swift**

Run: `swift build`
Expected: SwiftPM builds `OndselSolverCxx`, then builds the `OndselSolver` Swift target. Building the Swift target compiles the `OndselSolverCxx` Clang module from the module map; a clean `Build complete!` confirms the curated module map is valid and importable. C++-interop warnings are acceptable; a failure to build the Clang module is not.

- [ ] **Step 5: Commit**

```bash
git add Package.swift OndselSolver/module.modulemap Sources/OndselSolver/OndselSolver.swift
git commit -m "$(cat <<'EOF'
Add module map and placeholder Swift facade

Curated module.modulemap exposes ASMTAssembly.h as the OndselSolverCxx
module; the OndselSolver target is a placeholder Swift facade that
imports it.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Swift interop smoke test

Proves the solver is reachable across the Swift/C++ boundary: a Swift test calls the same static method the C++ smoke calls.

**Files:**
- Create: `Tests/OndselSolverTests/OndselSolverSmokeTests.swift`
- Modify: `Package.swift`

- [ ] **Step 1: Create the interop smoke test**

Create `Tests/OndselSolverTests/OndselSolverSmokeTests.swift`:

```swift
import XCTest
import OndselSolverCxx

final class OndselSolverSmokeTests: XCTestCase {
    // Proves the OndselSolver C++ solver is reachable across the
    // Swift/C++ interop boundary: builds and solves a single-pendulum
    // model entirely in code. The test passes by completing the call
    // without a C++ exception or crash; it is not a correctness test.
    func testSinglePendulumSolvesAcrossInterop() {
        // C++ namespace `MbD` imports as a Swift namespace; if this
        // does not resolve, the interop build flattened it — drop the
        // `MbD.` prefix.
        MbD.ASMTAssembly.runSinglePendulum()
    }
}
```

- [ ] **Step 2: Add the test target to the manifest**

Replace `Package.swift` with:

```swift
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
```

- [ ] **Step 3: Run the test suite**

Run: `swift test`
Expected: `OndselSolverTests` builds with C++ interop and `testSinglePendulumSolvesAcrossInterop` passes — output ends with `Test Suite 'All tests' passed` and `Executed 1 test`. Solver log output on stdout during the run is expected.

- [ ] **Step 4: Commit**

```bash
git add Package.swift Tests/OndselSolverTests/OndselSolverSmokeTests.swift
git commit -m "$(cat <<'EOF'
Add Swift/C++ interop smoke test

Calls ASMTAssembly.runSinglePendulum() through the imported
OndselSolverCxx module, verifying the solver is reachable from Swift.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: iOS build verification

Confirms the package builds against the iOS SDK. Verification only — no files change, no commit.

- [ ] **Step 1: List the package schemes**

Run: `xcodebuild -list`
Expected: a scheme list that includes `OndselSolver` and `OndselSolverCxx`. Use the exact `OndselSolver` scheme name from this output in Step 2.

- [ ] **Step 2: Build the package for iOS**

Run:
```bash
xcodebuild build -scheme OndselSolver -destination 'generic/platform=iOS' -derivedDataPath .build-ios
```
Expected: the C++ `OndselSolverCxx` target and the `OndselSolver` Swift facade both compile for iOS; output ends with `** BUILD SUCCEEDED **`. The `.build-ios/` directory is git-ignored (Task 1), so nothing needs committing.

---

### Task 6: Provenance, README, and CMake check

Records vendoring provenance, notes the SwiftPM package in the README, and confirms the untouched CMake build still configures.

**Files:**
- Create: `UPSTREAM.md`
- Modify: `README.md`

- [ ] **Step 1: Create UPSTREAM.md**

Create `UPSTREAM.md`:

```markdown
# Upstream provenance — OndselSolver

OndselSolver is Ondsel, Inc.'s assembly-constraint and multibody-dynamics
solver, packaged here as a stand-alone SwiftPM package for Machina Scribo
alongside its original CMake build.

- **Upstream project:** https://github.com/Ondsel-Development/OndselSolver
- **Working fork:** https://github.com/elhernes/OndselSolver
- **Packaging branch:** `swiftpm`
- **Branched from `main` at:** `81867f23220157b856f9aba221e2c2be25c6f5ed`
- **Vendored:** 2026-05-20
- **License:** see `LICENSE` (Ondsel, Inc.).

## Local divergence from `main`

The SwiftPM package is built **additively** — no upstream `.cpp` or `.h`
file is moved or edited. Divergence from `main` is:

- `Package.swift`, `UPSTREAM.md`, `.gitignore` (build-dir entries) and
  `README.md` (a SwiftPM note) — all at the repository root.
- `Sources/` and `Tests/` — the placeholder Swift facade, the C++ smoke
  executable, and the interop smoke test.
- `docs/superpowers/` — the design spec and implementation plan.
- `OndselSolver/module.modulemap` — the **only** file added
  inside upstream's source tree, marked with an `ONDSEL-LOCAL:` comment.

## Re-syncing with upstream

Because divergence is additive, re-syncing is an ordinary merge:

    git checkout swiftpm
    git merge main

No hand-applied diffs. `OndselSolverCxx` auto-discovers source files, so
added or removed upstream sources need no manifest change. Review
`module.modulemap` only if upstream changes `ASMTAssembly.h` or the
headers it includes.
```

- [ ] **Step 2: Note the SwiftPM package in the README**

Append this section to the end of `README.md`:

```markdown

## SwiftPM package

This repository also builds as a SwiftPM package for macOS and iOS — see
`Package.swift`. The C++ solver is the `OndselSolverCxx` target;
`OndselSolver` is a placeholder Swift facade for a future idiomatic API.
The original CMake build, test suite, and `OndselSolverMain` are
unaffected. Provenance is in `UPSTREAM.md`; design and plan are under
`docs/superpowers/`.
```

- [ ] **Step 3: Confirm the CMake build still configures**

Run: `cmake -S . -B /tmp/ondsel-cmake-check`
Expected: CMake configures without error, ending with `Build files have been written to: /tmp/ondsel-cmake-check`. This confirms the additive SwiftPM files did not disturb the CMake project. (A full CMake build is not needed — no CMake file or C++ source was changed.) The `/tmp` build directory is outside the repo and needs no cleanup or ignoring.

- [ ] **Step 4: Commit**

```bash
git add UPSTREAM.md README.md
git commit -m "$(cat <<'EOF'
Add UPSTREAM.md provenance and README SwiftPM note

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Definition of done

- `swift build` and `swift test` are green on macOS (Tasks 1, 3, 4).
- `swift run ondselsolver-smoke` builds, runs, and exits 0 (Task 2).
- `xcodebuild ... -destination 'generic/platform=iOS'` reports `BUILD SUCCEEDED` (Task 5).
- The existing CMake build still configures (Task 6).
- Six commits on the `swiftpm` branch; no existing C++ source file moved or edited; `module.modulemap` is the only addition inside upstream's source tree.
