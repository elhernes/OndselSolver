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
