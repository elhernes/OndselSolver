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
