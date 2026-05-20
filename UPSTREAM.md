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
- `OndselSolver/module.modulemap` — the **only** file added inside
  upstream's source tree, marked with an `ONDSEL-LOCAL:` comment.

## Re-syncing with upstream

Because divergence is additive, re-syncing is an ordinary merge:

    git checkout swiftpm
    git merge main

No hand-applied diffs. `OndselSolverCxx` auto-discovers source files, so
added or removed upstream sources need no manifest change. Review
`module.modulemap` only if upstream changes `ASMTAssembly.h` or the
headers it includes.
