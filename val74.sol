// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call function with zero values
CONCEPT: Edge-case behavior
=========================================================

OBJECTIVE

- Understand how contracts behave with zero inputs
- Learn why edge cases matter in auditing
- Observe storage + logic behavior with 0
- Think like auditor checking boundary conditions

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Zero is NOT "nothing" in Solidity.

---------------------------------------------------------

0 is a valid input and can still:

- change state
- trigger logic
- affect storage
- break assumptions

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Many bugs happen because developers assume:

"value > 0 always"

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Zero-value edge cases can cause:

- logic bypass
- division errors
- unnecessary state changes
- incorrect accounting

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors check:

- zero input handling
- boundary conditions
- default values
- uninitialized logic
- false assumptions

=========================================================
ZERO VALUE CONTRACT
=========================================================
*/

// contract ZeroValueEdgeCaseval {

//     /*
//         STORAGE VARIABLES
//     */
//     uint256 public total;
//     uint256 public lastInput;
//     uint256 public counter;

//     /*
//         STORAGE ARRAY
//     */
//     uint256[] public values;

//     /*
//     =====================================================
//     FUNCTION: ADD VALUE (INCLUDING ZERO)
//     =====================================================
//     */

//     function addValue(uint256 value)
//         external
//     {

//         /*
//         =================================================
//         EDGE CASE: ZERO INPUT
//         =================================================
//         */

//         lastInput = value;

//         /*
//             Even if value = 0,
//             state is still updated.
//         */

//         total += value;

//         /*
//             Storage write ALWAYS happens.
//         */
//         values.push(value);

//         /*
//             Counter always increases,
//             even for zero.
//         */
//         counter++;
//     }

//     /*
//     =====================================================
//     SAFE VERSION (ZERO CHECK)
//     =====================================================
//     */

//     function addValueSafe(uint256 value)
//         external
//     {

//         /*
//             Ignore zero values.
//         */
//         require(value > 0, "Zero not allowed");

//         lastInput = value;
//         total += value;
//         values.push(value);
//         counter++;
//     }

//     /*
//     =====================================================
//     ZERO TEST FUNCTION
//     =====================================================
//     */

//     function testZero()
//         external
//     {

//         /*
//             Explicit zero input calls.
//         */
//         addValue(0);
//         addValue(0);
//         addValue(0);
//     }

//     /*
//     =====================================================
//     GET ARRAY LENGTH
//     =====================================================
//     */

//     function getLength()
//         external
//         view
//         returns (uint256)
//     {

//         return values.length;
//     }
// }

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy ZeroValueEdgeCase

=========================================================
TRACE:
addValue(0)
=========================================================

STEP 1:
value = 0

---------------------------------------------------------

lastInput = 0

=========================================================
STEP 2
=========================================================

total += 0

---------------------------------------------------------

NO change in total

=========================================================
STEP 3
=========================================================

values.push(0)

---------------------------------------------------------

IMPORTANT:
ZERO is still stored in blockchain.

=========================================================
STEP 4
=========================================================

counter++

---------------------------------------------------------

counter increases even for zero input.

=========================================================
FINAL STATE AFTER 3 CALLS
=========================================================

CALL:
testZero()

---------------------------------------------------------
counter
---------------------------------------------------------

= 3

---------------------------------------------------------
values
---------------------------------------------------------

[0, 0, 0]

---------------------------------------------------------
total
---------------------------------------------------------

= 0

---------------------------------------------------------
lastInput
---------------------------------------------------------

= 0

=========================================================
IMPORTANT OBSERVATION
=========================================================

Zero STILL causes:

- storage writes
- gas consumption
- state updates

=========================================================
SAFE VERSION BEHAVIOR
=========================================================

CALL:
addValueSafe(0)

=========================================================

STEP 1:
require(value > 0)

---------------------------------------------------------

value = 0 → REVERT

=========================================================
RESULT
=========================================================

Transaction fails BEFORE state change.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Zero values are:

---------------------------------------------------------
VALID INPUTS
---------------------------------------------------------

BUT often:

---------------------------------------------------------
LOGICALLY IGNORED BY SYSTEMS
---------------------------------------------------------

=========================================================
COMMON BUGS FROM ZERO VALUES
=========================================================

---------------------------------------------------------
1. DIVISION BY ZERO
---------------------------------------------------------

if (a / value)

---------------------------------------------------------

---------------------------------------------------------
2. LOGIC BYPASS
---------------------------------------------------------

if (value > 0) { ... }

---------------------------------------------------------

---------------------------------------------------------
3. UNEXPECTED STORAGE WRITE
---------------------------------------------------------

storing useless zero values

---------------------------------------------------------

---------------------------------------------------------
4. INCORRECT ACCOUNTING
---------------------------------------------------------

totals not updated correctly

=========================================================
ATTACK THINKING
=========================================================

Attackers may:

- send zero values repeatedly
- bloat storage arrays
- trigger unnecessary gas costs
- exploit missing zero checks

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors check:

- is zero handled?
- does zero cause state change?
- can zero break logic?
- is validation missing?

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors test:

---------------------------------------------------------
BOUNDARY INPUTS:
0, 1, max uint256
---------------------------------------------------------

=========================================================
BEST PRACTICES
=========================================================

- Validate inputs when needed
- Handle zero explicitly
- Avoid storing useless values
- Document zero behavior
- Test boundary conditions

