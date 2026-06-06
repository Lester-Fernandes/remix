// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call contract from contract
CONCEPT: Nested execution
=========================================================

OBJECTIVE

- Learn how one contract calls another
- Understand nested execution flow
- Learn msg.sender behavior across contracts
- Understand inter-contract trust assumptions

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Contracts can directly interact
with other deployed contracts.

---------------------------------------------------------

Execution may flow like:

User
   ->
Contract A
   ->
Contract B

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

During nested calls:

msg.sender changes.

---------------------------------------------------------

Inside Contract B:

msg.sender =
Contract A

NOT original user.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Modern Solidity systems are:

multi-contract architectures.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Nested calls appear in:

- ERC20 token interactions
- routers
- lending protocols
- staking systems
- NFT marketplaces
- bridges

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- execution flow
- msg.sender transitions
- trust assumptions
- nested state changes
- reentrancy windows

=========================================================
TARGET CONTRACT
=========================================================
*/

// contract DataStorageval {

//     /*
//         STORED VALUE
//     */
//     uint256 public storedNumber;

//     /*
//         TRACK LAST CALLER
//     */
//     address public lastCaller;

//     /*
//     =====================================================
//     STORE NUMBER
//     =====================================================
//     */

//     function setNumber(
//         uint256 _number
//     )
//         external
//     {

//         /*
//             Save input.
//         */
//         storedNumber = _number;

//         /*
//             Store msg.sender.

//             IMPORTANT:
//             This will become
//             calling contract address
//             during nested execution.
//         */
//         lastCaller = msg.sender;
//     }

//     /*
//     =====================================================
//     READ VALUE
//     =====================================================
//     */

//     function getNumber()
//         external
//         view
//         returns (uint256)
//     {

//         return storedNumber;
//     }
// }

// /*
// =========================================================
// CALLER CONTRACT
// =========================================================
// */

// contract NestedCallerval {

//     /*
//         TARGET CONTRACT
//     */
//     DataStorage public target;

//     /*
//         TRACK LOCAL EXECUTION
//     */
//     uint256 public localCounter;

//     /*
//         STORE LAST READ VALUE
//     */
//     uint256 public lastReadValue;

//     /*
//         CONSTRUCTOR
//     */
//     constructor(address _target)
//     {

//         /*
//             Save target contract reference.
//         */
//         target = DataStorage(_target);
//     }

//     /*
//     =====================================================
//     CALL TARGET CONTRACT
//     =====================================================
//     */

//     function callSetNumber(
//         uint256 _number
//     )
//         external
//     {

//         /*
//             Local state update.
//         */
//         localCounter++;

//         /*
//             EXTERNAL CONTRACT CALL

//             Execution jumps into:
//             DataStorage.setNumber()
//         */
//         target.setNumber(_number);
//     }

//     /*
//     =====================================================
//     READ FROM TARGET CONTRACT
//     =====================================================
//     */

//     function readTargetNumber()
//         external
//     {

//         /*
//             Nested external read.
//         */
//         uint256 value =
//             target.getNumber();

//         /*
//             Save locally.
//         */
//         lastReadValue = value;
//     }
// }

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy DataStorage

---------------------------------------------------------

STEP 2:
Deploy NestedCaller

Constructor input:
DataStorage address

=========================================================
TRACE:
callSetNumber(100)
=========================================================

STEP 1:
User calls:

NestedCaller.callSetNumber(100)

=========================================================
STEP 2
=========================================================

NestedCaller executes:

localCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
STEP 3
=========================================================

External contract call:

target.setNumber(100)

---------------------------------------------------------

Execution CONTEXT switches.

=========================================================
STEP 4
=========================================================

Execution enters:
DataStorage contract

---------------------------------------------------------

storedNumber = 100

=========================================================
STEP 5
=========================================================

IMPORTANT:

Inside DataStorage:

msg.sender =
NestedCaller contract

---------------------------------------------------------

NOT original user.

=========================================================
STEP 6
=========================================================

lastCaller =
NestedCaller address

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
NestedCaller.localCounter
---------------------------------------------------------

1

---------------------------------------------------------
DataStorage.storedNumber
---------------------------------------------------------

100

---------------------------------------------------------
DataStorage.lastCaller
---------------------------------------------------------

NestedCaller address

=========================================================
IMPORTANT msg.sender UNDERSTANDING
=========================================================

FLOW:

User
   ->
NestedCaller
   ->
DataStorage

---------------------------------------------------------

Inside DataStorage:

msg.sender =
NestedCaller

=========================================================
WHY THIS IS IMPORTANT
=========================================================

Authentication logic may fail
if developer assumes:

msg.sender == original user

=========================================================
READ TRACE
=========================================================

