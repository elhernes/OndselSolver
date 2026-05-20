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
