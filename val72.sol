// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use repeated storage writes
CONCEPT: Expensive operations
=========================================================

OBJECTIVE

- Understand cost of repeated storage updates
- See how gas scales with state writes
- Learn why storage-heavy loops are dangerous
- Think like auditor about optimization risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Every storage write costs gas.

---------------------------------------------------------

Repeated storage writes inside loops:
become VERY expensive quickly.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Storage writes:

- modify blockchain state
- are permanently stored
- require high gas

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Repeated writes can cause:

- high transaction cost
- out-of-gas failure
- denial of service
- unscalable contracts

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Repeated writes appear in:

- reward updates
- counters
- staking systems
- voting systems
- accounting updates

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- write frequency
- loop-based storage updates
- redundant state changes
- gas inefficiencies
- optimization opportunities

=========================================================
EXPENSIVE STORAGE CONTRACT
=========================================================
*/

contract RepeatedStorageWritesval {

    /*
        STORAGE VARIABLES
    */
    uint256 public counter;
    uint256 public lastValue;

    /*
        STORAGE ARRAY
    */
    uint256[] public history;

    /*
    =====================================================
    HEAVY STORAGE WRITE LOOP
    =====================================================
    */

    function heavyWrites(uint256 n)
        external
    {

        /*
            Loop controlled by user input.
        */
        for (
            uint256 i = 0;
            i < n;
            i++
        ) {

            /*
            =============================================
            EXPENSIVE OPERATION 1
            =============================================

            Increment storage variable.
            */
            counter++;

            /*
            =============================================
            EXPENSIVE OPERATION 2
            =============================================
            */
            lastValue = i;

            /*
            =============================================
            EXPENSIVE OPERATION 3
            =============================================
            */
            history.push(i);
        }
    }

    /*
    =====================================================
    OPTIMIZED VERSION
    =====================================================
    */

    function optimizedWrites(uint256 n)
        external
    {

        /*
            Local variable (cheap).
        */
        uint256 tempCounter = counter;

        uint256 tempValue = 0;

        uint256[] memory tempArray =
            new uint256[](n);

        for (
            uint256 i = 0;
            i < n;
            i++
        ) {

            /*
                ONLY memory operations inside loop.
            */
            tempCounter++;

            tempValue = i;

            tempArray[i] = i;
        }

        /*
            SINGLE storage write operations.
        */
        counter = tempCounter;
        lastValue = tempValue;

        /*
            Write array once (optional pattern).
        */
        for (
            uint256 i = 0;
            i < n;
            i++
        ) {

            history.push(tempArray[i]);
        }
    }

    /*
    =====================================================
    GET HISTORY LENGTH
    =====================================================
    */

    function getHistoryLength()
        external
        view
        returns (uint256)
    {

        return history.length;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy RepeatedStorageWrites

=========================================================
TRACE:
heavyWrites(n)
=========================================================

INPUT:
n = 100

=========================================================
STEP 2
=========================================================

Loop starts:

i = 0

=========================================================
STEP 3
=========================================================

STORAGE WRITE #1:

counter++

=========================================================
STEP 4
=========================================================

STORAGE WRITE #2:

lastValue = 0

=========================================================
STEP 5
=========================================================

STORAGE WRITE #3:

history.push(0)

=========================================================
STEP 6
=========================================================

Repeat for i = 1 ... 99

=========================================================
IMPORTANT OBSERVATION
=========================================================

Each iteration performs:

---------------------------------------------------------
3 STORAGE WRITES
---------------------------------------------------------

Total:

100 × 3 = 300 writes

=========================================================
GAS IMPACT
=========================================================

This becomes VERY expensive.

---------------------------------------------------------

May lead to:

- high transaction cost
- gas limit issues
- execution failure

=========================================================
OPTIMIZED FLOW
=========================================================

CALL:
optimizedWrites(100)

=========================================================

STEP 1:
All computation happens in memory.

=========================================================
STEP 2
=========================================================

Only 2 final storage writes:

---------------------------------------------------------
counter = tempCounter
lastValue = tempValue

=========================================================
STEP 3
=========================================================

history updated in batch style.

=========================================================
IMPORTANT RESULT
=========================================================

Same outcome,
MUCH lower gas cost.

=========================================================
WHY THIS MATTERS
=========================================================

Storage writes are the MOST expensive
EVM operation.

---------------------------------------------------------

Reducing them improves scalability.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

=========================================================
TEST 1
=========================================================

Call:
heavyWrites(100)

---------------------------------------------------------

Observe:
HIGH gas usage

=========================================================
TEST 2
=========================================================

Call:
optimizedWrites(100)

---------------------------------------------------------

Observe:
lower gas usage

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Repeated storage writes cause:

---------------------------------------------------------
GAS EXPLOSION
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. LOOPED STORAGE WRITES
---------------------------------------------------------

very expensive pattern

---------------------------------------------------------
2. UNNECESSARY STATE UPDATES
---------------------------------------------------------

wasted gas

---------------------------------------------------------
3. USER CONTROLLED n
---------------------------------------------------------

can trigger DOS

---------------------------------------------------------
4. SCALABILITY FAILURE
---------------------------------------------------------

contract becomes unusable

=========================================================
ATTACK THINKING
=========================================================

Attackers may:

- increase n
- force heavy writes
- trigger gas exhaustion
- block execution

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors check:

- number of storage writes per call
- loop complexity
- worst-case gas cost
- user-controlled input size

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors calculate:

---------------------------------------------------------
writes_per_iteration × max_iterations
---------------------------------------------------------

to estimate risk.

=========================================================
BEST PRACTICES
=========================================================

- Minimize storage writes
- Batch updates
- Use memory for intermediate data
- Avoid per-iteration state changes
- Validate input size

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Limit n to 50
2. Compare gas usage
3. Add event logging instead of storage
4. Remove history array writes

BONUS:
Create event-based accounting system.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Storage writes are expensive
- Repeated writes increase gas linearly
- Loops with state changes are dangerous
- Memory is cheaper than storage
- Batch updates improve efficiency
- User-controlled loops can cause DOS
- Gas optimization is critical
- Auditors analyze write frequency
- Scalability depends on storage design
- Efficient state management is essential

=========================================================
*/
/*
Title: Excessive storage writes causing high gas consumption

Severity: Medium

Reason: Repeated storage writes inside loops significantly increases gas comsumption and reduce contract scalability

Location: Contact: RepeatedStorageWrites
          Affected Function: heavyWrites()
                             optmizedWrites()

Vulnerability Description: The original implementation performed multiple storage writes during every loop iteration:
counter++;
lastValue = i;
history.push(i);
Storage operations are among the most expensive EVM operations

Repeated writes inside large loops can
- drastically increase gas costs
- create scalability problems
- trigger out of gas failures

Impact: If the loop size becomes large:
- transactions become expensive
- execution may revert
- users may be unable to execute functions
- protocol efficiency decreases

Proof of Concept:
Step 1 — Deploy Contract

Deploy: RepeatedStorageWrites

Step 2 — Execute Heavy Writes

Call: heavyWrites(50)

Observe:

multiple storage updates,
higher gas usage,
emitted events.
Step 3 — Execute Optimized Writes

Call: optimizedWrites(50)

Observe:

reduced storage writes,
lower gas usage,
improved efficiency.

Root Cause: The issue exists because 
- storage writes occur during each iteration
- storage expansion is expensive
- loops amplify gas costs linearly

*/

// PATCHED CODE

contract RepeatedStorageWrites {

    /*
        STORAGE VARIABLES
    */
    uint256 public counter;
    uint256 public lastValue;

    /*
        STORAGE ARRAY
    */
    uint256[] public history;

    // TRACK GAS USAGE
    uint256 public heavyGasUsed;
    uint256 public optimizedGasUsed;

    // EVENTS
    event HeavyWriteEvent(uint256 iteration, uint256 value);

    event optimizedWriteEvent(uint256 iteration, uint256 value);

    event GasMeasured(string functionType, uint256 gasUsed);

    /*
    =====================================================
    HEAVY STORAGE WRITE LOOP
    =====================================================
    */

    function heavyWrites(uint256 n)
        external
    {
        require(n <= 50, "Max 50 iterations");

        uint startGas = gasleft();

        for (
            uint256 i = 0;
            i < n;
            i++
        ) {

            /*
            =============================================
            EXPENSIVE OPERATION 1
            =============================================

            Increment storage variable.
            */
            counter++;

            /*
            =============================================
            EXPENSIVE OPERATION 2
            =============================================
            */
            lastValue = i;

            emit HeavyWriteEvent(i, counter);
        }
        // SAVE GAS USAGE
        heavyGasUsed = startGas - gasleft();

        emit GasMeasured("Heavy Writes", heavyGasUsed);
    }

    /*
    =====================================================
    OPTIMIZED VERSION
    =====================================================
    */

    function optimizedWrites(uint256 n)
        external
    {
        require(n <= 50,"Max 50 iterations");

        uint256 startGas = gasleft();

        /*
            Local variable (cheap).
        */
        uint256 tempCounter = counter;

        uint256 tempValue = 0;

        for (
            uint256 i = 0;
            i < n;
            i++
        ) {

            /*
                ONLY memory operations inside loop.
            */
            tempCounter++;

            tempValue = i;

            emit optimizedWriteEvent(i, tempCounter);
        }

        /*
            SINGLE storage write operations.
        */
        counter = tempCounter;
        lastValue = tempValue;

        // SAVE GAS USAGE
        optimizedGasUsed = startGas - gasleft();

        emit GasMeasured("Optimized Writes", optimizedGasUsed);
    }

    // COMPARE GAS USAGE
    function compareGasUsage() external view returns(uint256 heavyGas, uint256 optimizedGas)
    {
        return(heavyGasUsed, optimizedGasUsed);
    }

    // GET CURRENT STATE
    function getState() external view returns(uint256 currentCounter, uint256 currentValue)
    {
        return(counter, lastValue);
    }
}