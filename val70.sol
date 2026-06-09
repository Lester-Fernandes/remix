// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Pass huge calldata array
CONCEPT: Gas impact
=========================================================

OBJECTIVE

- Understand calldata gas efficiency
- Compare large input handling costs
- Learn why calldata is preferred over memory
- Observe gas impact of large arrays

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

calldata = read-only external input

---------------------------------------------------------

Huge calldata arrays:
do NOT get copied into memory automatically.

---------------------------------------------------------

This makes calldata cheaper than memory.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Gas cost increases with:

- array size
- decoding complexity
- storage writes (if any)
- loops over data

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Large inputs appear in:

- batch transfers
- airdrops
- multicall systems
- oracle feeds
- on-chain aggregation

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- calldata size limits
- loop processing cost
- gas scaling behavior
- DOS via large inputs

=========================================================
CALDATA CONTRACT
=========================================================
*/

contract CalldataGasval {

    /*
        STORE PROCESSED SUM
    */
    uint256 public totalSum;

    /*
        TRACK ELEMENT COUNT
    */
    uint256 public totalElements;

    /*
    =====================================================
    PROCESS HUGE CALDATA ARRAY
    =====================================================
    */

    function processCalldataArray(
        uint256[] calldata data
    )
        external
    {

        /*
            Local variable in stack.
        */
        uint256 sum = 0;

        /*
        =================================================
        LOOP OVER CALDATA ARRAY
        =================================================
        */

        for (
            uint256 i = 0;
            i < data.length;
            i++
        ) {

            /*
                READ FROM CALDATA

                Cheap read-only access.
            */
            sum += data[i];

            /*
                Storage update per iteration.
                (expensive part)
            */
            totalElements++;
        }

        /*
            One final storage write.
        */
        totalSum = sum;
    }

    /*
    =====================================================
    COMPARE MEMORY VERSION
    =====================================================
    */

    function processMemoryArray(
        uint256[] memory data
    )
        public
        pure
        returns (uint256)
    {

        uint256 sum = 0;

        for (
            uint256 i = 0;
            i < data.length;
            i++
        ) {

            /*
                Memory access.
            */
            sum += data[i];
        }

        return sum;
    }

    /*
    =====================================================
    GET TOTAL ELEMENTS
    =====================================================
    */

    function getTotalElements()
        external
        view
        returns (uint256)
    {

        return totalElements;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy CalldataGas

=========================================================
TRACE:
processCalldataArray()
=========================================================

INPUT:
Huge uint256[] calldata

Example size:
1000 elements

=========================================================
STEP 2
=========================================================

Function starts.

---------------------------------------------------------

sum = 0

=========================================================
STEP 3
=========================================================

Loop begins:

i = 0

=========================================================
STEP 4
=========================================================

Read:

data[0]

---------------------------------------------------------

Add to sum.

---------------------------------------------------------

sum += data[0]

=========================================================
STEP 5
=========================================================

Storage write:

totalElements++

---------------------------------------------------------

IMPORTANT:
This is expensive.

=========================================================
STEP 6
=========================================================

Loop continues:

i = 1 ... 999

=========================================================
IMPORTANT BEHAVIOR
=========================================================

Each iteration:

---------------------------------------------------------
READ
---------------------------------------------------------

from calldata (cheap)

---------------------------------------------------------
WRITE
---------------------------------------------------------

to storage (expensive)

=========================================================
FINAL STEP
=========================================================

After loop:

totalSum = sum

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
totalElements
---------------------------------------------------------

= number of elements processed

---------------------------------------------------------
totalSum
---------------------------------------------------------

= sum of all values

=========================================================
WHY CALDATA IS IMPORTANT
=========================================================

calldata is:

---------------------------------------------------------
READ-ONLY
---------------------------------------------------------

AND

---------------------------------------------------------
NO COPYING INTO MEMORY
---------------------------------------------------------

=========================================================
GAS ADVANTAGE
=========================================================

Compared to memory:

- NO extra copy cost
- NO allocation overhead
- DIRECT access

=========================================================
BUT IMPORTANT
=========================================================

Gas still increases due to:

---------------------------------------------------------
LOOP PROCESSING
---------------------------------------------------------

AND

---------------------------------------------------------
STORAGE WRITES
---------------------------------------------------------

=========================================================
MEMORY VS CALDATA COMPARISON
=========================================================

---------------------------------------------------------
calldata
---------------------------------------------------------

- cheapest input
- read-only
- no copying
- best for external inputs

=========================================================

---------------------------------------------------------
memory
---------------------------------------------------------

- copied data
- more gas than calldata
- mutable

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

=========================================================
TEST 1
=========================================================

Call:
processCalldataArray([1,2,3,...1000])

---------------------------------------------------------

Observe:
moderate gas usage

=========================================================
TEST 2
=========================================================

Call:
processMemoryArray([...1000 values...])

---------------------------------------------------------

Observe:
higher gas than calldata version

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Large calldata inputs can cause:

---------------------------------------------------------
GAS DOS
---------------------------------------------------------

if processing is heavy.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. LARGE INPUT LOOPS
---------------------------------------------------------

Gas scales linearly.

---------------------------------------------------------
2. STORAGE INSIDE LOOP
---------------------------------------------------------

Major gas explosion.

---------------------------------------------------------
3. UNBOUNDED CALDATA SIZE
---------------------------------------------------------

Attacker can send huge arrays.

---------------------------------------------------------
4. DENIAL OF SERVICE
---------------------------------------------------------

Function becomes too expensive.

=========================================================
ATTACK THINKING
=========================================================

Attackers may:

- send huge arrays
- force gas exhaustion
- exploit loop scaling
- DOS processing functions

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors check:

- calldata size limits
- loop complexity O(n)
- storage writes per iteration
- gas upper bounds
- worst-case execution cost

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors estimate:

---------------------------------------------------------
MAX ARRAY SIZE IMPACT
---------------------------------------------------------

AND

---------------------------------------------------------
BLOCK GAS LIMIT SAFETY
---------------------------------------------------------

=========================================================
BEST PRACTICES
=========================================================

- Use calldata for external inputs
- Avoid storage writes in loops
- Batch processing carefully
- Enforce input size limits
- Prefer O(1) or O(log n) designs

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Limit array size to 500
2. Compare 500 vs 1000 gas usage
3. Remove storage writes in loop
4. Add batch processing function

BONUS:
Create gas-safe streaming processor.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata is cheapest input type
- Large arrays increase gas linearly
- Storage writes dominate gas cost
- calldata avoids memory copy cost
- loops over large inputs are expensive
- gas scaling can cause DOS
- auditors analyze worst-case input size
- calldata is read-only external input
- optimization reduces execution cost
- input validation is critical for security

=========================================================
*/
/*
Title: Gas optimization and batch processing for large calldata arrays

Severity: Medium

Reason: Large calldata arrays and repeated loop execution may significantly increase gas consumotion, especially when processing large datasets without batching or optimization.

Location: Contract: calldataGas

Affected Function: process500Array()
                   process1000Array()
                   batchprocess()

Vulnerability Description: The original contract processed dynamic calldata arrays without strict size limits and performed storage updates during iterative execution

Large array processing increases:
- loop execution cost
- calldata read overhead
- storage write expenses
The modified implementation introduces:
- array size limits
- gas usage comparison
- optimized loops
- batch processing

Impact: Without optimization
- transactions may consume excessive gas
- large arrays may cause out of gas failures
- repeated storage writes may reduce scalability
Large iterative execution can also lead to:
- denial of service risks
- expensive transaction fees
- inefficient protocol execution

Proof of Concept:
Step 1 — Deploy Contract

Deploy: CalldataGas

Step 2 — Process 500 Elements

Call: process500Array(data)

where:

data.length <= 500

Observe lower gas usage.

Step 3 — Process 1000 Elements

Call: process1000Array(data)

Observe increased gas consumption compared to the 500-element version.

Step 4 — Batch Processing

Call: batchProcess(batches)

The contract processes multiple arrays efficiently using controlled batch sizes.

Root Cause: The issue exists because:
- large loops increase execution cost
- repeated iterations scale linearly
- storage writes are expensive
- large calldata arrays increase processing overhead
*/

// PATCHED CODE

contract CalldataGas {

    /*
        STORE PROCESSED SUM
    */
    uint256 public totalSum;

    /*
        TRACK ELEMENT COUNT
    */
    uint256 public totalElements;

    // TRACK LAST GAS USED
    uint256 public lastGasUsed;

    // EVENTS
    event GasMeasured(string operation, uint256 gasUsed);

    /*
    =====================================================
    PROCESS HUGE CALDATA ARRAY
    =====================================================
    */

    function processCalldataArray(
        uint256[] calldata data
    )
        external
    {

       
        require(data.length <= 500, "max 500 elements");

        uint256 startGas = gasleft();

        uint256 sum = 0;

        /*
        =================================================
        LOOP CALDATA ARRAY
        =================================================
        */

        for (
            uint256 i = 0;
            i < data.length;
            i++
        ) {

            
            sum += data[i];

        }

        totalElements+= data.length;

        totalSum = sum;

        lastGasUsed = startGas - gasleft();

        emit GasMeasured("500 Element Processing", lastGasUsed);
    }

    // PROCESS 1000 ELEMENTS

    function process1000Array(uint256[] calldata data) external 
    {
        require(data.length <= 1000, "Max 1000 elements");

        uint256 startGas = gasleft();

        uint256 sum = 0;

        // Larger calldata loop
        for(uint256 i = 0; i < data.length; i++)
        {
            sum += data[i];

            // Single storage writes
            totalSum = sum;

            totalElements += data.length;

            // Measure gas
            lastGasUsed = startGas - gasleft();

            emit GasMeasured("1000 Element Processing",lastGasUsed);
        }
    }

    /*
    =====================================================
     MEMORY VERSION
    =====================================================
    */

    function processMemoryArray(
        uint256[] memory data
    )
        public
        pure
        returns (uint256)
    {

        uint256 sum = 0;

        for (
            uint256 i = 0;
            i < data.length;
            i++
        ) {

            /*
                Memory access.
            */
            sum += data[i];
        }

        return sum;
    }

    // BATCH PROCESSING
    function batchProcess(uint256[][] calldata batches) external 
    {
        uint256 satrtGas = gasleft();

        uint256 globalSum = 0;

        uint256 elementCount = 0;

        // PROCESS MULTIPLE BATCHES
        for(uint256 i = 0; i < batches.length; i++)
        {
            require(batches[i].length <= 500, "Batch too large");

            for(uint256 j = 0; j < batches[i].length; j++)
            {
                globalSum += batches[i][j];

                elementCount++;
            }
        }

        // FINAL STORAGE WRITES
        totalSum = globalSum;

        totalElements += elementCount;

        // SAVE GAS USAGE
        lastGasUsed = satrtGas - gasleft();

        emit GasMeasured("Batch Processing",lastGasUsed);
    }

    /*
    =====================================================
    GET TOTAL ELEMENTS
    =====================================================
    */

    function getTotalElements()
        external
        view
        returns (uint256)
    {

        return totalElements;
    }

    // CONTRACT BALANCE
    function contractBalance() external view returns (uint256)
    {
        return address(this).balance;
    }
}