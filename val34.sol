// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Pass nested calldata array
CONCEPT: Complex input handling
=========================================================

OBJECTIVE

- Learn how nested calldata arrays work
- Understand complex ABI input decoding
- Learn handling of multi-dimensional arrays
- Understand gas/scaling risks of nested structures

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Nested arrays are arrays inside arrays.

Example:

[
    [1,2],
    [3,4],
    [5,6]
]

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Nested calldata arrays:
- are read-only
- are externally supplied
- require ABI decoding
- can become expensive at scale

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Complex nested structures appear in:

- batch DeFi operations
- governance systems
- Merkle proofs
- routing paths
- advanced multicalls

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Nested arrays used in:

- Uniswap swap paths
- batch execution systems
- matrix-style computations
- grouped transactions
- multi-user operations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Input complexity
- Nested loop gas risks
- ABI decoding correctness
- DOS vulnerabilities
- Scalability failures

=========================================================
*/

contract NestedCalldataArrayval {

    /*
        STORAGE VARIABLE

        Permanent blockchain state.
    */
    uint256 public totalSum;

    /*
    =====================================================
    READ NESTED CALLDATA ARRAY
    =====================================================
    */

    function readNestedArray(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256[][] memory)
    {

        /*
            Returning nested calldata array.

            Solidity ABI-encodes nested structure.
        */
        return _matrix;
    }

    /*
    =====================================================
    CALCULATE TOTAL SUM
    =====================================================
    */

    function calculateNestedSum(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256)
    {

        uint256 total = 0;

        /*
            OUTER LOOP

            Iterates outer arrays.
        */
        for (uint256 i = 0; i < _matrix.length; i++) {

            /*
                INNER LOOP

                Iterates inner arrays.
            */
            for (
                uint256 j = 0;
                j < _matrix[i].length;
                j++
            ) {

                total += _matrix[i][j];
            }
        }

        return total;
    }

    /*
    =====================================================
    SAVE COMPUTED TOTAL
    =====================================================
    */

    function processAndStore(
        uint256[][] calldata _matrix
    )
        external
    {

        uint256 total = 0;

        /*
            Nested loop processing.
        */
        for (uint256 i = 0; i < _matrix.length; i++) {

            for (
                uint256 j = 0;
                j < _matrix[i].length;
                j++
            ) {

                total += _matrix[i][j];
            }
        }

        /*
            Store result permanently.
        */
        totalSum = total;
    }

    /*
    =====================================================
    GET DIMENSIONS
    =====================================================
    */

    function getOuterLength(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256)
    {

        return _matrix.length;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:

calculateNestedSum(
[
    [1,2],
    [3,4]
]
)

=========================================================

EVM ACTIONS

1. Nested array arrives in calldata
2. Solidity ABI-decodes structure
3. Outer loop processes rows
4. Inner loop processes elements
5. Total computed
6. Result returned
7. Calldata discarded

---------------------------------------------------------

CALCULATION:

1 + 2 + 3 + 4 = 10

---------------------------------------------------------

RESULT:
10

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
readNestedArray()

INPUT:

[
    [1,2],
    [3,4]
]

EXPECTED:
Same nested array returned

---------------------------------------------------------

STEP 3:
Call:
calculateNestedSum()

INPUT:

[
    [1,2],
    [3,4]
]

EXPECTED:
10

---------------------------------------------------------

STEP 4:
Call:
processAndStore()

INPUT:

[
    [5,5],
    [10]
]

---------------------------------------------------------

STEP 5:
Call:
totalSum()

EXPECTED:
20

---------------------------------------------------------

STEP 6:
Call:
getOuterLength()

INPUT:

[
    [1],
    [2],
    [3]
]

EXPECTED:
3

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Empty outer array

INPUT:
[]

EXPECTED:
0

---------------------------------------------------------

TEST:
Empty inner arrays

INPUT:
[
    [],
    []
]

EXPECTED:
0

---------------------------------------------------------

TEST:
Very large nested arrays

OBSERVE:
Extremely high gas usage

=========================================================
IMPORTANT NESTED ARRAY UNDERSTANDING
=========================================================

TYPE:

uint256[][] calldata

---------------------------------------------------------

MEANS:

Array of uint256 arrays.

---------------------------------------------------------

STRUCTURE:

[
    [row1],
    [row2],
    [row3]
]

=========================================================
NESTED LOOP RISK
=========================================================

THIS IS IMPORTANT:

Nested loops scale badly.

---------------------------------------------------------

OUTER LOOP:
N iterations

INNER LOOP:
M iterations

---------------------------------------------------------

TOTAL OPERATIONS:
N × M

=========================================================
CALLDATA IMMUTABILITY
=========================================================

Nested calldata arrays are:
READ-ONLY.

---------------------------------------------------------

THIS FAILS:

_matrix[0][0] = 999;

---------------------------------------------------------

Reason:
calldata is immutable.

=========================================================
ABI DECODING COMPLEXITY
=========================================================

Nested arrays require:
complex ABI decoding.

---------------------------------------------------------

LARGER STRUCTURES:
More decoding cost.

=========================================================
GAS OBSERVATION
=========================================================

SMALL NESTED ARRAYS:
Cheap

---------------------------------------------------------

LARGE NESTED ARRAYS:
Very expensive

---------------------------------------------------------

NESTED LOOPS:
Multiply gas consumption rapidly

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. DOS VIA NESTED LOOPS
---------------------------------------------------------

Most important risk.

Nested attacker-controlled arrays
can exhaust gas quickly.

---------------------------------------------------------
2. UNBOUNDED INPUTS
---------------------------------------------------------

Large nested structures may:
- exceed block gas limit
- break protocol usability

---------------------------------------------------------
3. ABI DECODING RISKS
---------------------------------------------------------

Complex nested structures
increase decoding complexity.

---------------------------------------------------------
4. SCALABILITY FAILURES
---------------------------------------------------------

Functions may become unusable
as input size grows.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker submits huge nested arrays.

Nested loops explode computational cost.

Result:
- out-of-gas
- DOS condition
- protocol unusability

---------------------------------------------------------

REAL-WORLD ISSUE

Improper batch-processing logic
has caused scalability failures
in production contracts.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Find largest number
inside nested array

2. Reject arrays larger than:
- outer length > 50
- inner length > 50

BONUS:
Add pagination support.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Nested arrays contain arrays inside arrays
- Nested calldata arrays are read-only
- ABI decoding handles complex structures
- Nested loops scale poorly
- Large nested inputs increase gas heavily
- Unbounded loops create DOS risks
- External inputs are attacker-controlled
- Scalability is critical in Solidity
- Complex structures require careful auditing
- Auditors inspect nested-loop behavior carefully

=========================================================
*/

/*
Title: Missing Bounds Validation and Maximum Value Search in Nested Calldata Arrays

Severity: Medium

Reason: Nested arrays can consume significant gas due to double loops. Without limits on outer and inner array sizes, transactions may become too expensive or fail. 
        The contract also lacks functionality to find the largest value in the nested structure.

Location: Contract: NestedCalldataArray
          New Function: findLargestNumber()

Vulnerability Description:
The contract currently:

reads nested calldata arrays
calculates sums
stores results

However, it does not:

validate nested array dimensions
find the maximum value
support partial processing (pagination)

Large nested arrays can result in:

outer length = 1000
inner length = 1000

which requires 1,000,000 iterations.

Impact: Without size restrictions:

- excessive gas consumption
- possible out-of-gas failures
- reduced scalability

Without a maximum search function:

- users cannot efficiently determine the largest value in the matrix

Proof of Concept
Input:

[
  [10,20,30],
  [99,40,50],
  [5,6,7]
]

Processing:
largest = 10
20 > 10 → 20
30 > 20 → 30
99 > 30 → 99

Output: 99

Root Cause: The contract lacks:
- outer array size validation
- inner array size validation
- maximum value search logic

Recommendation:

Add:

require(_matrix.length <= 50);

and

require(_matrix[i].length <= 50);

before processing.
*/

//Patched code

contract NestedCalldataArray {

    /*
        STORAGE VARIABLE

        Permanent blockchain state.
    */
    uint256 public totalSum;

    /*
    =====================================================
    READ NESTED CALLDATA ARRAY
    =====================================================
    */

    function readNestedArray(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256[][] memory)
    {

        /*
            Returning nested calldata array.

            Solidity ABI-encodes nested structure.
        */
        return _matrix;
    }

    /*
    =====================================================
    CALCULATE TOTAL SUM
    =====================================================
    */

// FIND LARGEST NUMBER

    uint256 public constant MAX_OUTER_LENGTH = 50;

    uint256 public constant MAX_INNER_LENGTH = 50;

    function findLargestNumber(uint256[][] calldata _matrix) external pure returns (uint256)
    {
        require(_matrix.length > 0, "Array must not be empty");

        require(_matrix.length <= MAX_OUTER_LENGTH, "Outer array too large");

        uint256 largest = _matrix[0][0];

        for(uint256 i = 0; i < _matrix.length; i++)
        {
            require(_matrix[i].length > 0, "Empty inner array");

            require(_matrix[i].length <= MAX_INNER_LENGTH,"Inner array too large");

            for(uint256 j = 0; j < _matrix[i].length; j++)
            {
                if(_matrix[i][j] > largest)
                {
                    largest = _matrix[i][j];
                }
            }
        }

        return largest;
    }

    function calculateNestedSum(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256)
    {

        uint256 total = 0;

        /*
            OUTER LOOP

            Iterates outer arrays.
        */
        for (uint256 i = 0; i < _matrix.length; i++) {

            /*
                INNER LOOP

                Iterates inner arrays.
            */
            for (
                uint256 j = 0;
                j < _matrix[i].length;
                j++
            ) {

                total += _matrix[i][j];
            }
        }

        return total;
    }

    /*
    =====================================================
    SAVE COMPUTED TOTAL
    =====================================================
    */

    function processAndStore(
        uint256[][] calldata _matrix
    )
        external
    {

        uint256 total = 0;

        /*
            Nested loop processing.
        */
        for (uint256 i = 0; i < _matrix.length; i++) {

            for (
                uint256 j = 0;
                j < _matrix[i].length;
                j++
            ) {

                total += _matrix[i][j];
            }
        }

        /*
            Store result permanently.
        */
        totalSum = total;
    }

    /*
    =====================================================
    GET DIMENSIONS
    =====================================================
    */

    function getOuterLength(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256)
    {

        return _matrix.length;
    }
}