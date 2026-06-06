// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Handle success boolean properly
CONCEPT: Safe call handling
=========================================================

OBJECTIVE

- Learn proper low-level call() handling
- Understand safe external interaction logic
- Learn transaction rollback protection
- Prevent silent external-call failures

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Low-level call() returns:

(bool success, bytes memory data)

---------------------------------------------------------

SAFE handling requires:

require(success)

---------------------------------------------------------

Otherwise:
external call failures may be ignored.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

External calls are:
UNTRUSTED EXECUTION.

---------------------------------------------------------

Target contracts may:

- revert
- reject ETH
- consume gas
- behave maliciously

---------------------------------------------------------

Safe code ALWAYS checks:
success boolean.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Unchecked calls caused:

- accounting corruption
- lost funds
- broken withdrawals
- inconsistent state
- DOS vulnerabilities

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Safe call handling used in:

- DeFi protocols
- vaults
- token bridges
- DAO systems
- exchanges
- lending protocols

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- require(success)
- unchecked low-level calls
- rollback guarantees
- silent failure risks
- external interaction safety

=========================================================
TARGET CONTRACT
=========================================================
*/

contract CallTargetval {

    /*
        TRACK EXECUTIONS
    */
    uint256 public counter;

    /*
    =====================================================
    SUCCESS FUNCTION
    =====================================================
    */

    function successFunction()
        external
    {

        /*
            Increment counter.
        */
        counter++;
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

        /*
            Intentionally revert.
        */
        revert("Intentional failure");
    }

    /*
    =====================================================
    REJECT ETH
    =====================================================
    */

    receive()
        external
        payable
    {

        /*
            Reject ETH transfers.
        */
        revert("ETH rejected");
    }
}

/*
=========================================================
SAFE CALLER CONTRACT
=========================================================
*/

