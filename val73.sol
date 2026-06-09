// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Stress test repeated calls
CONCEPT: Stability testing
=========================================================

OBJECTIVE

- Understand system behavior under repeated calls
- Learn how state grows over time
- Observe gas accumulation risks
- Think like auditor performing stress tests

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Repeated function calls simulate real-world load.

---------------------------------------------------------

Each call:
modifies state
consumes gas
adds cumulative load

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Stress testing is used to detect:

- gas exhaustion
- storage bloating
- performance degradation
- DOS risks

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

In real systems:

- users call contracts repeatedly
- bots interact heavily
- protocols accumulate state over time

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors test:

- repeated execution stability
- state growth over time
- gas scaling behavior
- worst-case repeated usage
- storage accumulation

=========================================================
STRESS TEST CONTRACT
=========================================================
*/

contract StressTestCallsval {

    /*
        STORAGE STATE
    */
    uint256 public counter;

    uint256 public totalCalls;

    uint256[] public history;

    /*
    =====================================================
    SINGLE STATE UPDATE FUNCTION
    =====================================================
    */

    function singleCall(uint256 value)
        public
    {

        /*
            Increment counters.
        */
        counter++;
        totalCalls++;

        /*
            Store value.
        */
        history.push(value);
    }

    /*
    =====================================================
    STRESS TEST FUNCTION (LOOPED CALLS)
    =====================================================
    */

    function stressTest(uint256 times)
        external
    {

        /*
        =================================================
        WARNING:
        =================================================

        This simulates repeated usage.

        Gas grows linearly with `times`.
        */

        for (
            uint256 i = 0;
            i < times;
            i++
        ) {

            /*
                Repeated internal execution.
            */
            singleCall(i);
        }
    }

    /*
    =====================================================
    DIRECT CALL STRESS (EXTERNAL STYLE SIMULATION)
    =====================================================
    */

    function externalStyleStress(uint256 times)
        external
    {

        for (
            uint256 i = 0;
            i < times;
            i++
        ) {

            /*
                Simulates repeated user interactions.
            */
            this.singleCall(i);
        }
    }

    /*
    =====================================================
    RESET STATE (FOR TESTING ONLY)
    =====================================================
    */

    function reset()
        external
    {

        counter = 0;
        totalCalls = 0;

        delete history;
    }

    /*
    =====================================================
    GET HISTORY SIZE
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
Deploy StressTestCalls

=========================================================
TRACE:
stressTest(5)
=========================================================

STEP 1:
i = 0

---------------------------------------------------------

singleCall(0)

=========================================================
STEP 2
=========================================================

STATE CHANGES:

counter++
totalCalls++
history.push(0)

=========================================================
STEP 3
=========================================================

i = 1 → repeat

=========================================================
STEP 4
=========================================================

i = 2 → repeat

=========================================================
STEP 5
=========================================================

i = 3 → repeat

=========================================================
STEP 6
=========================================================

i = 4 → repeat

=========================================================
FINAL STATE
=========================================================

---------------------------------------------------------
counter
---------------------------------------------------------

= 5

---------------------------------------------------------
totalCalls
---------------------------------------------------------

= 5

---------------------------------------------------------
history
---------------------------------------------------------

[0,1,2,3,4]

=========================================================
IMPORTANT OBSERVATION
=========================================================

Each loop iteration:

---------------------------------------------------------
1 storage increment
1 storage increment
1 array push
---------------------------------------------------------

Gas grows quickly.

=========================================================
TRACE:
externalStyleStress()
=========================================================

STEP 1:
this.singleCall(i)

---------------------------------------------------------

IMPORTANT:

This creates EXTERNAL CALLS to same contract.

=========================================================
STEP 2
=========================================================

Execution context switches:

Contract → Contract (external call)

=========================================================
STEP 3
=========================================================

Each iteration:

- external call overhead
- higher gas usage
- more execution cost

=========================================================
IMPORTANT DIFFERENCE
=========================================================

---------------------------------------------------------
singleCall()
---------------------------------------------------------

cheap internal call

---------------------------------------------------------

---------------------------------------------------------
this.singleCall()
---------------------------------------------------------

expensive external call

=========================================================
STRESS TEST INSIGHT
=========================================================

Repeated calls reveal:

- gas scaling issues
- storage growth
- execution bottlenecks
- stability limits

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

=========================================================
TEST 1
=========================================================

Call:
stressTest(10)

EXPECTED:
fast execution

=========================================================
STEP 2
=========================================================

Call:
stressTest(1000)

EXPECTED:
high gas usage / possible failure

=========================================================
TEST 3
=========================================================

Call:
externalStyleStress(10)

EXPECTED:
higher gas than internal version

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Repeated calls can cause:

---------------------------------------------------------
GAS DOS
---------------------------------------------------------

AND

---------------------------------------------------------
STORAGE BLOAT
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNBOUNDED REPEATED CALLS
---------------------------------------------------------

can exhaust gas

---------------------------------------------------------
2. STORAGE GROWTH
---------------------------------------------------------

array keeps increasing

---------------------------------------------------------
3. EXTERNAL CALL OVERHEAD
---------------------------------------------------------

increases gas significantly

---------------------------------------------------------
4. SYSTEM INSTABILITY
---------------------------------------------------------

becomes unscalable under load

=========================================================
ATTACK THINKING
=========================================================

Attackers may:

- spam function calls
- increase gas usage
- force storage growth
- degrade protocol performance

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors test:

- repeated call behavior
- worst-case gas usage
- storage scaling
- external call risks
- system stability under load

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors simulate:

---------------------------------------------------------
HIGH-FREQUENCY USAGE
---------------------------------------------------------

to find failure points.

=========================================================
BEST PRACTICES
=========================================================

- Avoid unbounded loops
- Minimize storage writes per call
- Prefer batch processing
- Avoid unnecessary external calls
- Design for scalability

=========================================================
MINI CHALLENGE
=========================================================

Modify contract:

1. Limit stressTest to 100 calls
2. Replace storage writes with events
3. Compare internal vs external call gas
4. Add gas measurement logging

BONUS:
Create batch-stress-safe architecture.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Repeated calls simulate real load
- Gas grows with execution frequency
- Storage accumulates over time
- External calls are more expensive
- Stress testing reveals vulnerabilities
- System scalability must be designed
- Auditors simulate heavy usage scenarios
- Unbounded execution is dangerous
- Storage + loops = high risk pattern
- Stability testing is critical for security

=========================================================
*/
/*
Title: Excessive gas consumption from repeated internal and external calls

Severity: Medium

Reason: Repeated function execution inside loops can significantly increase gas consumption, especially when using external self-calls and repeated storage writes

Location: Contract: StressTestCalls
          Affected Functions: stressTest()
                              externalStyleStress()
                              singleCall()

Vulnerability DEscription: The original contract repeatedly executed state-changing functions inside loops:
singleCall(i);
and
this.singleCall(i);

This external self-call version is especially expensive because each iteration creates a full external message call

Additionally the original implementation continuously expanded storage arrays:
history.push(value);
which drastically increases gas usage

Impact: LArge loop execution may cause
- excessive gas consumption
- transaction failures
- scalability problems
- Out-Of-Gas(OOG) conditions
External self-calls additionally increase:
- calldata encoding cost
- message call overhead
- execution complexity

Proof of Concept:
Step 1 — Deploy Contract

Deploy:

StressTestCalls
Step 2 — Execute Internal Stress Test

Call:

stressTest(100)

Observe:

successful execution,
lower gas consumption,
emitted events.
Step 3 — Execute External Stress Test

Call:

externalStyleStress(100)

Observe:

- significantly higher gas usage,
- slower execution,
- additional external call overhead.

Root Cause: The issue exists because
- Loops repeatedly execute state-changing logic
- storage writes are expensive
- external calls add additional EVM overhead
- dynamic array writes scale poorly

*/

// PATCHED CODE

contract StressTestCalls {

    /*
        STORAGE STATE
    */
    uint256 public counter;

    uint256 public totalCalls;

    uint256[] public history;

    // TRACK GAS USAGE
    uint256 public internalGasUsed;

    uint256 public externalGasUsed;

    // EVENTS
    event CallExecuted(address caller, uint256 value, uint256 counter);

    event GasMeasured(string callType, uint256 gasUsed);

    /*
    =====================================================
    SINGLE STATE UPDATE FUNCTION
    =====================================================
    */

    function singleCall(uint256 value)
        public
    {

        /*
            Increment counters.
        */
        counter++;
        totalCalls++;

        emit CallExecuted(msg.sender, value, counter);

    }

    /*
    =====================================================
    STRESS TEST FUNCTION 
    =====================================================
    */

    function stressTest(uint256 times)
        external
    {

       // LIMIT LOOP SIZE
       require(times <= 100,"Max 100 calls");

       uint256 startGas = gasleft();

        for (
            uint256 i = 0;
            i < times;
            i++
        ) {

            /*
                Repeated internal execution.
            */
            singleCall(i);
        }
        
        // SAVE GAS USAGE
        internalGasUsed = startGas - gasleft();

        emit GasMeasured("Internal Calls", internalGasUsed);
    }

    /*
    =====================================================
    DIRECT CALL STRESS (EXTERNAL)
    =====================================================
    */

    function externalStyleStress(uint256 times)
        external
    {
        // LIMIT LOOP SIZE
        require(times <= 100,"Max 100 calls");

        uint256 startGas = gasleft();

        // External self calls

        for (
            uint256 i = 0;
            i < times;
            i++
        ) {

            /*
                Simulates repeated user interactions.
            */
            this.singleCall(i);
        }
            // SAVE GAS USAGE
            externalGasUsed = startGas - gasleft();

            emit GasMeasured("External Calls", externalGasUsed);

    }

    // COMPARE GAS USAGE
    function compareGas() external view returns(uint256 internalGas, uint256 externalGas)
    {
        return(internalGasUsed, externalGasUsed);
    }

    /*
    =====================================================
    RESET STATE
    =====================================================
    */

    function reset()
        external
    {

        counter = 0;

        totalCalls = 0;

        internalGasUsed = 0;

        externalGasUsed = 0;

    }

    /*
    =====================================================
    GET CURRENT SIZE
    =====================================================
    */

    function getState() external view returns(uint256 currentCounter, uint256 currentCalls)
    {
        return(counter, totalCalls);
    }
}
