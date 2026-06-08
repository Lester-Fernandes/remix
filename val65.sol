// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Trace external call execution
CONCEPT: Control transfer awareness
=========================================================

OBJECTIVE

- Learn how execution control moves externally
- Understand execution-context switching
- Trace msg.sender across contracts
- Think like auditor during external interactions

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

When Contract A calls Contract B:

execution control LEAVES A
and ENTERS B.

---------------------------------------------------------

This is one of the MOST IMPORTANT
security concepts in Solidity.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

External calls are NOT normal jumps.

---------------------------------------------------------

Execution temporarily transfers to:

UNTRUSTED CODE.

---------------------------------------------------------

The called contract controls execution flow
until it returns or reverts.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most Solidity vulnerabilities involve:

- external execution
- reentrancy
- callback attacks
- malicious contracts
- trust assumptions

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

External calls exist in:

- token transfers
- swaps
- lending protocols
- NFT marketplaces
- staking systems
- bridges

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors trace:

- execution switching
- msg.sender transitions
- state before/after calls
- reentrancy windows
- callback opportunities

=========================================================
TARGET CONTRACT
=========================================================
*/

contract ExternalTargetval {

    /*
        STORE LAST CALLER
    */
    address public lastCaller;

    /*
        TRACK EXECUTIONS
    */
    uint256 public executionCounter;

    /*
    =====================================================
    TARGET FUNCTION
    =====================================================
    */

    function targetFunction()
        external
    {

        /*
        =================================================
        EXECUTION CONTEXT NOW INSIDE TARGET CONTRACT
        =================================================

        msg.sender becomes:
        calling contract address.
        */

        lastCaller = msg.sender;

        /*
            Increment execution count.
        */
        executionCounter++;
    }
}

/*
=========================================================
CALLER CONTRACT
=========================================================
*/

