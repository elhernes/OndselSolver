# MbDCode
Assembly Constraints and Multibody Dynamics code

Install freecad9a.exe from ar-cad.com. Run program and read Explain menu items for documentations. (edited) 

The MbD theory is at
https://github.com/Ondsel-Development/MbDTheory

## SwiftPM package

This repository also builds as a SwiftPM package for macOS and iOS — see
`Package.swift`. The C++ solver is the `OndselSolverCxx` target;
`OndselSolver` is a placeholder Swift facade for a future idiomatic API.
The original CMake build, test suite, and `OndselSolverMain` are
unaffected. Provenance is in `UPSTREAM.md`; design and plan are under
`docs/superpowers/`.
