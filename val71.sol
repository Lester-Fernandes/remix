// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Trigger out-of-gas scenario
CONCEPT: Execution failure
=========================================================

OBJECTIVE

- Understand what "out of gas" means
- See how loops can cause execution failure
- Learn why gas limits exist
- Think like an auditor about DOS risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Every Ethereum transaction has a GAS LIMIT.

---------------------------------------------------------

If execution consumes more gas than available:

→ transaction REVERTS automatically

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Out-of-gas (OOG) is NOT a normal revert.

It is a HARD EXECUTION FAILURE.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Out-of-gas scenarios cause:

- failed transactions
- stuck operations
- denial of service (DOS)
- unusable functions

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

OOG risks appear in:

- loops over arrays
- batch processing
- staking reward distribution
- token airdrops
- NFT mint batches

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- loop bounds
- gas estimation
- worst-case inputs
- storage-heavy iterations
- external call loops

=========================================================
OUT-OF-GAS CONTRACT
=========================================================
*/

contract OutOfGasDemoval {

    /*
        STORAGE ARRAY
    */
    uint256[] public data;

    /*
    =====================================================
    INFINITE LOOP RISK FUNCTION
    =====================================================
    */

    function dangerousLoop()
        external
    {

        /*
        =================================================
        WARNING PATTERN
        =================================================

        This function loops over ALL stored data.

        If array becomes large:
        GAS LIMIT WILL BE EXCEEDED.
        */

        uint256 sum = 0;

        for (
            uint256 i = 0;
            i < data.length;
            i++
        ) {

            /*
                Storage read (expensive).
            */
            sum += data[i];

            /*
                Additional storage write (very expensive).
            */
            data[i] = sum;
        }
    }

    /*
    =====================================================
    ADD MANY VALUES
    =====================================================
    */

    function addMany(uint256 n)
        external
    {

        for (
            uint256 i = 0;
            i < n;
            i++
        ) {

            data.push(i);
        }
    }

    /*
    =====================================================
    SAFE BATCH VERSION
    =====================================================
    */

    function safeProcess(uint256 limit) view 
        external
    {

        /*
            Limit loop size to avoid OOG.
        */
        require(limit <= 100, "Too large batch");

        uint256 sum = 0;

        for (
            uint256 i = 0;
            i < limit;
            i++
        ) {

            sum += data[i];
        }
    }

    /*
    =====================================================
    GET LENGTH
    =====================================================
    */

    function getLength()
        external
        view
        returns (uint256)
    {

        return data.length;
    }
}

/*
=========================================================
EXECUTION FLOW (OUT-OF-GAS SCENARIO)
=========================================================

STEP 1:
Deploy OutOfGasDemo

=========================================================
STEP 2:
CALL:
addMany(10000)

=========================================================

Array grows to:
10000 elements

=========================================================
STEP 3:
CALL:
dangerousLoop()

=========================================================

STEP-BY-STEP EXECUTION
=========================================================

STEP 1:
sum = 0

---------------------------------------------------------

STEP 2:
i = 0 → read data[0]

---------------------------------------------------------

STEP 3:
data[0] updated

---------------------------------------------------------

STEP 4:
i = 1 → read data[1]

---------------------------------------------------------

(repeats thousands of times)

=========================================================
GAS CONSUMPTION GROWS
=========================================================

Each iteration costs:

- storage read
- storage write
- loop increment
- memory operations

=========================================================
CRITICAL MOMENT
=========================================================

At some iteration:

gas remaining < required gas

=========================================================
RESULT
=========================================================

TRANSACTION FAILS:

OUT OF GAS (OOG)

=========================================================
IMPORTANT BEHAVIOR
=========================================================

When OOG happens:

- entire transaction REVERTS
- ALL state changes rollback
- no partial execution persists

=========================================================
FINAL RESULT
=========================================================

data remains unchanged after failure

=========================================================
WHY THIS HAPPENS
=========================================================

Ethereum enforces gas limit per block:

→ prevents infinite computation
→ protects network from abuse

=========================================================
SAFE VERSION TRACE
=========================================================

CALL:
safeProcess(100)

=========================================================

STEP 1:
limit checked

---------------------------------------------------------

limit <= 100

=========================================================
STEP 2:
loop executes safely

---------------------------------------------------------

only 100 iterations

=========================================================
STEP 3:
execution completes successfully

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Out-of-gas is a:

---------------------------------------------------------
HARD EXECUTION FAILURE
---------------------------------------------------------

not a normal revert.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNBOUNDED LOOPS
---------------------------------------------------------

can exceed gas limit

---------------------------------------------------------
2. STORAGE INSIDE LOOP
---------------------------------------------------------

accelerates gas exhaustion

---------------------------------------------------------
3. USER-CONTROLLED INPUT SIZE
---------------------------------------------------------

attackers can force OOG

---------------------------------------------------------
4. DOS VIA GAS LIMIT
---------------------------------------------------------

contract becomes unusable

=========================================================
ATTACK THINKING
=========================================================

Attackers may:

- increase array size
- trigger expensive loops
- force OOG condition
- block contract execution

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Can loop exceed gas limit?
- Is input size bounded?
- Are storage writes inside loops?
- What is worst-case gas cost?

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors calculate:

---------------------------------------------------------
GAS PER ITERATION × MAX SIZE
---------------------------------------------------------

to ensure safety.

=========================================================
BEST PRACTICES
=========================================================

- Always bound loops
- Avoid storage writes in loops
- Use batching techniques
- Validate input size
- Design O(1) or O(log n) logic

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Allow dynamic batch processing
2. Prevent OOG using chunking
3. Compare safe vs unsafe loops
4. Add gas estimator function

BONUS:
Create pagination-based processing system.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Out-of-gas causes transaction failure
- Gas limits protect Ethereum network
- Large loops are dangerous
- Storage operations are expensive
- OOG reverts entire transaction
- Input size must be controlled
- Gas estimation is critical
- Auditors analyze worst-case execution
- Batching avoids gas exhaustion
- Safe design prevents DOS attacks

=========================================================
*/
/*
Title: Unbounded loop causing out of gas (OOG) Risk

Severity: High

Reason: The contract contains unbounded iterative execution over dynamic storage array, which may exceed the Ethereum block gas limit
        and cause transaction failure

Location: Contract: OutOfGasDemo
          Affected Function: dangerousLoop()
                             addmany()

Vulnerability Description: The original implementation loops through the entire dynamic storage array:
for(uint256 i = 0 l i < data.length; i++)

As the array grows larger, execution cost scales linearly
Additionally the loop perform:
- Storage reads
- Storage writes
- arithmetic operations
This creates severe gas scalability problems

Impact: if the array becomes very large
- transactions may revert
- functions become permanently unusable
- protocol logic may become inaccessible
- denial of service conditions may occur
Attackers may intertionall increase array size using: addMany()
to make processing impossinle

Proof of Concept:
Step 1 — Deploy Contract

Deploy: OutOfGasDemo

Step 2 — Add Large Dataset

Call: addMany(1000)

or repeatedly call: addMany(1000)

Step 3 — Execute Dangerous Loop

Call: dangerousLoop()

Gas usage grows rapidly as array size increases.

Large datasets may eventually trigger:

Out of Gas

Root Cause: The vulnerability exists because:
- loops depend on dynamic storage length
- no iteration limi exists
- storage writes occur inside loops
- gas usage scales linearly with array growth
*/

