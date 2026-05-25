// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Compare calldata vs memory
CONCEPT: Gas + mutability
=========================================================

OBJECTIVE

- Learn difference between calldata and memory
- Understand gas efficiency differences
- Learn mutability behavior
- Understand when to use calldata vs memory

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

CALLDATA:
- external input area
- read-only
- cheaper
- avoids copying

MEMORY:
- temporary execution area
- mutable
- more expensive
- requires allocation/copying

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Choosing correct data location:
- affects gas usage
- affects mutability
- affects protocol efficiency

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Gas optimization is critical in:

- DeFi protocols
- routers
- NFT systems
- governance contracts
- multicall architectures

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

CALldata commonly used for:
- external read-only inputs

Memory commonly used for:
- temporary modifications
- internal processing

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is calldata preferable?
- Are unnecessary copies created?
- Are developers misunderstanding mutability?
- Can large copies create DOS?
- Is gas optimized properly?

=========================================================
*/

contract CalldataVsMemoryval {

    /*
        STORAGE ARRAY

        Permanent blockchain data.
    */
    uint256[] public storedValues;

    /*
    =====================================================
    CALLDATA EXAMPLE
    =====================================================

    Efficient external read-only input.
    */

    function useCalldata(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {

        uint256 total = 0;

        /*
            LOOP DIRECTLY OVER CALLDATA

            No memory copy created.
        */
        for (uint256 i = 0; i < _numbers.length; i++) {

            total += _numbers[i];
        }

        return total;
    }

    /*
    =====================================================
    MEMORY EXAMPLE
    =====================================================

    Creates memory copy.
    */

    function useMemory(
        uint256[] memory _numbers
    )
        public
        pure
        returns (uint256)
    {

        uint256 total = 0;

        /*
            _numbers exists in memory.

            Mutable temporary copy.
        */
        for (uint256 i = 0; i < _numbers.length; i++) {

            total += _numbers[i];
        }

        return total;
    }

    /*
    =====================================================
    MEMORY MODIFICATION EXAMPLE
    =====================================================

    Memory arrays are mutable.
    */

    function modifyMemory(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256[] memory)
    {

        /*
            COPY CALLDATA INTO MEMORY
        */
        uint256[] memory tempArray = _numbers;

        /*
            MODIFY MEMORY ARRAY

            Allowed.
        */
        tempArray[0] = 999;

        return tempArray;
    }

    /*
    =====================================================
    STORAGE WRITE EXAMPLE
    =====================================================
    */

    function saveValues(
        uint256[] calldata _numbers
    )
        external
    {

        /*
            Copy calldata values into storage.
        */
        for (uint256 i = 0; i < _numbers.length; i++) {

            storedValues.push(_numbers[i]);
        }
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
useCalldata([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Loop reads directly from calldata
3. No memory copy created
4. Result returned
5. Calldata discarded

---------------------------------------------------------

GAS:
Cheaper

=========================================================

CALL:
modifyMemory([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Full copy created in memory
3. Memory array modified
4. Modified copy returned
5. Memory destroyed

---------------------------------------------------------

GAS:
More expensive than calldata-only read

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
useCalldata([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 3:
Call:
useMemory([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 4:
Compare gas usage

OBSERVE:
calldata cheaper than memory

---------------------------------------------------------

STEP 5:
Call:
modifyMemory([5,6,7])

EXPECTED:
[999,6,7]

---------------------------------------------------------

STEP 6:
Observe:
Original calldata unchanged

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Pass empty array

EXPECTED:
0

---------------------------------------------------------

TEST:
Pass huge array

OBSERVE:
Higher gas usage

---------------------------------------------------------

TEST:
Modify calldata directly

EXPECTED:
Compiler error

=========================================================
IMPORTANT CALLDATA UNDERSTANDING
=========================================================

CALLDATA:
- temporary
- immutable
- external-input optimized

---------------------------------------------------------

BEST FOR:
Read-only external inputs.

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

MEMORY:
- temporary
- mutable
- supports modifications

---------------------------------------------------------

BEST FOR:
Temporary processing and mutations.

=========================================================
CALLDATA VS MEMORY COMPARISON
=========================================================

---------------------------------------------------------
CALLDATA
---------------------------------------------------------

Read-only

Cheaper

No automatic copy

Cannot modify

External functions only

---------------------------------------------------------
MEMORY
---------------------------------------------------------

Mutable

More expensive

Requires allocation

Can modify

Used internally too

=========================================================
GAS OBSERVATION
=========================================================

CALLDATA:
More gas efficient

---------------------------------------------------------

Reason:
Avoids memory allocation/copying.

---------------------------------------------------------

MEMORY:
More expensive due to:
- allocation
- copying
- expansion

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. UNNECESSARY MEMORY COPIES
---------------------------------------------------------

Common gas inefficiency.

Auditors recommend:
calldata where possible.

---------------------------------------------------------
2. DOS VIA LARGE ARRAYS
---------------------------------------------------------

Huge arrays may:
- exhaust gas
- break loops
- create scalability issues

---------------------------------------------------------
3. MUTABILITY CONFUSION
---------------------------------------------------------

Developers may incorrectly assume:
calldata can be modified.

---------------------------------------------------------
4. LOOP RISKS
---------------------------------------------------------

Attacker-controlled arrays
must be bounded carefully.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker submits huge array.

Contract unnecessarily copies:
calldata -> memory.

Result:
- wasted gas
- DOS condition
- inefficient execution

---------------------------------------------------------

ANOTHER RISK

Developer expects:
calldata modification.

Logic silently fails.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Accept calldata string array
2. Copy into memory
3. Modify one element safely
4. Return updated memory array

BONUS:
Measure gas differences in Remix.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata is read-only
- Memory is mutable
- Calldata cheaper than memory
- Memory requires allocation
- Copying arrays costs gas
- External inputs arrive via calldata
- Memory useful for temporary modifications
- Large arrays create DOS risks
- Gas optimization matters heavily
- Auditors inspect data-location efficiency carefully

=========================================================
*/

/*
Title: Safe modification of calldata string array using memory copies

Severity: Low

Reason: String arrays received through calldata are read-only. To modify any element safely, the array must first be copied into memory

Location: Contract: CalldataVsMemory
          New Function: modifyStringArray()

Vulnerability Description: The contract demonstrates
1. calldata uint arrays
2. memory uint arrays
3. calldata-to-memory copying

However it does not demonstrate the same behavior with dynamic string arrays
A string array passed as:

string[] calldata _names

cannot be modified directly because calldata is immutable.

The correct approach is:

1. Accept a calldata string array
2. Copy it into memory
3. Modify a memory element
4. Return the updated memory array

Impact: Attempting to modify calldata directly results in
- comiler errors
- deployment failure
using memory copies allows safe modification while preserving the original calldata

Proof of concept:
input: ;["Alice","Bob","Charlie"]

copy to memory:
string[] memory tempNames = new string[](_names.length);

Mofify: 
tempNames[1] = "Modified";

Output:
["Alice", "Modified","Charlie"]
- Orginal calldata remains unchanged

Root Cause: calldata arrays are immutable by design
Direct modification such as: _name[0] = "Test";
- is prohibited by the solidity compiler

Recommendation: Copy calldata arrays into memory before performing modifications


*/

// Patched code

contract CalldataVsMemory {

    /*
        STORAGE ARRAY

        Permanent blockchain data.
    */
    uint256[] public storedValues;

    /*
    =====================================================
    CALLDATA EXAMPLE
    =====================================================

    Efficient external read-only input.
    */

    function useCalldata(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {

        uint256 total = 0;

        /*
            LOOP DIRECTLY OVER CALLDATA

            No memory copy created.
        */
        for (uint256 i = 0; i < _numbers.length; i++) {

            total += _numbers[i];
        }

        return total;
    }

    /*
    =====================================================
    MEMORY EXAMPLE
    =====================================================

    Creates memory copy.
    */

    function useMemory(
        uint256[] memory _numbers
    )
        public
        pure
        returns (uint256)
    {

        uint256 total = 0;

        /*
            _numbers exists in memory.

            Mutable temporary copy.
        */
        for (uint256 i = 0; i < _numbers.length; i++) {

            total += _numbers[i];
        }

        return total;
    }

    /*
    =====================================================
    MEMORY MODIFICATION EXAMPLE
    =====================================================

    Memory arrays are mutable.
    */

    function modifyMemory(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256[] memory)
    {

        /*
            COPY CALLDATA INTO MEMORY
        */
        uint256[] memory tempArray = _numbers;

        /*
            MODIFY MEMORY ARRAY

            Allowed.
        */
        tempArray[0] = 999;

        return tempArray;
    }

// STRING ARRAY EXAMPLE

    function modifyStringArray(string[] calldata _names) external pure returns (string[] memory)
    {
        require(_names.length > 0, "Array cannot be empty");

        string[] memory tempNames = new string[](_names.length);

        for(uint256 i = 0; i < _names.length; i++)
        {
            tempNames[i] = _names[i];
        }

        tempNames[0] = "Modified Name";

        return tempNames;
    }

    /*
    =====================================================
    STORAGE WRITE EXAMPLE
    =====================================================
    */

    function saveValues(
        uint256[] calldata _numbers
    )
        external
    {

        /*
            Copy calldata values into storage.
        */
        for (uint256 i = 0; i < _numbers.length; i++) {

            storedValues.push(_numbers[i]);
        }
    }
}