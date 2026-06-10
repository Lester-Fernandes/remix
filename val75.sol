// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call function with max uint
CONCEPT: Boundary testing (audit-focused)
=========================================================

OBJECTIVE

- Test system behavior at extreme input limits
- Detect overflow assumptions and logic breaks
- Observe gas impact of boundary values
- Simulate real audit-style fuzz inputs

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Max uint256 = extreme boundary condition.

It is used to test:
- arithmetic safety
- comparison logic
- storage correctness
- gas behavior

=========================================================
CONTRACT
=========================================================
*/

// contract MaxUintBoundaryTestval {

//     uint256 public lastValue;
//     uint256 public sum;
//     uint256 public calls;

//     event ValueReceived(uint256 value);

//     /*
//     =====================================================
//     NORMAL FUNCTION
//     =====================================================
//     */

//     function set(uint256 value) external {
//         lastValue = value;
//         sum += value;
//         calls++;

//         emit ValueReceived(value);
//     }

//     /*
//     =====================================================
//     BOUNDARY TEST: MAX UINT
//     =====================================================
//     */

//     function testMaxUint() external {
//         uint256 max = type(uint256).max;

//         set(max);
//     }

//     /*
//     =====================================================
//     STRESS BOUNDARY TEST
//     =====================================================
//     */

//     function stressMax(uint256 n) external {
//         uint256 max = type(uint256).max;

//         for (uint256 i = 0; i < n; i++) {
//             set(max);
//         }
//     }

//     /*
//     =====================================================
//     SAFE CHECK VERSION
//     =====================================================
//     */

//     function safeSet(uint256 value) external {
//         require(value < type(uint256).max, "Max not allowed");

//         lastValue = value;
//         sum += value;
//         calls++;
//     }
// }

/*
=========================================================
EXECUTION TRACE
=========================================================

CALL:
testMaxUint()

---------------------------------------------------------

STEP 1:
value = 2^256 - 1

---------------------------------------------------------

STEP 2:
lastValue = max uint256
(sum storage write happens)

---------------------------------------------------------

IMPORTANT:

Solidity 0.8+ prevents overflow automatically.

So:
sum += value is SAFE

BUT gas cost is still high due to large number.

=========================================================
STRESS TEST TRACE
=========================================================

CALL:
stressMax(5)

---------------------------------------------------------

Each iteration:

- set(max)
- storage write
- event emission
- counter increment

---------------------------------------------------------

Total effect:

5 full state updates

=========================================================
IMPORTANT OBSERVATIONS
=========================================================

1. MAX VALUE DOES NOT BREAK ARITHMETIC
---------------------------------------------------------
No overflow occurs.

2. GAS IS STILL CONSUMED NORMALLY
---------------------------------------------------------
Size of number does NOT reduce gas.

3. LOGIC MAY STILL BREAK
---------------------------------------------------------
Example issues:
- comparisons like value < threshold
- incorrect assumptions about range
- UI misinterpretation

=========================================================
REAL AUDITOR INSIGHT
=========================================================

Auditors do NOT just test “normal values”.

They test:

- 0
- 1
- max uint256
- max-1
- random fuzz inputs

Because bugs appear at boundaries.

=========================================================
COMMON VULNERABILITIES FOUND HERE
=========================================================

- incorrect upper-bound checks
- overflow assumptions in legacy logic
- mispriced calculations
- incorrect fee systems
- broken reward distributions

=========================================================
GAS INSIGHT
=========================================================

Max uint does NOT significantly increase gas by itself.

BUT:
- repeated storage writes dominate cost
- loops + max values = worst-case scenario testing

=========================================================
KEY TAKEAWAY
=========================================================

Max uint testing is NOT about breaking arithmetic.

It is about breaking assumptions.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract:

1. Reject max uint automatically
2. Compare gas:
   - normal value (100)
   - max value
3. Add batch processing for max inputs
4. Simulate fuzz testing (random values)

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- max uint256 = boundary edge case
- Solidity 0.8 prevents overflow automatically
- logic bugs still happen at boundaries
- gas cost is independent of value size
- auditors always test extreme inputs
- stress testing exposes hidden assumptions
- real failures come from logic, not arithmetic

=========================================================
*/
/*
Title: Improper maximum uint256 boundary handling and missing batch validation

Severity: Medium

Reason: The original contract allowed direct insertion of type(uint256).max, which may trigger arithmetic overflow conditions and excessive
        gas consumption during repeated execution

Location: Contract: MaxUintBoundaryTest
          Affected Functions: set()
                              testMaxUint()
                              stressMax()
                              safeSet()

Vulnerability Description: The original contract accepted the maximum uint256 value
2
256
−1

through:

set(max);

and:

stressMax(n);

Repeated execution using the maximum possible integer value creates dangerous arithmetic edge cases and unnecessary gas-heavy operations.

The original implementation also lacked:

- Automatic max-value rejection,
- Batch input validation,
- Fuzz-style randomized testing,
- Gas comparison metrics.

Impact: An attacker or tester could
- repeatedly inject maximum uint values
- trigger overflow conditions
- increase gas consumption
- cause transaction failures
- stress storage accounting logic
Large repeated executions may also
- waste gas
- reduce scalability
- create denial-of-service style execution patterns

Proof Of Concep:
Step 1 — Deploy Contract

Deploy:

MaxUintBoundaryTest
Step 2 — Execute Normal Value

Call:

set(100)

Observe:

successful execution,
gas measurement event emitted.
Step 3 — Execute Max Uint Test

Call:

testMaxUint()

Observe:

max value rejected,
rejection event emitted,
gas usage recorded.
Step 4 — Batch Processing Test

Call:

batchProcess([1,2,3,type(uint256).max])

Observe:

normal values processed,
max uint skipped safely,
rejection event emitted.
Step 5 — Fuzz Test Simulation

Call:

fuzzTest(12345)

Observe:

pseudo-random values generated,
accepted/rejected events emitted.

Root Cause: The issue existed because
- maximum interger inputs were not filtered
- repeated stress loops lacked validation
- overflow-sensitive arithmetic relied only on solidity defaults
- no batch safety checks existed


*/