// PATCHED CODE

contract OutOfGasDemo {

    /*
        STORAGE ARRAY
    */
    uint256[] public data;

    // TRACK LAST SUM
    uint256 public lastSum;

    // TRACK LAST GAS USED
    uint256 public lastGasUsed;

    // EVENTS
    event UnsafeLoopExecutes(uint256 gasUsed, uint256 length);

    event SafeChunkProcessed(uint256 start, uint256 end, uint256 gasUsed);

    /*
    =====================================================
    INFINITE LOOP RISK FUNCTION
    =====================================================
    */

    function dangerousLoop()
        external
    {

        /*
        =================================================
        WARNING PATTERN
        =================================================

        This function loops over ALL stored data.

        If array becomes large:
        GAS LIMIT WILL BE EXCEEDED.
        */

        uint256 startGas = gasleft();

         uint256 sum = 0;

        for (
            uint256 i = 0;
            i < data.length;
            i++
        ) {

            /*
                Storage read (expensive).
            */
            sum += data[i];

            /*
                Additional storage write (very expensive).
            */
            data[i] = sum;
        }
        lastSum = sum;

        lastGasUsed = startGas - gasleft();

        emit UnsafeLoopExecutes(lastGasUsed, data.length);
    }

    // SAFE CHUNK PROCESSING

    function safeChunkProcess(uint256 start, uint256 batchSize) external 
    {
        require(batchSize <= 100, "Batch too large");

        require(start < data.length, "Invalid start");

        uint256 startGas = gasleft();

        uint256 end = start + batchSize;

        // PREVENT OVERFLOW
        if(end >  data.length)
        {
            end = data.length;
        }

        uint256 sum = lastSum;

        // SAFE LIMITED LOOP
        for(uint256 i = start; i < end; i++)
        {
            sum += data[i];

            // Optional write

            data[i] = sum;
        }
        lastSum = sum;

        lastGasUsed = startGas - gasleft();

        emit SafeChunkProcessed(start, end, lastGasUsed);

    }

    /*
    =====================================================
    ADD MANY VALUES
    =====================================================
    */

    function addMany(uint256 n)
        external
    {

        require(n <= 1000, "Too many values");

        for (
            uint256 i = 0;
            i < n;
            i++
        ) {

            data.push(i);
        }
    }

    /*
    =====================================================
    SAFE READ ONLY
    =====================================================
    */

    function safeReadOnlyProcess(uint256 start, uint256 batchSize) view 
        external
        returns (uint256 sum)
    {

        /*
            Limit loop size to avoid OOG.
        */
        require(batchSize <= 100, "Batch too large");

        uint256 end = start + batchSize;

        if(end > data.length)
        {
            end = data.length;
        }

        for (
            uint256 i = start;
            i < end;
            i++
        ) {

            sum += data[i];
        }
    }

    // GAS ESTIMATOR

    function estimateGasCost(uint256 iterations) external pure returns (string memory)
    {
        if(iterations <= 100)
        {
            if (iterations <= 100)
            {
                return "low gas usage";
            }
            if (iterations <= 1000)
            {
                return "Medium gas usage";
            }
            if (iterations <= 5000)
            {
                return "High gas usage";
            }
            return "Extreme gas risk";
        }
    }

    // COMPARE SAFE VS UNSAFE
    
    function compareLoops() external view returns (string memory unsafeLoop, string memory safeLoop)
    {
        unsafeLoop = "loops entir array and may cause OOG";

        unsafeLoop = "Uses chunking to prevent OOG";
    }

    /*
    =====================================================
    GET LENGTH
    =====================================================
    */

    function getLength()
        external
        view
        returns (uint256)
    {

        return data.length;
    }
}