contract SafeCallHandlerval {

    /*
        TRACK RESULTS
    */
    bool public lastSuccess;

    bytes public lastData;

    uint256 public executionCounter;

    /*
    =====================================================
    SAFE FUNCTION CALL
    =====================================================
    */

    function safeFunctionCall(
        address _target
    )
        external
    {

        /*
            Local state update.
        */
        executionCounter++;

        /*
            Low-level external call.
        */
        (bool success, bytes memory data) =
            _target.call(
                abi.encodeWithSignature(
                    "successFunction()"
                )
            );

        /*
            Store results.
        */
        lastSuccess = success;

        lastData = data;

        /*
        =================================================
        SAFE HANDLING
        =================================================

        If external call failed:
        transaction fully reverts.
        */
        require(
            success,
            "External function call failed"
        );
    }

    /*
    =====================================================
    SAFE FAILING CALL
    =====================================================
    */

    function safeFailingCall(
        address _target
    )
        external
    {

        /*
            Local state update.
        */
        executionCounter++;

        /*
            External call that fails.
        */
        (bool success, bytes memory data) =
            _target.call(
                abi.encodeWithSignature(
                    "failFunction()"
                )
            );

        /*
            Save results.
        */
        lastSuccess = success;

        lastData = data;

        /*
            SAFE FAILURE HANDLING.

            Revert if call failed.
        */
        require(
            success,
            "External call reverted"
        );
    }

    /*
    =====================================================
    SAFE ETH TRANSFER
    =====================================================
    */

    function safeETHTransfer(
        address payable _target
    )
        external
        payable
    {

        /*
            Attempt ETH transfer.
        */
        (bool success, bytes memory data) =
            _target.call{
                value: msg.value
            }("");

        /*
            Store results.
        */
        lastSuccess = success;

        lastData = data;

        /*
            SAFE CHECK.

            Prevent silent ETH-transfer failure.
        */
        require(
            success,
            "ETH transfer failed"
        );
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy CallTarget

---------------------------------------------------------

STEP 2:
Deploy SafeCallHandler

=========================================================
TRACE:
safeFunctionCall()
=========================================================

STEP 1:
executionCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
STEP 2
=========================================================

Low-level call executes:

successFunction()

=========================================================
STEP 3
=========================================================

Target function succeeds.

---------------------------------------------------------

success = true

=========================================================
STEP 4
=========================================================

require(success)

---------------------------------------------------------

PASS

---------------------------------------------------------

Transaction succeeds safely.

=========================================================
FAILING CALL TRACE
=========================================================

CALL:
safeFailingCall()

=========================================================

STEP 1:
executionCounter++

---------------------------------------------------------

NEW VALUE:
2

=========================================================
STEP 2
=========================================================

External call executes:

failFunction()

=========================================================
STEP 3
=========================================================

Target contract reverts.

---------------------------------------------------------

success = false

=========================================================
STEP 4
=========================================================

require(success)

---------------------------------------------------------

FAILS

---------------------------------------------------------

TRANSACTION REVERTS

=========================================================
IMPORTANT ROLLBACK OBSERVATION
=========================================================

Even though:

executionCounter++

executed BEFORE call,

---------------------------------------------------------

ALL state changes rollback.

=========================================================
FINAL RESULT
=========================================================

executionCounter restored
to previous value.

=========================================================
WHY?
=========================================================

Ethereum transactions are:
ATOMIC.

---------------------------------------------------------

Either:
everything succeeds

OR

everything reverts.

=========================================================
ETH FAILURE TRACE
=========================================================

CALL:
safeETHTransfer()

VALUE:
1 ETH

=========================================================

STEP 1:
ETH sent to CallTarget.

=========================================================
STEP 2
=========================================================

receive() executes.

---------------------------------------------------------

receive() reverts intentionally.

=========================================================
STEP 3
=========================================================

call() returns:

success = false

=========================================================
STEP 4
=========================================================

require(success)

---------------------------------------------------------

Transaction fully reverts.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Safe external handling requires:

---------------------------------------------------------
CHECKING success
---------------------------------------------------------

on EVERY low-level call.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy CallTarget

---------------------------------------------------------

STEP 2:
Deploy SafeCallHandler

---------------------------------------------------------

STEP 3:
Call:
safeFunctionCall()

Input:
CallTarget address

---------------------------------------------------------

EXPECTED:
Success

=========================================================
STEP 4
=========================================================

Call:
safeFailingCall()

---------------------------------------------------------

EXPECTED:
Revert with:
"External call reverted"

=========================================================
STEP 5
=========================================================

Check:
executionCounter()

---------------------------------------------------------

EXPECTED:
unchanged due to rollback.

=========================================================
STEP 6
=========================================================

In VALUE field:
enter 1 ether

---------------------------------------------------------

STEP 7:
Call:
safeETHTransfer()

---------------------------------------------------------

EXPECTED:
Revert with:
"ETH transfer failed"

=========================================================
IMPORTANT LOW-LEVEL CALL UNDERSTANDING
=========================================================

call() NEVER auto-reverts.

---------------------------------------------------------

It only returns:

success = true/false

---------------------------------------------------------

Developer decides:
how to handle failure.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNCHECKED SUCCESS VALUES
---------------------------------------------------------

Classic Solidity vulnerability.

---------------------------------------------------------
2. SILENT FAILURES
---------------------------------------------------------

Execution continues incorrectly.

---------------------------------------------------------
3. ACCOUNTING CORRUPTION
---------------------------------------------------------

Internal state diverges from reality.

---------------------------------------------------------
4. DOS VIA REVERT
---------------------------------------------------------

Malicious contracts halt execution.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers intentionally:

- revert calls
- reject ETH
- break assumptions
- exploit unchecked failures

---------------------------------------------------------

Safe handling blocks these issues.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors search for:

---------------------------------------------------------
.call(
---------------------------------------------------------

without:

---------------------------------------------------------
require(success)
---------------------------------------------------------

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. External interactions
2. Failure paths
3. Return-value handling
4. Rollback guarantees
5. Silent-failure scenarios

=========================================================
BEST PRACTICE
=========================================================

ALWAYS:

---------------------------------------------------------
(bool success, ) = target.call(...)

require(success)
---------------------------------------------------------

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add try/catch
2. Decode revert messages
3. Emit failure events
4. Compare checked vs unchecked calls

BONUS:
Build ERC20 safe-transfer wrapper.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- call() returns success manually
- Low-level calls do not auto-revert
- require(success) ensures safe handling
- Reverts rollback all state changes
- Transactions are atomic
- External calls are untrusted
- Silent failures are dangerous
- Safe call handling prevents inconsistencies
- Auditors inspect low-level calls carefully
- Error handling is critical for Solidity security

=========================================================
*/

/*
Title: Insufficient External call error handling in SafeCallHandler

Severity: Medium

Reason: The contract user low-level external calls with require(success) bit lacks stuctured failure handling, revert-message decoding, and event-based monitiring

Location: Contract: SafeCallHandler
          Function: safeFunctionCall(address _target)
          Function: safeFailingCall(address _target)
          Function: safeETHTransfer(address payable _target)

Vulnerability Description: The contract performs low-level .call() operations and validates execution using
require(success, "External function call failed");
- Although this prevents silent failures, the implementation still has limitations
* Revert reason are not decoded
* No failure events are emitted
* No structured try/catch handling exists
* Debugging failed calls in difficult

Impact: Missing structured error handling may cause
- Difficult debugging
- Loss of detailed revert information
- Poor monitoring visbility
- Harder incident analysis
In complex systems this can affect
- Treasury interactions
- Governance execution
- Cross-contract integrations
- External protocol communication

Proof of Concept:
1. Deploy CallTarget
2. Deplay safecallHandler
3. Call: safeFailingCall(targetAddress)
4. Target executes: revert("Intentional failure");
5. .call() returns: success = false
6. Contract reverts with only: External call reverted
7. Original revert reason is lost

Root Cause:The issue exists because:
- Low-level calls return raw bytes
- Revert data is ignored
- No revert decoding logic exists
- No structured error handling is implemented
Low-level .call() does not automatically propagate revert strings

Recommendation:
1. Decode revert messages from returned data
2. Emit detailed failure events
3. use try/catch for interface-based calls
4. Log success and failure outcomes
5. Perfer interface calls when possible.

*/

// PATCHED CODE

// INTERFACE
interface ICallTarget
{
    function successFunction() external;

    function failFunction() external;
}

contract CallTarget {

    /*
        TRACK EXECUTIONS
    */
    uint256 public counter;

    // EVENTS

    event SuccessExecuted(address caller);

    event FailureTriggered(address caller, string reason);

    /*
    =====================================================
    SUCCESS FUNCTION
    =====================================================
    */

    function successFunction()
        external
    {

        /*
            Increment counter.
        */
        counter++;

        emit SuccessExecuted(msg.sender);
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

        /*
            Intentionally revert.
        */
        revert("Intentional failure");
    }

    /*
    =====================================================
    REJECT ETH
    =====================================================
    */

    receive()
        external
        payable
    {

        /*
            Reject ETH transfers.
        */
        revert("ETH rejected");
    }
}

/*
=========================================================
SAFE CALLER CONTRACT
=========================================================
*/

contract SafeCallHandler {

    /*
        TRACK RESULTS
    */
    bool public lastSuccess;

    bytes public lastData;

    uint256 public executionCounter;

    string public lastReverReason;

    // EVENTS
    event FunctionCallResult(bool success, bytes data);

    event FailureReason(string reason);

    event TryCatchFailure(string reason);

    event TryCatchSuccess(string message);

    /*
    =====================================================
    SAFE FUNCTION CALL
    =====================================================
    */

    function safeFunctionCall(
        address _target
    )
        external
    {

        /*
            Local state update.
        */
        executionCounter++;

        /*
            Low-level external call.
        */
        (bool success, bytes memory data) =
            _target.call(
                abi.encodeWithSignature(
                    "successFunction()"
                )
            );

        /*
            Store results.
        */
        lastSuccess = success;

        lastData = data;

        emit FunctionCallResult(success, data);

        // DECODE FAILURE REASON
        if (!success)
        {
            string memory reason = decodeRevertMessage(data);

            lastReverReason = reason;

            emit FailureReason(reason);
        }
        /*
        =================================================
        SAFE HANDLING
        =================================================

        If external call failed:
        transaction fully reverts.
        */
        require(
            success,
            "External function call failed"
        );
    }

    /*
    =====================================================
    SAFE FAILING CALL
    =====================================================
    */

    function safeFailingCall(
        address _target
    )
        external
    {

        /*
            Local state update.
        */
        executionCounter++;

        /*
            External call that fails.
        */
        (bool success, bytes memory data) =
            _target.call(
                abi.encodeWithSignature(
                    "failFunction()"
                )
            );

        /*
            Save results.
        */
        lastSuccess = success;

        lastData = data;

        emit FunctionCallResult(success, data);

        // DECODE REVERT MESSAGE
        if(!success)
        {
            string memory reason = decodeRevertMessage(data);

            lastReverReason = reason;

            emit FailureReason(reason);
        }

        require(
            success,
            "External call reverted"
        );
    }

    /*
    =====================================================
    SAFE ETH TRANSFER
    =====================================================
    */

    function safeETHTransfer(
        address payable _target
    )
        external
        payable
    {

        /*
            Attempt ETH transfer.
        */
        (bool success, bytes memory data) =
            _target.call{
                value: msg.value
            }("");

        /*
            Store results.
        */
        lastSuccess = success;

        lastData = data;

        emit FunctionCallResult(success, data);

        // DECODE REVERT REASON
        if(!success)
        {
            string memory reason = decodeRevertMessage(data);

            lastReverReason = reason;

            emit FailureReason(reason);
        }

        
        require(
            success,
            "ETH transfer failed"
        );
    }

    // TRY/CATCH EXAMPLE
    function tryCatchExample(address _target) external 
    {
        ICallTarget target = ICallTarget(_target);

        // SUCCESSFUL CALL
        try target.successFunction()
        {
            emit TryCatchSuccess("Success function executed");
        }
        catch Error(string memory reason)
        {
            emit TryCatchFailure(reason);
        }

        // FAILING CALL
        try target.failFunction()
        {

        }
        catch Error(string memory reason)
        {
            lastReverReason = reason;

            emit TryCatchFailure(reason);
        }
    }

    // DECODE REVERT MESSAGE
    function decodeRevertMessage(bytes memory _data) internal pure returns (string memory)
    {
        // UNKNOW REVERT
        if(_data.length < 68)
        {
            return "Unknown revert";
        }

        assembly
        {
            // SKIP SELECTOR
            _data := add(_data, 0x04)
        }

        return abi.decode(_data, (string));
    }
}