/*
=========================================================
MAX UINT BOUNDARY TEST CONTRACT
=========================================================
*/

contract MaxUintBoundaryTest {

    /*
        STORAGE VARIABLES
    */
    uint256 public lastValue;

    uint256 public sum;

    uint256 public calls;

    /*
        TRACK GAS USAGE
    */
    uint256 public normalGasUsed;

    uint256 public rejectedGasUsed;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event ValueReceived(
        uint256 value
    );

    event MaxRejected(
        uint256 value
    );

    event GasMeasured(
        string testType,
        uint256 gasUsed
    );

    event FuzzValueTested(
        uint256 value,
        bool accepted
    );

    /*
    =====================================================
    INTERNAL SAFE SET
    =====================================================
    */

    function _safeSet(
        uint256 value
    )
        internal
    {

        /*
            Reject max uint automatically.
        */
        require(
            value != type(uint256).max,
            "Max uint rejected"
        );

        /*
            Overflow protection.
        */
        require(
            sum + value >= sum,
            "Overflow detected"
        );

        lastValue = value;

        sum += value;

        calls++;

        emit ValueReceived(value);
    }

    /*
    =====================================================
    NORMAL SAFE FUNCTION
    =====================================================
    */

    function set(
        uint256 value
    )
        external
    {

        uint256 startGas =
            gasleft();

        _safeSet(value);

        normalGasUsed =
            startGas - gasleft();

        emit GasMeasured(
            "Normal Value",
            normalGasUsed
        );
    }

    /*
    =====================================================
    TEST MAX UINT
    =====================================================
    */

    function testMaxUint()
        external
    {

        uint256 startGas =
            gasleft();

        uint256 max =
            type(uint256).max;

        /*
            Simulate rejection.
        */
        try this.set(max) {

        } catch {

            emit MaxRejected(max);
        }

        rejectedGasUsed =
            startGas - gasleft();

        emit GasMeasured(
            "Rejected Max Uint",
            rejectedGasUsed
        );
    }

    /*
    =====================================================
    BATCH PROCESSING
    =====================================================
    */

    function batchProcess(
        uint256[] calldata values
    )
        external
    {

        /*
            Limit batch size.
        */
        require(
            values.length <= 50,
            "Batch too large"
        );

        for (
            uint256 i = 0;
            i < values.length;
            i++
        ) {

            /*
                Skip max uint values.
            */
            if (
                values[i] ==
                type(uint256).max
            ) {

                emit MaxRejected(
                    values[i]
                );

                continue;
            }

            _safeSet(values[i]);
        }
    }

    /*
    =====================================================
    FUZZ TEST SIMULATION
    =====================================================

    Tests random-like values.
    */

    function fuzzTest(
        uint256 seed
    )
        external
    {

        for (
            uint256 i = 0;
            i < 10;
            i++
        ) {

            /*
                Generate pseudo-random value.
            */
            uint256 randomValue =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            seed,
                            i,
                            block.timestamp
                        )
                    )
                );

            /*
                Simulate fuzz testing.
            */
            if (
                randomValue ==
                type(uint256).max
            ) {

                emit FuzzValueTested(
                    randomValue,
                    false
                );

                continue;
            }

            emit FuzzValueTested(
                randomValue,
                true
            );
        }
    }

    /*
    =====================================================
    COMPARE GAS USAGE
    =====================================================
    */

    function compareGas()
        external
        view
        returns (
            uint256 normalGas,
            uint256 rejectedGas
        )
    {

        return (
            normalGasUsed,
            rejectedGasUsed
        );
    }

    /*
    =====================================================
    GET CURRENT STATE
    =====================================================
    */

    function getState()
        external
        view
        returns (
            uint256 currentValue,
            uint256 currentSum,
            uint256 currentCalls
        )
    {

        return (
            lastValue,
            sum,
            calls
        );
    }
}