// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Create loop with 10 iterations
CONCEPT: Basic gas usage
=========================================================

OBJECTIVE

- Learn how loops execute in Solidity
- Understand gas consumption in loops
- Learn iteration behavior internally
- Think like auditor regarding loop risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Loops execute repeatedly.

---------------------------------------------------------

Each iteration:
consumes additional gas.

---------------------------------------------------------

More iterations =
more gas usage.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Ethereum execution is NOT free.

---------------------------------------------------------

Every operation costs gas:

- storage writes
- arithmetic
- memory allocation
- looping
- external calls

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Large loops can cause:

- out-of-gas reverts
- denial of service
- unusable contracts

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Loops appear in:

- reward distribution
- staking systems
- NFT minting
- airdrops
- governance voting
- array processing

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- unbounded loops
- gas scaling
- iteration complexity
- DOS risks
- storage writes inside loops

=========================================================
LOOP CONTRACT
=========================================================
*/

contract LoopGasUsageval {

    /*
        STORE LOOP RESULTS
    */
    uint256[] public storedNumbers;

    /*
        TRACK TOTAL ITERATIONS
    */
    uint256 public totalIterations;

    /*
        TRACK FINAL SUM
    */
    uint256 public finalSum;

    /*
    =====================================================
    LOOP 10 TIMES
    =====================================================
    */

    function runLoop()
        external
    {

        /*
            Local variable stored in memory/stack.

            NOT permanent storage.
        */
        uint256 sum = 0;

        /*
        =================================================
        FOR LOOP
        =================================================

        Executes 10 times:

        i = 0
        i = 1
        ...
        i = 9
        */

        for (
            uint256 i = 0;
            i < 10;
            i++
        ) {

            /*
            =============================================
            EACH ITERATION DOES:
            =============================================

            1. Comparison:
               i < 10

            2. Arithmetic:
               sum += i

            3. Storage write:
               push into array

            4. Increment:
               i++
            */

            sum += i;

            /*
                STORAGE WRITE

                Expensive operation.
            */
            storedNumbers.push(i);

            /*
                Update storage counter.
            */
            totalIterations++;
        }

        /*
            Save final result to storage.
        */
        finalSum = sum;
    }

    /*
    =====================================================
    READ ARRAY LENGTH
    =====================================================
    */

    function getArrayLength()
        external
        view
        returns (uint256)
    {

        return storedNumbers.length;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy LoopGasUsage

=========================================================
TRACE:
runLoop()
=========================================================

STEP 1:
Function execution starts.

---------------------------------------------------------

sum = 0

---------------------------------------------------------

Stored:
temporary stack/memory variable

=========================================================
STEP 2
=========================================================

Loop initializes:

uint256 i = 0

=========================================================
STEP 3
=========================================================

Condition checked:

i < 10

---------------------------------------------------------

0 < 10

---------------------------------------------------------

TRUE

=========================================================
STEP 4
=========================================================

Loop body executes.

---------------------------------------------------------

sum += i

---------------------------------------------------------

sum = 0 + 0

---------------------------------------------------------

sum = 0

=========================================================
STEP 5
=========================================================

Storage write:

storedNumbers.push(0)

---------------------------------------------------------

VERY IMPORTANT:
Storage writes cost high gas.

=========================================================
STEP 6
=========================================================

Storage update:

totalIterations++

---------------------------------------------------------

totalIterations = 1

=========================================================
STEP 7
=========================================================

Increment:

i++

---------------------------------------------------------

i = 1

=========================================================
STEP 8
=========================================================

Loop repeats again.

---------------------------------------------------------

1 < 10

---------------------------------------------------------

TRUE

=========================================================
LOOP CONTINUES
=========================================================

Iterations:

---------------------------------------------------------
Iteration 1
---------------------------------------------------------

i = 0

---------------------------------------------------------
Iteration 2
---------------------------------------------------------

i = 1

---------------------------------------------------------
Iteration 3
---------------------------------------------------------

i = 2

---------------------------------------------------------
...
---------------------------------------------------------

---------------------------------------------------------
Iteration 10
---------------------------------------------------------

i = 9

=========================================================
FINAL ITERATION
=========================================================

After i = 9:

---------------------------------------------------------

i++

---------------------------------------------------------

i = 10

=========================================================
LOOP EXIT
=========================================================

Condition checked:

10 < 10

---------------------------------------------------------

FALSE

---------------------------------------------------------

Loop stops.

=========================================================
FINAL STORAGE UPDATE
=========================================================

finalSum = 45

---------------------------------------------------------

Why 45?

---------------------------------------------------------

0+1+2+3+4+5+6+7+8+9

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
storedNumbers
---------------------------------------------------------

[0,1,2,3,4,5,6,7,8,9]

---------------------------------------------------------
totalIterations
---------------------------------------------------------

10

---------------------------------------------------------
finalSum
---------------------------------------------------------

45

=========================================================
IMPORTANT GAS UNDERSTANDING
=========================================================

Each iteration consumes gas.

---------------------------------------------------------

Gas increases because of:

- comparison
- arithmetic
- increment
- storage writes

=========================================================
MOST EXPENSIVE PART
=========================================================

THIS LINE:

storedNumbers.push(i)

---------------------------------------------------------

Storage writes are expensive.

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

Loops scale gas usage linearly.

---------------------------------------------------------

10 iterations =
manageable

---------------------------------------------------------

10,000 iterations =
dangerous

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
runLoop()

---------------------------------------------------------

EXPECTED:
successful execution

=========================================================
STEP 3
=========================================================

Check:
finalSum()

EXPECTED:
45

---------------------------------------------------------

Check:
totalIterations()

EXPECTED:
10

---------------------------------------------------------

Check:
getArrayLength()

EXPECTED:
10

=========================================================
STEP 4
=========================================================

Inspect transaction gas used
inside Remix.

---------------------------------------------------------

Observe:
gas increases because of loop.

=========================================================
IMPORTANT AUDITOR UNDERSTANDING
=========================================================

Loops are dangerous when:

---------------------------------------------------------
USER-CONTROLLED
---------------------------------------------------------

or

---------------------------------------------------------
UNBOUNDED
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNBOUNDED LOOPS
---------------------------------------------------------

Infinite scalability risk.

---------------------------------------------------------
2. GAS DOS
---------------------------------------------------------

Too many iterations cause revert.

---------------------------------------------------------
3. STORAGE WRITES INSIDE LOOP
---------------------------------------------------------

Massive gas consumption.

---------------------------------------------------------
4. EXTERNAL CALLS INSIDE LOOP
---------------------------------------------------------

Very dangerous execution pattern.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers may:

- enlarge arrays
- force expensive loops
- trigger gas exhaustion
- DOS protocol execution

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Is loop bounded?
- Can attacker increase iterations?
- Are storage writes inside loop?
- Can gas exceed block limit?
- Is external call inside loop?

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors estimate:

---------------------------------------------------------
TIME COMPLEXITY
---------------------------------------------------------

and

---------------------------------------------------------
GAS SCALING
---------------------------------------------------------

=========================================================
WHY LOOPS ARE RISKY
=========================================================

Ethereum has:
block gas limits.

---------------------------------------------------------

Too much computation =
transaction failure.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Loop 100 times
2. Compare gas usage
3. Remove storage writes
4. Add external call inside loop

BONUS:
Create gas-optimized loop version.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Loops consume gas every iteration
- Storage writes are expensive
- Gas scales with iteration count
- for-loops repeatedly execute logic
- Large loops risk DOS
- Unbounded loops are dangerous
- Ethereum has gas limits
- Auditors inspect loop scalability
- Gas optimization matters heavily
- Loop complexity affects protocol security

=========================================================
*/
/*
Title: Gas-Heave Loop Execution and Expensive storage operations

Severity: Medium

Reason: The contract performs repeated storage writes and external contract calls inside loop, significantly increasing gas comumption and potentially
        causing out-of-gas failures

Location: Contracts Affected: LoopGasUsage
                              ExternalCallee
          Vulnerable Function: expensiveLoop()
                               optimizedLoop()

Vulnerability Description: The expensiveLoop() function performs:
- 100 loop iterations
- repeated storage writes
- external contract calls
- event emissions
Inside each iteration: storedNumbers.push(i);

and:

callee.externalWork(i);

are executed.

Both operations are gas expensive.

Storage writes permanently modify blockchain state and cost significant gas.

External calls additionally:

- transfer execution control,
- increase execution complexity,
- add call overhead.

This creates a highly gas-intensive execution flow.

Impact: Excessive gas consumption may lead to:
- out-of-gas transaction failures
- denial of service
- execution limits
- expensive user interactions
Potential consequences include:
- failed transactions
- wasted gas fee
- scalability problems
- degraded protocol efficiency

Proof of Concept:

Step 1 — Deploy Contracts

Deploy:

ExternalCallee
LoopGasUsage

Step 2 — Execute expensiveLoop()

Call:

expensiveLoop()
Step 3 — Observe Gas Consumption

Each iteration performs:

Arithmetic
+ Storage Write
+ Storage Counter Update
+ External Call
+ Event Emission

100 iterations dramatically increase gas usage.

Step 4 — Compare Optimized Version

Call:

optimizedLoop()

This version avoids:

- repeated storage writes,
- repeated external calls.

Gas usage becomes significantly lower.

Root Cause: The issue exists because
- storage writes occir inside loop
- external calls occur repeatedly
- event emissions happen every iteration

*/

// PATCHED CODE 

// EXTERNAL CALLEE CONTRACT
contract ExternalCallee
{
    // TRACK EXTERNAL CALLS
    uint256 public callCounter;

    // EXTERNAL FUNCTION
    function externalWork(uint256 _value) external 
    {
        // Simulate external execution
        callCounter += _value;
    }
}

/*
LOOP CONTRACT
=========================================================
*/

contract LoopGasUsage {

    /*
        STORE LOOP RESULTS
    */
    uint256[] public storedNumbers;

    /*
        TRACK TOTAL ITERATIONS
    */
    uint256 public totalIterations;

    /*
        TRACK FINAL SUM
    */
    uint256 public finalSum;

    // STORE LAST GAS USED
    uint256 public lastGasUsed;

    // EXTERNAL CONTRACT
    ExternalCallee public callee;

    // EVENTS
    event LoopCompleted(uint256 gasUsed, uint256 sum);

    event ExternalCallEXecuted(uint256 iteration);

    
// CONSTRUCTOR
    constructor(address _callee)
    {
        callee = ExternalCallee(_callee);
    }

    // EXPENSIVE LOOP
    function expensiveLoop() external 
    {
        uint256 startGas = gasleft(); 
        uint256 sum = 0;
    

    /*
    =====================================================
    LOOP 10 TIMES
    =====================================================
    */
        for (
            uint256 i = 0;
            i < 100;
            i++
        ) {

            sum += i;

        
            storedNumbers.push(i);

          
            totalIterations++;

            callee.externalWork(i);

            emit ExternalCallEXecuted(i);
        }

        /*
            Save final sum
        */
        finalSum = sum;

        // Calculate gas usage
        lastGasUsed = startGas - gasleft();

        emit LoopCompleted(lastGasUsed, sum);
    }

    // OPTIMIZED LOOP
    function optimizedLoop() external 
    {
        uint256 startGas = gasleft();

        uint256 sum = 0;

        // MEMORY ONLY LOOP
        for(uint256 i = 0; i < 100; i++)
        {
            sum += i;
        }

        // Single storage write
        finalSum = sum;

        // Save gas usage
        lastGasUsed = startGas - gasleft();

        emit LoopCompleted(lastGasUsed, sum);
    }

    /*
    =====================================================
    READ ARRAY LENGTH
    =====================================================
    */

    function getArrayLength()
        external
        view
        returns (uint256)
    {

        return storedNumbers.length;
    }

    // CONTRACT BALANCE
    function contractBalance() external view returns(uint256)
    {
        return address(this).balance;
    }
}