CALL:
readTargetNumber()

=========================================================

STEP 1:
NestedCaller calls:

target.getNumber()

=========================================================
STEP 2
=========================================================

Execution enters:
DataStorage

---------------------------------------------------------

storedNumber returned.

=========================================================
STEP 3
=========================================================

Returned value saved:

lastReadValue = storedNumber

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy DataStorage

---------------------------------------------------------

STEP 2:
Deploy NestedCaller

Input:
DataStorage address

---------------------------------------------------------

STEP 3:
Call:
callSetNumber(100)

---------------------------------------------------------

STEP 4:
Open DataStorage

---------------------------------------------------------

STEP 5:
Call:
storedNumber()

EXPECTED:
100

---------------------------------------------------------

STEP 6:
Call:
lastCaller()

EXPECTED:
NestedCaller contract address

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

Nested execution changes:

---------------------------------------------------------
CONTROL FLOW
---------------------------------------------------------

and

---------------------------------------------------------
AUTHENTICATION CONTEXT
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. msg.sender CONFUSION
---------------------------------------------------------

Authentication bypass possible.

---------------------------------------------------------
2. TRUST ASSUMPTIONS
---------------------------------------------------------

External contracts may behave maliciously.

---------------------------------------------------------
3. REENTRANCY
---------------------------------------------------------

Nested calls create callback opportunities.

---------------------------------------------------------
4. FAILURE PROPAGATION
---------------------------------------------------------

Nested revert breaks entire transaction.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers exploit:

- msg.sender assumptions
- nested callback logic
- external state assumptions
- recursive execution

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors trace:

- external jumps
- msg.sender changes
- storage mutations
- nested execution paths
- trust boundaries

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors build:

---------------------------------------------------------
EXECUTION GRAPH
---------------------------------------------------------

to understand:

- control flow
- state dependencies
- attack surface

=========================================================
WHY NESTED EXECUTION IS RISKY
=========================================================

More contracts =
more assumptions.

---------------------------------------------------------

More assumptions =
larger attack surface.

=========================================================
MINI CHALLENGE
=========================================================

Modify contracts so that:

1. Add ETH transfers
2. Add low-level call()
3. Add failing nested call
4. Add malicious callback contract

BONUS:
Build mini router contract.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Contracts can call other contracts
- Nested execution changes msg.sender
- Execution context switches externally
- Nested calls increase complexity
- External calls create attack surface
- Authentication assumptions are dangerous
- Reverts propagate across nested calls
- Auditors trace execution flow carefully
- Multi-contract systems are harder to secure
- Inter-contract trust assumptions are critical

=========================================================
*/
/*
Title: Unsafe Low-Level External Calls and Potential Callback Exploitation

Severity: High

Reason: The contracts use low-level external calls and nested execution flows without implementing reentrancy protection or strict access control mechanisms

Location: Contracts Affected: DataStorage
                              NestedCaller
                              MaliciousCallback

          Vulnerable Function: sendETH()
                               lowLevelCall()
                               failingCall()
                               attack()
                               receive()

Vulnerability Description: The system demonstrates nested external contract interactions using
- Direct external calls
- low-level call()
- ETH transfers
- callback execution
The NestedCaller contract performs low-level external calls to DataStorage using
address(target).call(...)
* Low-level calls are dangerous because:
- they bypass type safety,
- execution control leaves the contract,
- malicious callbacks may execute,
- manual success validation is required.

Impact: An attacker may
- trigger recursive external execution,
- manipulate nested call flow,
- abuse low-level calls,
- exploit callback execution,
- force unexpected state transitions.

Potential consequences include:

- Denial of Service (DoS),
- gas exhaustion,
- recursive execution loops,
- unsafe ETH transfer behavior,
- unexpected contract interactions.

Proof of Concept:
Step 1 — Deploy Contracts

Deploy in this order:

1. DataStorage
2. NestedCaller
3. MaliciousCallback

Step 2 — Start Attack

Call:

attack()

from MaliciousCallback.

Step 3 — Nested Execution Begins

Execution flow:

MaliciousCallback.attack()
        ↓
NestedCaller.lowLevelCall()
        ↓
DataStorage.setNumber()

Step 4 — Callback Triggered

If ETH transfers occur during execution, the malicious contract’s receive() function executes recursively:

receive() external payable

This creates repeated nested external calls.

Root Cause: The vulnerabilities exist because:
- low-level call() transfers execution control externally
- callback execution is unrestricted
- no nonReentrant protection exists
- no access control is implemented
- nested external execution is trusted implicitly

*/

// PATCHED CODE

/*
=========================================================
DATA STORAGE CONTRACT
=========================================================
*/

