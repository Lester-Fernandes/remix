// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Return large memory array
CONCEPT: Memory allocation
=========================================================

OBJECTIVE

- Learn how large memory arrays are allocated
- Understand memory expansion costs
- Learn how returning large arrays affects gas
- Understand scalability risks in Solidity

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Memory arrays are allocated dynamically
during execution.

Larger arrays:
- require more memory
- consume more gas
- increase execution cost

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Returning large arrays can become expensive.

Reason:
EVM must:
- allocate memory
- store elements
- encode return data

---------------------------------------------------------
REAL-WORLD IMPORTANCE
---------------------------------------------------------

Large memory operations affect:

- scalability
- gas efficiency
- DOS resistance
- protocol usability

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Large arrays appear in:

- DeFi protocols
- NFT collections
- staking systems
- governance snapshots
- batch operations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Can arrays grow unbounded?
- Can functions become uncallable?
- Is gas exhaustion possible?
- Are loops scalable?
- Is pagination needed?

=========================================================
*/

contract LargeMemoryArrayval {

    /*
        STORAGE ARRAY

        Persists permanently.
    */
    uint256[] public storedValues;

    function addValues(uint256 _count) public {

        /*
            Add values into storage array.

            WARNING:
            Large loops increase gas usage.
        */
        for (uint256 i = 0; i < _count; i++) {

            storedValues.push(i);
        }
    }

    function returnLargeArray(uint256 _size)
        public
        pure
        returns (uint256[] memory)
    {

        /*
            CREATE LARGE MEMORY ARRAY

            Memory allocated dynamically.
        */
        uint256[] memory tempArray =
            new uint256[](_size);

        /*
            Fill memory array
        */
        for (uint256 i = 0; i < _size; i++) {

            tempArray[i] = i + 1;
        }

        /*
            Entire array returned.

            Larger arrays:
            higher gas cost.
        */
        return tempArray;
    }

    function copyStorageToMemory()
        public
        view
        returns (uint256[] memory)
    {

        /*
            FULL STORAGE -> MEMORY COPY

            Dangerous if storage array becomes huge.
        */
        return storedValues;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
returnLargeArray(5)

EVM ACTIONS:

1. Allocate memory for 5 elements
2. Create temporary array
3. Fill array using loop
4. Encode return data
5. Return memory array
6. Memory cleared after execution

---------------------------------------------------------

RETURNED ARRAY:

[1,2,3,4,5]

=========================================================

CALL:
returnLargeArray(1000)

OBSERVE:

- more memory allocation
- more loop iterations
- higher gas consumption
- larger return data

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
returnLargeArray(5)

EXPECTED:
[1,2,3,4,5]

---------------------------------------------------------

STEP 3:
Call:
returnLargeArray(50)

OBSERVE:
Higher execution cost

---------------------------------------------------------

STEP 4:
Call:
returnLargeArray(500)

OBSERVE:
Even higher gas usage

---------------------------------------------------------

STEP 5:
Call:
addValues(20)

---------------------------------------------------------

STEP 6:
Call:
copyStorageToMemory()

EXPECTED:
Returns all stored values

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
_size = 0

EXPECTED:
Empty array returned

---------------------------------------------------------

TEST:
Very large _size

OBSERVE:
Possible:
- high gas cost
- out-of-gas errors

---------------------------------------------------------

TEST:
Huge storage array copy

OBSERVE:
Function may become expensive/unusable

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

THIS LINE:

new uint256[](_size)

---------------------------------------------------------

ALLOCATES:
dynamic memory space.

---------------------------------------------------------

LARGER ARRAYS:
require more EVM memory expansion.

---------------------------------------------------------

VERY IMPORTANT

Memory is temporary:
cleared after execution.

=========================================================
MEMORY EXPANSION COST
=========================================================

EVM charges gas for:
- allocating memory
- expanding memory
- writing values
- encoding return data

---------------------------------------------------------

LARGE ARRAYS:
grow gas costs rapidly.

=========================================================
RETURN DATA COST
=========================================================

Returning large arrays also costs gas.

Reason:
EVM must ABI-encode:
every array element.

=========================================================
SCALABILITY RISK
=========================================================

UNBOUNDED ARRAYS ARE DANGEROUS.

Functions may become:
- too expensive
- uncallable
- DOS vulnerable

=========================================================
GAS OBSERVATION
=========================================================

SMALL ARRAY:
Cheap

---------------------------------------------------------

LARGE ARRAY:
Expensive

---------------------------------------------------------

VERY LARGE ARRAY:
Possible out-of-gas failure

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. DOS VIA GAS EXHAUSTION
---------------------------------------------------------

Huge arrays may:
- exceed block gas limit
- make function unusable

---------------------------------------------------------
2. UNBOUNDED LOOPS
---------------------------------------------------------

Loops over attacker-controlled size
are dangerous.

---------------------------------------------------------
3. STORAGE-TO-MEMORY COPYING
---------------------------------------------------------

Copying massive storage arrays
can break scalability.

---------------------------------------------------------
4. PAGINATION REQUIREMENT
---------------------------------------------------------

Auditors often recommend:
pagination instead of returning everything.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker grows storage array massively.

Then calls:
copyStorageToMemory()

Result:
- excessive gas usage
- DOS condition
- function unusable

---------------------------------------------------------

REAL-WORLD ISSUE

Many protocols became uncallable
because arrays grew too large.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add pagination support
2. Return only partial array range
3. Avoid returning entire huge array

BONUS:
Implement:
(start, limit) logic

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Memory arrays allocate temporary memory
- Large arrays increase gas consumption
- Memory expansion costs gas
- Returning arrays requires ABI encoding
- Large return data becomes expensive
- Unbounded loops create scalability risks
- Storage-to-memory copying can be dangerous
- DOS via gas exhaustion is common
- Pagination improves scalability
- Auditors inspect array growth carefully

=========================================================
*/
/*
Title: Unbounded Large Array Return May Cause Excessive Gas Consumption

Severity: Medium

Reason: Returning very large arrays can consume excessive gas and may eventually fail due to block gas limits.

Location:
Contract: LargeMemoryArray
Functions:
returnLargeArray()
copyStorageToMemory()

Vulnerability Description:

The contract allows returning entire arrays from memory and storage:

return storedValues;

and

new uint256[](_size);

If arrays become very large:

memory allocation cost increases
storage-to-memory copying becomes expensive
returning huge arrays may exceed gas limits
frontend RPC calls may fail

The contract lacks pagination support, forcing callers to retrieve the entire dataset at once.

Impact: Large array returns may cause:
transaction failures
out-of-gas errors
frontend performance issues
denial-of-service style behavior
expensive RPC responses

Proof of Concept: Large Storage Array

Suppose storage contains:

storedValues.length = 100000

Calling:

copyStorageToMemory()

Root Cause: The contract lacks
- pagination logic
- bounded array retrieval
- partial memory copying

Recommendation:
Implement pagination using:

start

and

limit

Return only partial array ranges instead of the full dataset.
*/

//Patched code

contract LargeMemoryArray 
{

    /*
        STORAGE ARRAY

        Persists permanently.
    */
    uint256[] public storedValues;

    function addValues(uint256 _count) public {

        /*
            Add values into storage array.

            WARNING:
            Large loops increase gas usage.
        */
        for (uint256 i = 0; i < _count; i++) {

            storedValues.push(i);
        }
    }

    function returnLargeArray(uint256 _size)
        public
        pure
        returns (uint256[] memory)
    {

        /*
            CREATE LARGE MEMORY ARRAY

            Memory allocated dynamically.
        */
        uint256[] memory tempArray =
            new uint256[](_size);

        /*
            Fill memory array
        */
        for (uint256 i = 0; i < _size; i++) {

            tempArray[i] = i + 1;
        }

        /*
            Entire array returned.

            Larger arrays:
            higher gas cost.
        */
        return tempArray;
    }

    function getPaginatedValues(uint256 _start, uint256 _limit) public view returns (uint256[] memory)
    {
        require( _start < storedValues.length, "Start index out of bounds");
    

        uint256 end = _start + _limit;
    

    if(end > storedValues.length)
    {
        end = storedValues.length;
    }

    uint256 resultSize = end - _start;

    uint256[] memory result = new uint256[](resultSize);

    for(uint256 i = 0; i < resultSize; i++)
    {
        result[i] = storedValues[_start + i];

    
    }

        return result;
    }
    function getLength() public view returns (uint256)
    {
        return storedValues.length;
    }

    function copyStorageToMemory()
        public
        view
        returns (uint256[] memory)
    {

        /*
            FULL STORAGE -> MEMORY COPY

            Dangerous if storage array becomes huge.
        */
        return storedValues;
    }
}