// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Compare storage vs memory updates
CONCEPT: Reference behavior
=========================================================

OBJECTIVE

- Learn difference between storage and memory updates
- Understand reference vs copy behavior
- Learn why storage changes persist
- Understand why memory changes disappear

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

STORAGE:
Creates direct reference to blockchain state.

MEMORY:
Creates temporary independent copy.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

STORAGE UPDATE:
Changes original blockchain data.

MEMORY UPDATE:
Changes temporary copy only.

---------------------------------------------------------
VERY IMPORTANT
---------------------------------------------------------

This is one of the MOST IMPORTANT
concepts in Solidity security.

Many real-world bugs happen because:
developers confuse memory and storage.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Understanding reference behavior is critical for:

- DeFi protocols
- token accounting
- staking systems
- governance logic
- NFT marketplaces
- upgradeable contracts

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is storage reference intentional?
- Is memory copy expected?
- Are mutations happening correctly?
- Can accidental state mutation occur?
- Is protocol logic silently failing?

=========================================================
*/

contract StorageVsMemoryval {

    /*
        STRUCT STORED ON BLOCKCHAIN
    */
    struct User {

        uint256 score;

        bool active;
    }

    /*
        STORAGE MAPPING

        Persistent blockchain storage
    */
    mapping(address => User) public users;

    function createUser() public {

        users[msg.sender] = User({

            score: 100,

            active: true
        });
    }

    function updateUsingStorage() public {

        /*
            STORAGE REFERENCE

            user directly points to:
            users[msg.sender]
        */
        User storage user = users[msg.sender];

        /*
            MODIFY STORAGE DIRECTLY

            Changes persist permanently.
        */
        user.score = 999;
    }

    function updateUsingMemory() public view returns (
        uint256,
        bool
    ) {

        /*
            MEMORY COPY

            Creates independent temporary copy.
        */
        User memory user = users[msg.sender];

        /*
            MODIFY MEMORY COPY ONLY

            Original storage remains unchanged.
        */
        user.score = 555;

        user.active = false;

        /*
            Returning modified MEMORY values
        */
        return (
            user.score,
            user.active
        );
    }

    function getUser()
        public
        view
        returns (
            uint256,
            bool
        )
    {
        User storage user = users[msg.sender];

        return (
            user.score,
            user.active
        );
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
createUser()

STORAGE STATE:

{
    score: 100,
    active: true
}

---------------------------------------------------------

CALL:
updateUsingStorage()

EVM ACTIONS:

1. Storage reference created
2. user points directly to storage
3. user.score updated
4. Blockchain state modified permanently

---------------------------------------------------------

FINAL STORAGE STATE:

{
    score: 999,
    active: true
}

=========================================================

CALL:
updateUsingMemory()

EVM ACTIONS:

1. Storage struct copied into memory
2. user becomes temporary copy
3. Memory values modified
4. Storage remains untouched
5. Memory destroyed after execution

---------------------------------------------------------

MEMORY COPY:

{
    score: 555,
    active: false
}

---------------------------------------------------------

ACTUAL STORAGE STILL:

{
    score: 999,
    active: true
}

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createUser()

---------------------------------------------------------

STEP 3:
Call:
getUser()

EXPECTED:
100, true

---------------------------------------------------------

STEP 4:
Call:
updateUsingStorage()

---------------------------------------------------------

STEP 5:
Call:
getUser()

EXPECTED:
999, true

OBSERVE:
Storage permanently updated.

---------------------------------------------------------

STEP 6:
Call:
updateUsingMemory()

EXPECTED RETURN:
555, false

---------------------------------------------------------

STEP 7:
Call:
getUser()

EXPECTED:
999, true

OBSERVE:
Storage remained unchanged.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Call updateUsingMemory() repeatedly

EXPECTED:
Storage never changes

---------------------------------------------------------

TEST:
Call updateUsingStorage() multiple times

EXPECTED:
Storage updates persist

---------------------------------------------------------

TEST:
Use different Remix accounts

EXPECTED:
Each address has isolated storage

=========================================================
IMPORTANT REFERENCE UNDERSTANDING
=========================================================

---------------------------------------------------------
STORAGE REFERENCE
---------------------------------------------------------

User storage user = users[msg.sender];

Creates POINTER.

Changes affect original storage.

---------------------------------------------------------
MEMORY COPY
---------------------------------------------------------

User memory user = users[msg.sender];

Creates INDEPENDENT COPY.

Changes affect only memory.

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

MANY BUGS HAPPEN BECAUSE:

Developer expects:
storage update

But accidentally modifies:
memory copy

---------------------------------------------------------

RESULT:
Protocol logic silently fails.

=========================================================
GAS OBSERVATION
=========================================================

STORAGE WRITES:
Expensive

---------------------------------------------------------

MEMORY OPERATIONS:
Cheaper

---------------------------------------------------------

COPYING STORAGE TO MEMORY:
Still consumes gas

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

One of most common Solidity bug classes.

Auditors inspect:
- copy semantics
- reference behavior
- mutation expectations

---------------------------------------------------------
2. ACCIDENTAL STORAGE MUTATION
---------------------------------------------------------

Storage references may:
unexpectedly modify state.

---------------------------------------------------------
3. SILENT FAILURES
---------------------------------------------------------

Memory modifications may:
appear successful
but never persist.

---------------------------------------------------------
4. GAS RISKS
---------------------------------------------------------

Large copies from storage to memory
can become expensive.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Critical validation modifies memory copy
instead of storage.

Security state never updates.

Possible impact:
- bypassed restrictions
- broken accounting
- failed access control

---------------------------------------------------------

ANOTHER RISK

Unexpected storage references may:
modify balances unintentionally.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add memory array example
2. Add storage array example
3. Compare mutation behavior

BONUS:
Observe gas differences in Remix.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Storage creates direct reference
- Memory creates independent copy
- Storage updates persist permanently
- Memory updates disappear after execution
- Memory/storage confusion causes bugs
- Storage writes consume more gas
- Copying storage to memory costs gas
- Reference behavior critical in Solidity
- Many vulnerabilities come from wrong assumptions
- Auditors inspect mutation semantics carefully

=========================================================
*/
/*
Title: Understanding mutation differences between storage and memory data locations

Severity: Low

Reason: Developers may incorrectly assume memory arrays and storage behave identically during mutation operations

Location: 
Contract: StorageVsMemory
Functions:
updateUsingStorage()
updateUsingMemory()

Vulnerability Description: The contract demonstrates the difference between:

storage references
memory copies

Using:

User storage user = users[msg.sender];

creates a direct pointer to blockchain storage.

Changes persist permanently:

user.score = 999;

However:

User memory user = users[msg.sender];

creates an isolated temporary copy.

Changes affect only memory:

user.score = 555;

and do NOT mutate storage.

Impact: Misunderstanding storage vs memory behavior may cause
- unintended permanent state mutations
- incorrect business logic
- failed audit assumptions
- inefficient gas usage

Proof of Concept: Storage Mutation

Initial storage array:

[10, 20, 30]

Using:

uint256[] storage arr = numbers;

Then:

arr[0] = 999;

Storage becomes:

[999, 20, 30]

Permanent blockchain state change occurs. 

Root cause: Developers may confuse:
direct storage references
temporary memory copies

Recommendation:
Use:

memory

for:

temporary calculations
isolated processing
gas optimization

Use:

storage

only when permanent blockchain mutation is intended.

*/
//Patched code

contract StorageVsMemory {

    /*
        STRUCT STORED ON BLOCKCHAIN
    */
    struct User {

        uint256 score;

        bool active;
    }

    /*
        STORAGE MAPPING

        Persistent blockchain storage
    */
    mapping(address => User) public users;

    uint256[] public numbers;

    function createUser() public {

        users[msg.sender] = User({

            score: 100,

            active: true
        });
    }

    function updateUsingStorage() public {

        /*
            STORAGE REFERENCE

            user directly points to:
            users[msg.sender]
        */
        User storage user = users[msg.sender];

        /*
            MODIFY STORAGE DIRECTLY

            Changes persist permanently.
        */
        user.score = 999;
    }

    function updateUsingMemory() public view returns (
        uint256,
        bool
    ) {

        /*
            MEMORY COPY

            Creates independent temporary copy.
        */
        User memory user = users[msg.sender];

        /*
            MODIFY MEMORY COPY ONLY

            Original storage remains unchanged.
        */
        user.score = 555;

        user.active = false;

        /*
            Returning modified MEMORY values
        */
        return (
            user.score,
            user.active
        );
    }

// MEMORY ARRAY EXAMPLE
    function memoryArrayExample() public view returns(uint256[] memory, uint256[] memory)
    {
        uint256[] memory tempArray = numbers;

        if(tempArray.length > 0)
        {
            tempArray[0] = 555;
        }

        return(tempArray, numbers);
    }

// STORAGE ARRAY EXAMPLE
    function storageArrayExample() public 
    {
        uint256[] storage tempArray = numbers;

        if(tempArray.length > 0)
        {
            tempArray[0] = 999;
        }
    }

    function addNumber(uint256 _value) public 
    {
        numbers.push(_value);
    }
    
    function getUser()
        public
        view
        returns (
            uint256,
            bool
        )
    {
        User storage user = users[msg.sender];

        return (
            user.score,
            user.active
        );
    }
}