contract ExecutionTracerval {

    /*
        TARGET CONTRACT REFERENCE
    */
    ExternalTarget public target;

    /*
        LOCAL EXECUTION TRACKING
    */
    uint256 public localCounter;

    /*
        TRACK EXECUTION STEPS
    */
    string public executionStage;

    /*
        TRACK LAST msg.sender
    */
    address public lastObservedSender;

    /*
        CONSTRUCTOR
    */
    constructor(address payable _target)
    {

        /*
            Save target contract.
        */
        target = ExternalTarget(_target);
    }

    /*
    =====================================================
    TRACE EXTERNAL EXECUTION
    =====================================================
    */

    function traceExecution()
        external
    {

        /*
        =================================================
        STEP 1
        =================================================

        Execution currently inside:
        ExecutionTracer contract.
        */

        executionStage =
            "Before external call";

        /*
            msg.sender here:
            ORIGINAL USER.
        */
        lastObservedSender =
            msg.sender;

        /*
            Local state update.
        */
        localCounter++;

        /*
        =================================================
        STEP 2
        =================================================

        EXTERNAL CALL HAPPENS HERE.

        CONTROL LEAVES:
        ExecutionTracer

        CONTROL ENTERS:
        ExternalTarget
        */

        target.targetFunction();

        /*
        =================================================
        STEP 3
        =================================================

        External execution finished.

        CONTROL RETURNS:
        back to ExecutionTracer.
        */

        executionStage =
            "After external call";
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy ExternalTarget

---------------------------------------------------------

STEP 2:
Deploy ExecutionTracer

Constructor input:
ExternalTarget address

=========================================================
TRACE:
traceExecution()
=========================================================

STEP 1:
User calls:

traceExecution()

=========================================================
STEP 2
=========================================================

Execution enters:
ExecutionTracer

---------------------------------------------------------

Current contract:
ExecutionTracer

---------------------------------------------------------

msg.sender:
ORIGINAL USER

=========================================================
STEP 3
=========================================================

executionStage =
"Before external call"

---------------------------------------------------------

localCounter++

=========================================================
STEP 4
=========================================================

CRITICAL MOMENT:

target.targetFunction()

=========================================================
IMPORTANT
=========================================================

CONTROL LEAVES:
ExecutionTracer

---------------------------------------------------------

Execution CONTEXT switches externally.

=========================================================
STEP 5
=========================================================

Execution enters:
ExternalTarget

---------------------------------------------------------

Current contract:
ExternalTarget

=========================================================
IMPORTANT msg.sender CHANGE
=========================================================

Inside ExternalTarget:

msg.sender =
ExecutionTracer contract

---------------------------------------------------------

NOT original user.

=========================================================
STEP 6
=========================================================

ExternalTarget executes:

---------------------------------------------------------

lastCaller = ExecutionTracer

---------------------------------------------------------

executionCounter++

=========================================================
STEP 7
=========================================================

ExternalTarget finishes execution.

---------------------------------------------------------

CONTROL RETURNS:
ExecutionTracer

=========================================================
STEP 8
=========================================================

Execution continues AFTER external call.

---------------------------------------------------------

executionStage =
"After external call"

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
ExecutionTracer.localCounter
---------------------------------------------------------

1

---------------------------------------------------------
ExternalTarget.executionCounter
---------------------------------------------------------

1

---------------------------------------------------------
ExternalTarget.lastCaller
---------------------------------------------------------

ExecutionTracer address

=========================================================
CRITICAL SECURITY UNDERSTANDING
=========================================================

During external call:

---------------------------------------------------------
YOUR CONTRACT STOPS EXECUTING
---------------------------------------------------------

and

---------------------------------------------------------
ANOTHER CONTRACT TAKES CONTROL
---------------------------------------------------------

=========================================================
THIS IS DANGEROUS BECAUSE
=========================================================

External contract may:

- revert
- reenter
- consume gas
- manipulate execution
- attack assumptions

=========================================================
VERY IMPORTANT AUDITOR MINDSET
=========================================================

Every external call means:

---------------------------------------------------------
TRUSTING UNKNOWN EXECUTION
---------------------------------------------------------

=========================================================
CONTROL TRANSFER VISUALIZATION
=========================================================

User
  |
  v
ExecutionTracer
  |
  | external call
  v
ExternalTarget
  |
  | return
  v
ExecutionTracer resumes

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy ExternalTarget

---------------------------------------------------------

STEP 2:
Deploy ExecutionTracer

Input:
ExternalTarget address

---------------------------------------------------------

STEP 3:
Call:
traceExecution()

=========================================================
STEP 4
=========================================================

Check:
executionStage()

EXPECTED:
"After external call"

=========================================================
STEP 5
=========================================================

Check:
localCounter()

EXPECTED:
1

=========================================================
STEP 6
=========================================================

Open ExternalTarget

---------------------------------------------------------

Check:
executionCounter()

EXPECTED:
1

---------------------------------------------------------

Check:
lastCaller()

EXPECTED:
ExecutionTracer address

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

External calls create:

---------------------------------------------------------
EXECUTION BOUNDARIES
---------------------------------------------------------

and

---------------------------------------------------------
TRUST BOUNDARIES
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

External contract calls back unexpectedly.

---------------------------------------------------------
2. msg.sender CONFUSION
---------------------------------------------------------

Authentication assumptions fail.

---------------------------------------------------------
3. FAILURE PROPAGATION
---------------------------------------------------------

External revert breaks execution.

---------------------------------------------------------
4. MALICIOUS CALLBACKS
---------------------------------------------------------

Execution flow manipulated externally.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers abuse:

- external execution windows
- callback opportunities
- temporary state exposure
- trust assumptions

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Every external jump
2. Control-transfer timing
3. State before call
4. State after call
5. Reentrancy possibilities

=========================================================
WHY CONTROL TRANSFER IS CRITICAL
=========================================================

Most major Solidity exploits happen
during external execution.

---------------------------------------------------------

Understanding control transfer
is foundational for auditing.

=========================================================
MINI CHALLENGE
=========================================================

Modify contracts so that:

1. Add ETH transfer
2. Add malicious callback
3. Add reentrancy attack
4. Add nested external chain

BONUS:
Trace execution using Remix debugger.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- External calls transfer execution control
- msg.sender changes during nested calls
- Contracts temporarily stop execution
- External contracts are untrusted
- Control eventually returns after execution
- Reentrancy occurs during external execution
- Auditors trace every external jump
- Execution context changes externally
- External calls create attack surface
- Control-transfer awareness is critical for auditing

=========================================================
*/
/*
Title: Reentrancy risk and unsafe nested external excution

Severity: High

Reason: The contracts implement nested external calls, ETH transfer, low-level calls, and malicious callback execution which may expose the system
        to reentrancy and unsafe execution flow vulnerabilities

Location: Contracts Affected: ExecutionTracer
                              ExternalTarget
                              MaliciousCallback

          Vulnerable Functions: traceExexution()
                                lowLevelTrace()
                                sendETH()
                                receive()

Vulnerability Description: The contracts demonstrate
- external contract interaction
- low-level call execution
- ETH transfer handling
- malicious callback behavior
- nested execution chains

The ExcutionTracer contract transfers execution control externally into ExternalTarget

Additionally the MaliciousCallback contract recursively interacts with the target contract through its receive() function

Without proper reentrancy protection, malicious fallback execution may repeatedly trigger nested external calls

Impact: An attacker may
- trigger recursive execution
- exploit fallback callbacks
- manipulate execution flow
- exhaust gas through repeated calls
- abuse low-level call execution
Potential consequences include
- denial of service
- recursive call attacks
- inconsistent execution flow
- unexpected external interaction

Proof of Concept:
1. ExternalTarget
2. ExecutionTracer
3. MaliciousCallback

Step 2 — Start Attack

Call:

attack()

from MaliciousCallback.

Step 3 — Nested External Chain Executes

Execution flow:

MaliciousCallback.attack()
        ↓
ExecutionTracer.traceExecution()
        ↓
ExternalTarget.targetFunction()

Step 4 — Callback Execution

The malicious contract receive() function executes and repeatedly attempts nested calls:

try target.lowLevelTrace()

Root Cause: The vulnerabilities exist because:
- external calls transfer execution control
- low-level calls bypass safety checks
- callback execution is unrestricted
- nested execution chains are trusted implicitly


*/

// PATCHED CODE

/*
=========================================================
EXTERNAL TARGET CONTRACT
=========================================================
*/

contract ExternalTarget {

    /*
        STORE LAST CALLER
    */
    address public lastCaller;

    /*
        TRACK EXECUTIONS
    */
    uint256 public executionCounter;

    /*
        TRACK ETH RECEIVED
    */
    uint256 public totalETHReceived;

    /*
        STORE EXECUTION STAGE
    */
    string public currentStage;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event TargetExecuted(
        address caller,
        uint256 value
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
        totalETHReceived += msg.value;

        emit ETHReceived(
            msg.sender,
            msg.value
        );
    }

    /*
    =====================================================
    TARGET FUNCTION
    =====================================================
    */

    function targetFunction()
        external
        payable
    {

        currentStage =
            "Inside Target";

        lastCaller = msg.sender;

        executionCounter++;

        emit TargetExecuted(
            msg.sender,
            msg.value
        );
    }

    /*
    =====================================================
    FAIL FUNCTION
    =====================================================
    */

    function failFunction()
        external
        pure
    {
        revert("Target failure");
    }
}

/*
=========================================================
CALLER CONTRACT
=========================================================
*/

contract ExecutionTracer {

    /*
        TARGET CONTRACT
    */
    ExternalTarget public target;

    /*
        TRACK EXECUTION
    */
    uint256 public localCounter;

    /*
        EXECUTION STAGE
    */
    string public executionStage;

    /*
        LAST OBSERVED SENDER
    */
    address public lastObservedSender;

    /*
        REENTRANCY LOCK
    */
    bool internal locked;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event ExecutionStarted(
        address caller
    );

    event ExecutionFinished(
        address caller
    );

    event LowLevelResult(
        bool success
    );

    event ETHTransfer(
        address receiver,
        uint256 amount
    );

    /*
    =====================================================
    NON REENTRANT
    =====================================================
    */

    modifier nonReentrant()
    {
        require(
            !locked,
            "Reentrancy blocked"
        );

        locked = true;

        _;

        locked = false;
    }

    /*
    =====================================================
    CONSTRUCTOR
    =====================================================
    */

    constructor(
        address payable _target
    )
    {
        target =
            ExternalTarget(_target);
    }

    /*
    =====================================================
    TRACE EXECUTION
    =====================================================
    */

    function traceExecution()
        external
        payable
        nonReentrant
    {

        executionStage =
            "Before external call";

        lastObservedSender =
            msg.sender;

        localCounter++;

        emit ExecutionStarted(
            msg.sender
        );

        /*
            NORMAL EXTERNAL CALL
        */
        target.targetFunction{
            value: msg.value
        }();

        executionStage =
            "After external call";

        emit ExecutionFinished(
            msg.sender
        );
    }

    /*
    =====================================================
    LOW LEVEL CALL
    =====================================================
    */

    function lowLevelTrace()
        external
    {

        (
            bool success,
            bytes memory data
        ) =
            address(target).call(
                abi.encodeWithSignature(
                    "targetFunction()"
                )
            );

        data;

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

    function failingTrace()
        external
    {

        try target.failFunction() {

        } catch {

            executionStage =
                "Failure handled";
        }
    }

    /*
    =====================================================
    SEND ETH
    =====================================================
    */

    function sendETH(
        address payable _receiver
    )
        external
        payable
    {

        (bool success, ) =
            _receiver.call{
                value: msg.value
            }("");

        require(
            success,
            "ETH transfer failed"
        );

        emit ETHTransfer(
            _receiver,
            msg.value
        );
    }

    /*
    =====================================================
    CONTRACT BALANCE
    =====================================================
    */

    function contractBalance()
        external
        view
        returns(uint256)
    {
        return address(this).balance;
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
    ExecutionTracer public target;

    /*
        TRACK ATTACKS
    */
    uint256 public attackCounter;

    /*
        LIMIT ATTACKS
    */
    uint256 constant MAX_ATTACKS = 3;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event AttackTriggered(
        uint256 counter
    );

    /*
    =====================================================
    CONSTRUCTOR
    =====================================================
    */

    constructor(
        address payable _target
    )
    {
        target =
            ExecutionTracer(_target);
    }

    /*
    =====================================================
    START ATTACK
    =====================================================
    */

    function attack()
        external
        payable
    {

        target.traceExecution{
            value: msg.value
        }();
    }

    /*
    =====================================================
    REENTRANCY CALLBACK
    =====================================================
    */

    receive()
        external
        payable
    {

        if (
            attackCounter <
            MAX_ATTACKS
        ) {

            attackCounter++;

            emit AttackTriggered(
                attackCounter
            );

            /*
                Attempt reentrancy
            */
            try target.lowLevelTrace() {

            } catch {

            }
        }
    }
}