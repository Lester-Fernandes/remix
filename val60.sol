// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Ignore success boolean from call
CONCEPT: Dangerous coding
=========================================================

OBJECTIVE

- Learn why unchecked call() is dangerous
- Understand silent external-call failures
- Learn inconsistent state vulnerabilities
- Think like professional auditor

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Low-level call() returns:

(bool success, bytes memory data)

---------------------------------------------------------

If success is ignored:

execution may continue
even when external call FAILED.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

This creates:
silent failure vulnerabilities.

---------------------------------------------------------

Protocol may assume:
external interaction succeeded.

---------------------------------------------------------

Reality:
it failed completely.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Unchecked external calls caused:

- stuck funds
- accounting corruption
- broken logic
- DOS vulnerabilities
- protocol inconsistencies

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

External calls exist in:

- token transfers
- swaps
- governance execution
- vault withdrawals
- bridges
- staking systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors ALWAYS inspect:

- ignored success booleans
- unchecked external calls
- silent failures
- accounting assumptions
- inconsistent state

=========================================================
MALICIOUS / FAILING CONTRACT
=========================================================
*/

contract RejectETHval {

    /*
        Track calls
    */
    uint256 public counter;

    /*
    =====================================================
    ALWAYS REVERT ON ETH
    =====================================================
    */

    receive()
        external
        payable
    {

        revert("ETH rejected");
    }

    /*
    =====================================================
    ALWAYS FAIL FUNCTION
    =====================================================
    */

    function failFunction()
        external
        pure
    {

        revert("Function failed");
    }

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
}

/*
=========================================================
VULNERABLE CONTRACT
=========================================================
*/