contract DataStorage {

    /*
        STORED VALUE
    */
    uint256 public storedNumber;

    /*
        TRACK LAST CALLER
    */
    address public lastCaller;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event NumberStored(
        address caller,
        uint256 number
    );

    event ETHReceived(
        address sender,
        uint256 amount
    );

    /*
    =====================================================
    RECEIVE ETH
    =====================================================
    */

    receive()
        external
        payable
    {
        emit ETHReceived(
            msg.sender,
            msg.value
        );
    }

    /*
    =====================================================
    STORE NUMBER
    =====================================================
    */

    function setNumber(
        uint256 _number
    )
        external
    {
        storedNumber = _number;

        lastCaller = msg.sender;

        emit NumberStored(
            msg.sender,
            _number
        );
    }

    /*
    =====================================================
    FAILING FUNCTION
    =====================================================
    */

    function failFunction()
        external
        pure
    {
        revert("Intentional failure");
    }

    /*
    =====================================================
    SEND ETH
    =====================================================
    */

    function sendETH(
        address payable _to
    )
        external
        payable
    {
        (bool success, ) =
            _to.call{
                value: msg.value
            }("");

        require(
            success,
            "ETH transfer failed"
        );
    }
}

/*
=========================================================
NESTED CALLER CONTRACT
=========================================================
*/

contract NestedCaller {

    /*
        TARGET CONTRACT
    */
    DataStorage public target;

    /*
        TRACK EXECUTION
    */
    uint256 public localCounter;

    /*
        STORE CALL RESULT
    */
    bool public lastSuccess;

    bytes public lastData;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event LowLevelResult(
        bool success
    );

    event Failure(
        string reason
    );

    /*
    =====================================================
    CONSTRUCTOR
    =====================================================
    */

    constructor(
        address payable _target
    ) {

        target =
            DataStorage(_target);
    }

    /*
    =====================================================
    NORMAL CALL
    =====================================================
    */

    function callSetNumber(
        uint256 _number
    )
        external
    {
        localCounter++;

        target.setNumber(
            _number
        );
    }

    /*
    =====================================================
    LOW LEVEL CALL
    =====================================================
    */

    function lowLevelCall(
        uint256 _number
    )
        external
    {
        (
            bool success,
            bytes memory data
        ) =
            address(target).call(
                abi.encodeWithSignature(
                    "setNumber(uint256)",
                    _number
                )
            );

        lastSuccess = success;

        lastData = data;

        emit LowLevelResult(
            success
        );

        require(
            success,
            "Low-level call failed"
        );
    }

    /*
    =====================================================
    FAILING CALL
    =====================================================
    */

    function failingCall()
        external
    {
        (
            bool success,
            bytes memory data
        ) =
            address(target).call(
                abi.encodeWithSignature(
                    "failFunction()"
                )
            );

        lastSuccess = success;

        lastData = data;

        emit LowLevelResult(
            success
        );

        if (!success) {

            emit Failure(
                decodeRevert(data)
            );
        }
    }

    /*
    =====================================================
    TRY/CATCH EXAMPLE
    =====================================================
    */

    function tryCatchExample()
        external
    {
        try target.failFunction() {

        } catch Error(
            string memory reason
        ) {

            emit Failure(
                reason
            );
        }
    }

    /*
    =====================================================
    DECODE REVERT MESSAGE
    =====================================================
    */

    function decodeRevert(
        bytes memory _data
    )
        internal
        pure
        returns (string memory)
    {
        if (_data.length < 68) {

            return "Unknown revert";
        }

        assembly {

            _data := add(_data, 0x04)
        }

        return abi.decode(
            _data,
            (string)
        );
    }

    /*
    =====================================================
    RECEIVE ETH
    =====================================================
    */

    receive()
        external
        payable
    {

    }
}

/*
=========================================================
MALICIOUS CALLBACK CONTRACT
=========================================================
*/

contract MaliciousCallback {

    /*
        TARGET CONTRACT
    */
    NestedCaller public target;

    /*
        TRACK ATTACKS
    */
    uint256 public attackCounter;

    /*
    =====================================================
    CONSTRUCTOR
    =====================================================
    */

    constructor(
        address payable _target
    ) {

        target =
            NestedCaller(_target);
    }

    /*
    =====================================================
    START ATTACK
    =====================================================
    */

    function attack()
        external
    {
        target.lowLevelCall(
            999
        );
    }

    /*
    =====================================================
    CALLBACK FUNCTION
    =====================================================
    */

    receive()
        external
        payable
    {
        if (attackCounter < 2) {

            attackCounter++;

            try target.lowLevelCall(
                attackCounter
            ) {

            } catch {

            }
        }
    }
}