=========================================================
MINI CHALLENGE
=========================================================

Modify contract:

1. Reject zero and negative-like edge cases
2. Compare gas usage with/without zero validation
3. Add event logging instead of storage push
4. Handle max uint256 input safely

BONUS:
Create full edge-case testing suite.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Zero is a valid Solidity value
- Zero still consumes gas if stored
- State updates happen even for zero
- Edge cases cause real vulnerabilities
- Input validation is critical
- Auditors test boundary conditions
- Storage grows even with useless values
- Safe design avoids unnecessary writes
- Zero can break assumptions
- Robust contracts handle all inputs

=========================================================
*/
/*
Title: Improper handling of zero-value and maximum integer edge cases

Severity: Medium

Reason: The original contract accepted zero-value inputes and continuously performed unnecessary storage writes, increasing gas costs and enabling unintended state updates

Location: Contract: ZeroValueEdgeCase
          Affected Function: addValue()
                             addValueSafe()
                             testZero()

Vulnerability Description: The original implementation accepted zero-value inputs
addValue(0);
Event though the value was zero
- storage variables were updated
- array storage writes occurred
- gas was consumed unnecessarily
- counters increased incorrectly
Additionally, repeated storage pushes caused excessive gas consumption:
values.push(value);
The contract also lacked explicit validation against dangerous edge-case values such as:
type(uint256).max
which may create overflow-related risks in future modifications

Impact: An attacker or careless user could:
- spam zero-value transactions
- infate counters artificially
- waste gas through unnecessary storage writes
- trigger edge-case arithmetic behavior
This can lead to:
- inefficient execution
- state pollution
- accounting inconsistencies
- scalability issues

Proof of Concept
Step 1 — Deploy Contract

Deploy:

ZeroValueEdgeCase
Step 2 — Call Unsafe Function

Execute:

addValue(0)

Observe:

- counter increases,
- storage updates occur,
- gas is consumed,
- event emitted.

Step 3 — Call Safe Function

Execute: addValueSafe(0)

Result:

Zero not allowed

Transaction safely reverts.

Step 4 — Test Maximum Uint256

Execute: testMaxUint()

Observe:

- max uint256 rejected,
- failure event emitted,
- overflow protection triggered.

Root Cause: The issue existed because:
- zero values were not validated
- unnecessary storage writes occurred
- array expansion cnsumed excessive gas
- edge-case inputs lacked filtering

*/

// PATCHED CODE

contract ZeroValueEdgeCase 
{

    /*
        STORAGE VARIABLES
    */
    uint256 public total;
    uint256 public lastInput;
    uint256 public counter;

    // TRACK GAS USAGE
    uint256 public unsafeGasUsed;
    uint256 public safeGasUsed;

    // EVENTS
    event ValueAdded(address indexed user, uint256 value, uint256 newTotal);

    event ZeroRejected(address indexed user);

    event MaxValueRejected(address indexed user, uint256 value);

    event GasMeasured(string operation, uint256 gasUsed);

    /*
    =====================================================
    UNSAFE FUNCTION
    =====================================================
    */

    function addValue(uint256 value)
        external
    {
        uint256 startGas = gasleft();

        /*
        =================================================
        ZERO INPUT ALLOWED
        =================================================
        */

        lastInput = value;

        /*
            Even if value = 0,
            state is still updated.
        */

        total += value;

        /*
            Counter always increases,
            even for zero.
        */
        counter++;

        emit ValueAdded(msg.sender, value, total);

        // MEASURE GAS USAGE
        unsafeGasUsed = startGas - gasleft();

        emit GasMeasured("Unsafe Add",unsafeGasUsed);
    }

    /*
    =====================================================
    SAFE VERSION 
    =====================================================
    */

    function addValueSafe(uint256 value)
        external
    {

        uint256 startGas = gasleft();

        /*
             zero CHECK.
        */
        require(value > 0, "Zero not allowed");

        // MAX UINT256 CHECK
        require(value != type(uint256).max,"Max uint rejected");

        // OVERFLOW CHECK
        require(total + value >= total,"Overflow detected");

        // UPDATE STATE

        lastInput = value;

        total += value;

        counter++;

        // EVENT LOGGING ONLY
        emit ValueAdded(msg.sender, value, total);

        // MEASURE GAS USAGE
        safeGasUsed = startGas - gasleft();

        emit GasMeasured("Safe Add",safeGasUsed);
    }

    /*
    =====================================================
    ZERO TEST FUNCTION
    =====================================================
    */

    function testZero()
        external
    {

      // UNSAFE ACCEPTS ZERO
      this.addValue(0);

      // SAFE VERSION REJECTS
      try this.addValueSafe(0)
      {} catch {
        emit ZeroRejected(msg.sender);
      }
    }

      // TEST MAX UINT INPUT
      function testMaxUint() external 
      {
        uint256 max = type(uint256).max;

        try this.addValueSafe(max)
        {} catch 
        {
            emit MaxValueRejected(msg.sender,max);
        }
      }

      // COMPARE GAS USAGE
      function compareGas() external view returns(uint256 unsafeGas, uint256 safeGas)
      {
        return(unsafeGasUsed, safeGasUsed);
      }

      // GET CURRENT STATE
      function getState() external view returns (uint256 currentTotal,uint256 currentCounter,uint256 currentLastInput)
      {
        return(total,counter,lastInput);
      }
    
}