contract DangerousUncheckedCallval {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        TRACK WITHDRAWALS
    */
    mapping(address => bool) public withdrawn;

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================
    */

    function deposit()
        external
        payable
    {

        balances[msg.sender] += msg.value;
    }

    /*
    =====================================================
    DANGEROUS WITHDRAW
    =====================================================

    PROBLEM:
    ignores success boolean.
    */

    function dangerousWithdraw(
        address payable _receiver,
        uint256 _amount
    )
        external
    {

        /*
            Validate balance.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            EFFECTS:
            Update storage FIRST.
        */
        balances[msg.sender] -= _amount;

        withdrawn[msg.sender] = true;

        /*
        =================================================
        DANGEROUS EXTERNAL CALL
        =================================================

        ETH transfer may FAIL.

        BUT:
        success boolean ignored.
        */

        _receiver.call{
            value: _amount
        }("");

        /*
            Execution continues regardless.

            HUGE PROBLEM.
        */
    }

    /*
    =====================================================
    SAFE VERSION
    =====================================================
    */

    function safeWithdraw(
        address payable _receiver,
        uint256 _amount
    )
        external
    {

        /*
            Validate balance.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            Update storage.
        */
        balances[msg.sender] -= _amount;

        /*
            Properly check success.
        */
        (bool success, ) =
            _receiver.call{
                value: _amount
            }("");

        /*
            Revert if transfer failed.
        */
        require(
            success,
            "ETH transfer failed"
        );
    }

    /*
    =====================================================
    CHECK CONTRACT BALANCE
    =====================================================
    */

    function contractBalance()
        external
        view
        returns (uint256)
    {

        return address(this).balance;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy RejectETH

---------------------------------------------------------

STEP 2:
Deploy DangerousUncheckedCall

=========================================================
TRACE:
dangerousWithdraw()
=========================================================

STEP 1:
User deposits ETH.

---------------------------------------------------------

balances[user] = 1 ETH

=========================================================
STEP 2
=========================================================

Call:
dangerousWithdraw()

---------------------------------------------------------

Receiver:
RejectETH contract

=========================================================
STEP 3
=========================================================

Balance validation passes.

=========================================================
STEP 4
=========================================================

Storage updated FIRST.

---------------------------------------------------------

balances[user] -= 1 ETH

---------------------------------------------------------

withdrawn[user] = true

=========================================================
STEP 5
=========================================================

External ETH call executes.

---------------------------------------------------------

Receiver contract:
REVERTS intentionally.

=========================================================
STEP 6
=========================================================

IMPORTANT:

call() returns:

success = false

---------------------------------------------------------

BUT:

success is IGNORED.

=========================================================
STEP 7
=========================================================

Execution continues normally.

---------------------------------------------------------

Transaction DOES NOT revert.

=========================================================
FINAL RESULT
=========================================================

PROBLEM:

---------------------------------------------------------
USER BALANCE REDUCED
---------------------------------------------------------

YES

---------------------------------------------------------
withdrawn FLAG SET
---------------------------------------------------------

YES

---------------------------------------------------------
ETH ACTUALLY TRANSFERRED?
---------------------------------------------------------

NO

=========================================================
CRITICAL VULNERABILITY
=========================================================

Internal accounting says:
withdraw succeeded.

---------------------------------------------------------

Reality:
ETH never transferred.

=========================================================
WHY THIS IS DANGEROUS
=========================================================

Creates:
INCONSISTENT STATE.

---------------------------------------------------------

Protocol assumptions become false.

=========================================================
SAFE VERSION TRACE
=========================================================

safeWithdraw()

=========================================================

STEP 1:
External call fails.

---------------------------------------------------------

success = false

=========================================================
STEP 2
=========================================================

require(success)

---------------------------------------------------------

Transaction REVERTS.

=========================================================
STEP 3
=========================================================

ALL state changes rollback.

---------------------------------------------------------

balances restored.

---------------------------------------------------------

No inconsistent state.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy RejectETH

---------------------------------------------------------

STEP 2:
Deploy DangerousUncheckedCall

---------------------------------------------------------

STEP 3:
Deposit 1 ETH

---------------------------------------------------------

STEP 4:
Call:
dangerousWithdraw()

Inputs:
- RejectETH address
- 1 ether

---------------------------------------------------------

EXPECTED:
Transaction succeeds unexpectedly.

=========================================================
STEP 5
=========================================================

Check:

balances(user)

EXPECTED:
0

---------------------------------------------------------

withdrawn(user)

EXPECTED:
true

---------------------------------------------------------

BUT:
RejectETH received NO ETH.

=========================================================
STEP 6
=========================================================

Test:
safeWithdraw()

---------------------------------------------------------

EXPECTED:
Transaction reverts safely.

=========================================================
IMPORTANT LOW-LEVEL CALL UNDERSTANDING
=========================================================

call() NEVER auto-reverts.

---------------------------------------------------------

Developer MUST manually check:

success

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNCHECKED RETURN VALUES
---------------------------------------------------------

Classic Solidity vulnerability.

---------------------------------------------------------
2. ACCOUNTING CORRUPTION
---------------------------------------------------------

Internal state diverges from reality.

---------------------------------------------------------
3. SILENT FAILURES
---------------------------------------------------------

Protocol believes operation succeeded.

---------------------------------------------------------
4. DOS CONDITIONS
---------------------------------------------------------

Malicious contracts block execution silently.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

External calls are:
UNTRUSTED INTERACTIONS.

---------------------------------------------------------

Assume:
external execution may fail.

=========================================================
ATTACK THINKING
=========================================================

Attacker intentionally:

- rejects ETH
- reverts calls
- breaks assumptions
- causes inconsistent state

---------------------------------------------------------

Protocol logic becomes corrupted.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ALWAYS search for:

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

1. External interaction
2. Failure handling
3. Return-value checks
4. Accounting consistency
5. Silent-failure paths

=========================================================
WHY THIS BUG IS SUBTLE
=========================================================

Transaction appears:
successful.

---------------------------------------------------------

But:
protocol state corrupted internally.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add event logging
2. Add try/catch handling
3. Add revert-message decoding
4. Compare checked vs unchecked execution

BONUS:
Create token-transfer version
of unchecked-call bug.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- call() returns success manually
- Ignoring success is dangerous
- External calls may silently fail
- Silent failures corrupt accounting
- Transactions only revert if forced
- require(success) prevents inconsistencies
- Unchecked calls are major audit issue
- External interactions are untrusted
- Auditors inspect return-value handling carefully
- Error handling is critical in Solidity security

=========================================================
*/

/*
Title: Unchecked low-level call in dangerousWithdraw()

Severity: High

Reason: The contract ignores the return value of a low-level ETH transfer, allowing failed transfers to apperar successful and causing inconsistent accounting

Location: Contract: DangerousUncheckedCall
          Function: dangerousWithdraw(address payable _receiver uint256 _amount)

Vulnerability Description: The dangerousWithdraw() function perfoms a low-level ETH transfer using .call() but completely ingnores the returned success boolean
_receiver.call{
    value: _amount
}("");

If the receiver contract reject ETH or reverts during execution, the transfer fails silently

However
- User balances are already reduced
- withdrawn[msg.sender] becomes true
- Execution continues normally

Impact: an attacker or failing receiver contract can cause:
- Permanent loss of user funds
- Incorrect withdrawal records
- False successful withdrawals
- Accounting inconsistencies
- Broken protocol state
    Possible consequences include:
    - Users marked as paid without receiving ETH
    - Trasury accounting corruption
    - Failed intergrations with external contracts
    - Loss of recoverable balances

Proof of Concept:
1. Deploy RejectETH
2. Deploy DangerousUncheckedCall
3. Deposit ETH into DangerousUncheckedCall
4. Call:
dangerousWithdraw(
    rejectETHAddress,
    1 ether
5. RejectETH.receive() executes: revert("ETH rejected");
6. ETH transfer fails internally
7. .call() returns: success = false
8. Because the success flag is ignored:
  * balances[msg.sender] decreases
  * withdrawn[msg.sender] = true
  * No revert occurs
9. User loses accounting balance without receiving ETH

Root Cause: The vulnerability exists because the contract ignores the return value from a low-level external call
Unsafe implementation: _receiver.call{value: _amount}("");

Recommendation
1. Always check the success boolean returned by .call()
2. Revert failed ETH transfers
3. Add event logging for successful and failed calls
4. Decode revert messages for debugging
5. Use try/catch where interface calls are possible

*/

// PATCHED CODE

// INTERFACE
interface IRejectETH
{
    function failFunction() external;

    function successFunction() external;
}

contract RejectETH {

    /*
        Track calls
    */
    uint256 public counter;

    event ETHRejected(address sender, uint256 amount);

    event SuccessExecuted(address caller);


    /*
    =====================================================
    ALWAYS REVERT ON ETH
    =====================================================
    */

    receive()
        external
        payable
    {

        revert("ETH rejected");
    }

    /*
    =====================================================
    ALWAYS FAIL FUNCTION
    =====================================================
    */

    function failFunction()
        external
        pure
    {

        revert("Function failed");
    }


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
}

/*
=========================================================
VULNERABLE CONTRACT
=========================================================
*/

contract DangerousUncheckedCall {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        TRACK WITHDRAWALS
    */
    mapping(address => bool) public withdrawn;

    // TRACK LAST FAILURE
    string public lastReverReason;

    // EVENTS

    event Deposit(address indexed user, uint256 amount);

    event DangerousWithdrawAttempt(address indexed user, address receiver, uint256 amount, bool success);

    event SafeWithdrawattempt(address indexed user, address receiver, uint256 amount, bool success);

    event DecodedRevertReason(string reason);

    event TryCatchFailure(string reason);

    event TryCatchSuccess(string message);


    /*
    =====================================================
    DEPOSIT ETH
    =====================================================
    */

    function deposit()
        external
        payable
    {

        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /*
    =====================================================
    DANGEROUS WITHDRAW
    =====================================================

    PROBLEM:
    ignores success boolean.
    */

    function dangerousWithdraw(
        address payable _receiver,
        uint256 _amount
    )
        external
    {

        /*
            Validate balance.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            EFFECTS:
            Update storage FIRST.
        */
        balances[msg.sender] -= _amount;

        withdrawn[msg.sender] = true;

        /*
        =================================================
        DANGEROUS EXTERNAL CALL
        =================================================

        ETH transfer may FAIL.

        BUT:
        success boolean ignored.
        */
        
        (bool success, bytes memory data) =
        _receiver.call{
            value: _amount
        }("");

        emit DangerousWithdrawAttempt(msg.sender, _receiver, _amount, success);
        if (!success)
        {
            string memory reason = decodeRevertMessage(data);

            lastReverReason = reason;

            emit DecodedRevertReason(reason);
        }
        /*
            Execution continues regardless.

            HUGE PROBLEM.
        */
    }

    /*
    =====================================================
    SAFE VERSION
    =====================================================
    */

    function safeWithdraw(
        address payable _receiver,
        uint256 _amount
    )
        external
    {

        /*
            Validate balance.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            Update storage.
        */
        balances[msg.sender] -= _amount;

        /*
            Properly check success.
        */
        (bool success, bytes memory data) = _receiver.call{value: _amount}("");

        emit SafeWithdrawattempt(msg.sender, _receiver, _amount, success);

        if (!success)
        {
            string memory reason = decodeRevertMessage(data);

            lastReverReason = reason;
        }


        /*
            Revert if transfer failed.
        */
        require(
            success,
            "ETH transfer failed"
        );
    }

    // TRY/CATCH EXAMPLE
    function tryCatchExample(address _target) external 
    {
        IRejectETH target = IRejectETH(_target);

        try target.successFunction() 
        {
            emit TryCatchSuccess("Success function exected");
        } catch Error(string memory reason) 
        {
            emit TryCatchFailure(reason);
        }
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

     function decodeRevertMessage(
        bytes memory _data
    )
        internal
        pure
        returns (string memory)
    {

        /*
            Unknown revert.
        */
        if (_data.length < 68) {

            return "Unknown revert";
        }

        assembly {

            /*
                Skip selector.
            */
            _data := add(_data, 0x04)
        }

        return abi.decode(
            _data,
            (string)
        );
    }


    /*
    =====================================================
    CHECK CONTRACT BALANCE
    =====================================================
    */

    function contractBalance()
        external
        view
        returns (uint256)
    {

        return address(this).balance;
    }
}