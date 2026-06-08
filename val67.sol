// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Increase loop to 1000 iterations
CONCEPT: Gas scaling
=========================================================

OBJECTIVE

- Learn how gas scales with loop size
- Understand expensive execution patterns
- Observe storage-write gas costs
- Think like auditor about scalability risk

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

More loop iterations =
more gas consumption.

---------------------------------------------------------

Gas usage scales approximately:

LINEARLY

with iteration count.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

1000 iterations consume MUCH more gas
than 10 iterations.

---------------------------------------------------------

Especially when loop contains:

- storage writes
- external calls
- memory expansion

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Large loops can make contracts:

- unusable
- DOS vulnerable
- too expensive to execute

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Large loops appear in:

- reward systems
- NFT airdrops
- mass payouts
- governance processing
- staking calculations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- scalability
- gas complexity
- unbounded iteration
- storage-heavy loops
- DOS possibilities

=========================================================
GAS-SCALING CONTRACT
=========================================================
*/

contract GasScalingLoopval {

    /*
        STORE VALUES
    */
    uint256[] public values;

    /*
        TRACK ITERATIONS
    */
    uint256 public totalIterations;

    /*
        STORE FINAL SUM
    */
    uint256 public finalSum;

    /*
    =====================================================
    LOOP 1000 TIMES
    =====================================================
    */

    function loop1000()
        external
    {

        /*
            Temporary local variable.

            Stored in:
            stack/memory

            NOT persistent storage.
        */
        uint256 sum = 0;

        /*
        =================================================
        LARGE LOOP
        =================================================

        Executes:
        1000 iterations
        */

        for (
            uint256 i = 0;
            i < 1000;
            i++
        ) {

            /*
            =============================================
            GAS COST OCCURS HERE
            =============================================

            Every iteration performs:

            - comparison
            - arithmetic
            - increment
            - storage write
            */

            sum += i;

            /*
                VERY EXPENSIVE.

                Storage write every iteration.
            */
            values.push(i);

            /*
                Another storage write.
            */
            totalIterations++;
        }

        /*
            Final storage write.
        */
        finalSum = sum;
    }

    /*
    =====================================================
    CHEAPER LOOP
    =====================================================

    No storage writes inside loop.
    */

    function optimizedLoop1000()
        external
    {

        /*
            Temporary local variable.
        */
        uint256 sum = 0;

        /*
            Loop 1000 times.
        */
        for (
            uint256 i = 0;
            i < 1000;
            i++
        ) {

            /*
                ONLY arithmetic.

                Much cheaper than storage writes.
            */
            sum += i;
        }

        /*
            Single storage write at end.
        */
        finalSum = sum;
    }

    /*
    =====================================================
    CHECK ARRAY LENGTH
    =====================================================
    */

    function getArrayLength()
        external
        view
        returns (uint256)
    {

        return values.length;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy GasScalingLoop

=========================================================
TRACE:
loop1000()
=========================================================

STEP 1:
Function starts.

---------------------------------------------------------

sum = 0

=========================================================
STEP 2
=========================================================

Loop initializes:

i = 0

=========================================================
STEP 3
=========================================================

Condition checked:

i < 1000

---------------------------------------------------------

TRUE

=========================================================
STEP 4
=========================================================

Loop body executes.

---------------------------------------------------------

sum += i

---------------------------------------------------------

values.push(i)

---------------------------------------------------------

totalIterations++

=========================================================
IMPORTANT
=========================================================

Every iteration performs:

---------------------------------------------------------
COMPUTATION
---------------------------------------------------------

AND

---------------------------------------------------------
STORAGE WRITES
---------------------------------------------------------

=========================================================
LOOP CONTINUES
=========================================================

Iterations:

---------------------------------------------------------
0
---------------------------------------------------------

1

---------------------------------------------------------

2

---------------------------------------------------------

...

---------------------------------------------------------

999

=========================================================
FINAL ITERATION
=========================================================

After:

i = 999

---------------------------------------------------------

i++

---------------------------------------------------------

i = 1000

=========================================================
LOOP EXIT
=========================================================

Condition checked:

1000 < 1000

---------------------------------------------------------

FALSE

---------------------------------------------------------

Loop stops.

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
totalIterations
---------------------------------------------------------

1000

---------------------------------------------------------
values.length
---------------------------------------------------------

1000

---------------------------------------------------------
finalSum
---------------------------------------------------------

499500

=========================================================
WHY 499500?
=========================================================

Formula:

n(n-1)/2

---------------------------------------------------------

1000 * 999 / 2

---------------------------------------------------------

499500

=========================================================
IMPORTANT GAS UNDERSTANDING
=========================================================

Gas usage becomes VERY high because:

---------------------------------------------------------
1000 STORAGE WRITES
---------------------------------------------------------

occur.

=========================================================
MOST EXPENSIVE OPERATION
=========================================================

THIS LINE:

values.push(i)

---------------------------------------------------------

Storage writes are among
the MOST expensive EVM operations.

=========================================================
COMPARE FUNCTIONS
=========================================================

---------------------------------------------------------
loop1000()
---------------------------------------------------------

VERY expensive

---------------------------------------------------------

Reason:
storage writes inside loop

=========================================================

---------------------------------------------------------
optimizedLoop1000()
---------------------------------------------------------

MUCH cheaper

---------------------------------------------------------

Reason:
only one storage write

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

=========================================================
TEST 1
=========================================================

Call:
loop1000()

---------------------------------------------------------

Observe:
HIGH gas usage

=========================================================
STEP 2
=========================================================

Check:
getArrayLength()

EXPECTED:
1000

---------------------------------------------------------

Check:
totalIterations()

EXPECTED:
1000

=========================================================
TEST 2
=========================================================

Call:
optimizedLoop1000()

---------------------------------------------------------

Observe:
MUCH lower gas usage

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Gas scales with:

---------------------------------------------------------
WORK PER ITERATION
---------------------------------------------------------

=========================================================
VERY IMPORTANT AUDITOR MINDSET
=========================================================

Loops become dangerous when:

---------------------------------------------------------
ITERATION COUNT GROWS
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNBOUNDED LOOPS
---------------------------------------------------------

User-controlled iteration count.

---------------------------------------------------------
2. STORAGE INSIDE LOOP
---------------------------------------------------------

Massive gas explosion.

---------------------------------------------------------
3. GAS DOS
---------------------------------------------------------

Function becomes impossible to execute.

---------------------------------------------------------
4. EXTERNAL CALLS INSIDE LOOP
---------------------------------------------------------

Extremely dangerous pattern.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers may:

- enlarge arrays
- force massive loops
- increase gas costs
- DOS protocol execution

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors estimate:

---------------------------------------------------------
TIME COMPLEXITY
---------------------------------------------------------

AND

---------------------------------------------------------
GAS COMPLEXITY
---------------------------------------------------------

=========================================================
BIG-O THINKING
=========================================================

This loop complexity:

---------------------------------------------------------
O(n)
---------------------------------------------------------

Gas grows linearly with n.

=========================================================
WHY THIS MATTERS IN ETHEREUM
=========================================================

Ethereum has:

---------------------------------------------------------
BLOCK GAS LIMITS
---------------------------------------------------------

Too much execution =
transaction failure.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Is loop bounded?
- Can attacker increase n?
- Are storage writes inside loop?
- Is function scalable?
- Could execution exceed gas limits?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Loop 10,000 times
2. Measure gas usage
3. Remove storage writes
4. Add external call inside loop

BONUS:
Create batch-processing design.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Gas scales with iteration count
- Storage writes are very expensive
- Large loops may DOS contracts
- O(n) execution impacts scalability
- Ethereum has gas limits
- Unbounded loops are dangerous
- Storage-heavy loops are risky
- Gas optimization matters heavily
- Auditors inspect scalability carefully
- Large loops create security risks

=========================================================
*/
/*
Title: Excessive gas consumption due to large lterative storage writes and external calls

Severity: High

Reason: The contract executes 10,000 loop iterations containing repeated storage writes and external contract calls Create extermely high gas consumption
        and possible out-of-gas failures.

Location: contracts Affected: GasScalingLoop
                              ExternalProcessor
          Vulnerable Function: expensiveLoop10000()
                               optimizedLoop10000()

Vulnerability Description: The expensiveLoop10000() function performs
- 10,000 iterations
- repeated storage writes
- repeated external calls
- repeated event emissions
Inside every iteration: values.push(i);

and:

processor.processValue(i);

are executed.

Both operations are highly gas expensive.

Storage writes permanently modify blockchain state, while external calls transfer execution control outside the contract.

Combined inside a large loop, these operations significantly increase transaction cost.

Impact: The implementation may lead to
- out-of-gas transaction failures
- denial of service
- extremely expensive transactions
- execution limit exhaustion
- scalability issues
Potential consequences include
- failed protocol execution
- wasted gas fees
- unusable functions
- degraded network efficiency

Proof of Concept: 
Step 1 — Deploy Contracts

Deploy:

ExternalProcessor
GasScalingLoop
Step 2 — Execute Expensive Loop

Call:

expensiveLoop10000()
Step 3 — Observe Heavy Execution

Every iteration performs:

Arithmetic
+ Storage Write
+ Storage Counter Update
+ External Call
+ Event Emission

10,000 iterations create massive gas consumption.

Step 4 — Compare Optimized Version

Call: optimizedLoop10000()

This version avoids:

- storage writes inside the loop,
- external calls,
- repeated event emissions.

Gas usage becomes dramatically lower.

Root Cause: the issue exists because: 
- storage writes occur inside large loops
- external calls execute repeatedly
- events emit every iteration

*/

// PATCHED CODE

// EXTERNAL CONTRACT
contract ExternalProcessor
{
    // TRACK CALL COUNT
    uint256 public callCounter;

    // PROCESS FUNCTION
    function processValue(uint256 _value) external 
    {
        callCounter += _value;
    }
}

contract GasScalingLoop {

    /*
        STORE VALUES
    */
    uint256[] public values;

    /*
        TRACK ITERATIONS
    */
    uint256 public totalIterations;

    /*
        STORE FINAL SUM
    */
    uint256 public finalSum;

    // TRACK GAS USED
    uint256 public lastGasUsed;

    // EXTERNAL CONTRACT
    ExternalProcessor public processor;

    // EVENTS 
    event LoopCompleted(uint256 gasUsed, uint256 finalResult);

    event ExternalCallExecuted(uint256 iteration);

    // CONSTRUCTOR
    constructor(address _processor)
    {
        processor = ExternalProcessor(_processor);
    }

    // EXPENSIVE LOOP
    function expensiveLoop10000() external 
    {
        uint256 startGas = gasleft();

        uint256 sum = 0;
    

    /*
    =====================================================
    LOOP 1000 TIMES
    =====================================================
    */

        for (
            uint256 i = 0;
            i < 1000;
            i++
        ) {

           

            sum += i;

            /*
                VERY EXPENSIVE.

                Storage write every iteration.
            */
            values.push(i);

            /*
                Another storage write.
            */
            totalIterations++;

            // EXTERNAL CALL
            processor.processValue(i);

            emit ExternalCallExecuted(i);
        }

        /*
            Final storage write.
        */
        finalSum = sum;

        // Calculate gas usage
        lastGasUsed = startGas - gasleft();

        emit LoopCompleted(lastGasUsed, sum);
    }

    /*
    =====================================================
    OPTIMIZED LOOP
    =====================================================
    */

    function optimizedLoop1000()
        external
    {
        uint256 startGas = gasleft();
 
        uint256 sum = 0;

        /*
          Cheaper loop.
        */
        for (
            uint256 i = 0;
            i < 1000;
            i++
        ) {
            sum += i;
        }

        /*
            Single storage write 
        */
        finalSum = sum;

        // SAVE GAS USAGE
        lastGasUsed = startGas - gasleft();

        emit LoopCompleted(lastGasUsed, sum);
    }

    /*
    =====================================================
     ARRAY LENGTH
    =====================================================
    */

    function getArrayLength()
        external
        view
        returns (uint256)
    {

        return values.length;
    }

    // CONTRACT BALANCE

    function contractBalance() external view returns (uint256)
    {
        return address(this).balance;
    }
}