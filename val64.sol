// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Send ETH to non-payable contract
CONCEPT: Revert behavior
=========================================================

OBJECTIVE

- Learn why ETH transfers may fail
- Understand payable vs non-payable behavior
- Learn revert propagation mechanics
- Understand safe ETH transfer handling

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

A contract CANNOT receive ETH unless:

- receive() exists
OR
- fallback() is payable
OR
- target function is payable

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Sending ETH to a non-payable contract:

REVERTS the transaction.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

ETH transfer assumptions cause:

- failed withdrawals
- stuck funds
- broken integrations
- DOS vulnerabilities

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

ETH transfer logic exists in:

- vaults
- bridges
- staking systems
- exchanges
- DAO treasuries
- payment protocols

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- payable correctness
- ETH acceptance logic
- transfer failure handling
- unchecked call results
- DOS possibilities

=========================================================
NON-PAYABLE CONTRACT
=========================================================
*/

contract NonPayableReceiverval {

    /*
        TRACK EXECUTION
    */
    uint256 public counter;

    /*
    =====================================================
    NORMAL FUNCTION
    =====================================================

    NOT payable.
    */

    function increment()
        external
    {

        counter++;
    }

    /*
    =====================================================
    IMPORTANT
    =====================================================

    NO receive()
    NO payable fallback()

    Therefore:
    direct ETH transfers fail.
    */
}

/*
=========================================================
PAYABLE CONTRACT
=========================================================
*/

contract PayableReceiverval {

    /*
        TRACK RECEIVED ETH
    */
    uint256 public receivedAmount;

    /*
    =====================================================
    RECEIVE ETH
    =====================================================
    */

    receive()
        external
        payable
    {

        /*
            Store received ETH amount.
        */
        receivedAmount += msg.value;
    }
}

/*
=========================================================
SENDER CONTRACT
=========================================================
*/

contract ETHSenderval {

    /*
        TRACK LAST RESULT
    */
    bool public lastSuccess;

    /*
        TRACK TOTAL SENT
    */
    uint256 public totalSent;

    /*
    =====================================================
    SEND ETH SAFELY
    =====================================================
    */

    function sendETH(
        address payable _receiver
    )
        external
        payable
    {

        /*
            Attempt ETH transfer using call().
        */
        (bool success, ) =
            _receiver.call{
                value: msg.value
            }("");

        /*
            Save result.
        */
        lastSuccess = success;

        /*
            SAFE HANDLING.

            Revert if transfer failed.
        */
        require(
            success,
            "ETH transfer failed"
        );

        /*
            Update accounting ONLY after success.
        */
        totalSent += msg.value;
    }

    /*
    =====================================================
    DANGEROUS SEND
    =====================================================

    Ignores success boolean.
    */

    function dangerousSend(
        address payable _receiver
    )
        external
        payable
    {

        /*
            Attempt ETH transfer.
        */
        _receiver.call{
            value: msg.value
        }("");

        /*
            DANGEROUS:
            Execution continues even if transfer failed.
        */

        totalSent += msg.value;
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
Deploy NonPayableReceiver

---------------------------------------------------------

STEP 2:
Deploy PayableReceiver

---------------------------------------------------------

STEP 3:
Deploy ETHSender

=========================================================
TRACE:
sendETH() TO NON-PAYABLE CONTRACT
=========================================================

STEP 1:
User calls:

sendETH()

---------------------------------------------------------

VALUE:
1 ETH

---------------------------------------------------------

Receiver:
NonPayableReceiver

=========================================================
STEP 2
=========================================================

Low-level call executes:

_receiver.call{value: 1 ether}("")

=========================================================
STEP 3
=========================================================

Ethereum attempts to send ETH.

=========================================================
IMPORTANT
=========================================================

Target contract has:

---------------------------------------------------------
NO receive()
---------------------------------------------------------

AND

---------------------------------------------------------
NO payable fallback()
---------------------------------------------------------

=========================================================
STEP 4
=========================================================

ETH transfer automatically fails.

---------------------------------------------------------

success = false

=========================================================
STEP 5
=========================================================

require(success)

---------------------------------------------------------

FAILS

---------------------------------------------------------

FULL TRANSACTION REVERTS

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
ETH transferred?
---------------------------------------------------------

NO

---------------------------------------------------------
totalSent updated?
---------------------------------------------------------

NO

---------------------------------------------------------
Transaction status?
---------------------------------------------------------

REVERTED

=========================================================
WHY?
=========================================================

Contract cannot accept ETH.

=========================================================
TRACE:
sendETH() TO PAYABLE CONTRACT
=========================================================

STEP 1:
Call:
sendETH()

---------------------------------------------------------

VALUE:
1 ETH

---------------------------------------------------------

Receiver:
PayableReceiver

=========================================================
STEP 2
=========================================================

receive() executes successfully.

---------------------------------------------------------

success = true

=========================================================
STEP 3
=========================================================

require(success)

---------------------------------------------------------

PASSES

=========================================================
STEP 4
=========================================================

totalSent += 1 ether

=========================================================
FINAL RESULT
=========================================================

ETH transfer succeeds safely.

=========================================================
DANGEROUS TRACE
=========================================================

CALL:
dangerousSend()

---------------------------------------------------------

Receiver:
NonPayableReceiver

=========================================================

STEP 1:
ETH transfer fails.

---------------------------------------------------------

success = false

=========================================================
STEP 2
=========================================================

IMPORTANT:

success ignored completely.

=========================================================
STEP 3
=========================================================

Execution continues.

---------------------------------------------------------

totalSent += msg.value

=========================================================
CRITICAL PROBLEM
=========================================================

Internal accounting says:
ETH sent.

---------------------------------------------------------

Reality:
ETH transfer FAILED.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy NonPayableReceiver

---------------------------------------------------------

STEP 2:
Deploy PayableReceiver

---------------------------------------------------------

STEP 3:
Deploy ETHSender

=========================================================
TEST 1
=========================================================

Call:
sendETH()

---------------------------------------------------------

Receiver:
NonPayableReceiver address

---------------------------------------------------------

VALUE:
1 ether

---------------------------------------------------------

EXPECTED:
Transaction reverts

=========================================================
TEST 2
=========================================================

Call:
sendETH()

---------------------------------------------------------

Receiver:
PayableReceiver address

---------------------------------------------------------

VALUE:
1 ether

---------------------------------------------------------

EXPECTED:
Success

=========================================================
TEST 3
=========================================================

Call:
dangerousSend()

---------------------------------------------------------

Receiver:
NonPayableReceiver address

---------------------------------------------------------

VALUE:
1 ether

---------------------------------------------------------

EXPECTED:
Transaction succeeds incorrectly

=========================================================
STEP 4
=========================================================

Check:
totalSent()

---------------------------------------------------------

IMPORTANT:
Accounting corrupted.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

ETH transfers are NOT guaranteed.

---------------------------------------------------------

Receiving contracts control acceptance behavior.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNCHECKED ETH TRANSFERS
---------------------------------------------------------

Silent failures corrupt logic.

---------------------------------------------------------
2. NON-PAYABLE TARGETS
---------------------------------------------------------

Unexpected revert conditions.

---------------------------------------------------------
3. DOS VIA REVERT
---------------------------------------------------------

Malicious contracts reject ETH intentionally.

---------------------------------------------------------
4. ACCOUNTING INCONSISTENCY
---------------------------------------------------------

Protocol state diverges from reality.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers may:

- reject ETH intentionally
- revert receive()
- break protocol assumptions
- trigger DOS conditions

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Can target receive ETH?
- Is success checked?
- Are failures handled safely?
- Can ETH rejection DOS protocol?
- Is accounting updated correctly?

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. ETH transfer behavior
2. Payable correctness
3. Failure propagation
4. Accounting consistency
5. External trust assumptions

=========================================================
BEST PRACTICE
=========================================================

Always:

---------------------------------------------------------
(bool success, ) = receiver.call{value: x}("");

require(success)
---------------------------------------------------------

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add payable fallback()
2. Add try/catch handling
3. Add event logging
4. Compare transfer/send/call

BONUS:
Create malicious ETH-rejecting DOS contract.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Non-payable contracts reject ETH
- ETH transfers may revert
- receive() enables ETH reception
- call() returns success manually
- Ignoring success is dangerous
- External ETH handling is untrusted
- Reverts rollback transaction state
- Accounting must follow successful transfers
- Auditors inspect ETH-transfer assumptions
- Safe ETH handling is critical in Solidity

=========================================================
*/
/*
Title: Unsafe ETH transfer handling and lgnored failure conditions

Severity: High

Reason: The contract demonstrates multiple ETH transfer mechanisms(transfer, send, call) but includes dangerous logic where transfer failures may be
        ignored, leading to incorrect accounting and inconsistent contract state

Location: Contracts Affected: ETHSender
                              NonPayableReceiver
                              PayableReceiver
        
          Vulnerable Functions: dangerousSend()
                                sendETH()
                                transferETH()
                                fallback()
                                receive()

Vulnerability Description: The contracts demonstrate different ETH transfer techniques
- transfer()
- send()
- call() 
The dangerousSend() function uses:

_receiver.send(msg.value)

However, the returned success boolean is not validated properly before updating protocol accounting.

Even when the ETH transfer fails, execution continues:

totalSent += msg.value;

This creates inconsistent accounting because the contract records ETH as sent even when no transfer actually occurred.

Additionally:
- call() forwards all remaining gas,
- fallback() functions allow arbitrary execution,
- malicious fallback logic may trigger unexpected behavior.

Impact: An attacker or unexpected receiver contract may:
- reject ETH transfers
- force inconsistent accounting
- exploit incorrect financial records
- create incorrent financial records
- cause protocol logic errors
Potential consequences include
- incorrect balances
- failed transfers appearing successful
- accounting corruption
- unexpected fallback execution
- denial of service in integrations

Proof of Concept:
Step 1 — Deploy Contracts

Deploy:

NonPayableReceiver
ETHSender
Step 2 — Call dangerousSend()

Call:

dangerousSend(nonPayableReceiver)

with ETH.

Step 3 — ETH Transfer Fails

Because NonPayableReceiver cannot properly receive ETH through send():

send() returns false

Step 4 — State Still Updates

Despite transfer failure:

totalSent += msg.value;

still executes.

Root Cause: The vulnerability exists because:
- send() returns a boolean instead of reverting
- transfer failure is ignored
- state updates occur without validating success

*/

// PATCH CODE

/*
=========================================================
INTERFACE
=========================================================
*/

interface IPayableReceiver 
{

    function getBalance()
        external
        view
        returns (uint256);
}

/*
=========================================================
NON PAYABLE RECEIVER
=========================================================
*/

contract NonPayableReceiver 
{

    /*
        TRACK EXECUTION
    */
    uint256 public counter;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event Incremented(
        address caller
    );

    event FallbackTriggered(
        address sender,
        uint256 amount,
        bytes data
    );

    /*
    =====================================================
    NORMAL FUNCTION
    =====================================================
    */

    function increment()
        external
    {
        counter++;

        emit Incremented(
            msg.sender
        );
    }

    /*
    =====================================================
    PAYABLE FALLBACK
    =====================================================
    */

    fallback()
        external
        payable
    {
        emit FallbackTriggered(
            msg.sender,
            msg.value,
            msg.data
        );
    }
}

/*
=========================================================
PAYABLE RECEIVER
=========================================================
*/

contract PayableReceiver {

    /*
        TRACK RECEIVED ETH
    */
    uint256 public receivedAmount;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event ETHReceived(
        address sender,
        uint256 amount
    );

    event FallbackExecuted(
        address sender,
        uint256 amount,
        bytes data
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
        receivedAmount += msg.value;

        emit ETHReceived(
            msg.sender,
            msg.value
        );
    }

    /*
    =====================================================
    PAYABLE FALLBACK
    =====================================================
    */

    fallback()
        external
        payable
    {
        receivedAmount += msg.value;

        emit FallbackExecuted(
            msg.sender,
            msg.value,
            msg.data
        );
    }

    /*
    =====================================================
    GET BALANCE
    =====================================================
    */

    function getBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }
}

/*
=========================================================
ETH SENDER CONTRACT
=========================================================
*/

contract ETHSender {

    /*
        TRACK LAST RESULT
    */
    bool public lastSuccess;

    /*
        TRACK TOTAL SENT
    */
    uint256 public totalSent;

    /*
        STORE LAST REVERT
    */
    string public lastError;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event ETHTransferResult(
        address receiver,
        uint256 amount,
        bool success
    );

    event TransferUsed(
        address receiver,
        uint256 amount
    );

    event SendUsed(
        address receiver,
        uint256 amount,
        bool success
    );

    event CallUsed(
        address receiver,
        uint256 amount,
        bool success
    );

    event TryCatchFailure(
        string reason
    );

    /*
    =====================================================
    SEND ETH USING CALL
    =====================================================
    */

    function sendETH(
        address payable _receiver
    )
        external
        payable
    {

        (
            bool success,
            bytes memory data
        ) =
            _receiver.call{
                value: msg.value
            }("");

        lastSuccess = success;

        emit CallUsed(
            _receiver,
            msg.value,
            success
        );

        if (!success) {

            lastError =
                decodeRevert(data);

            emit TryCatchFailure(
                lastError
            );
        }

        require(
            success,
            "ETH transfer failed"
        );

        totalSent += msg.value;

        emit ETHTransferResult(
            _receiver,
            msg.value,
            success
        );
    }

    /*
    =====================================================
    DANGEROUS SEND
    =====================================================
    */

    function dangerousSend(
        address payable _receiver
    )
        external
        payable
    {

        /*
            SEND ignores returndata.
        */
        bool success =
            _receiver.send(
                msg.value
            );

        lastSuccess = success;

        emit SendUsed(
            _receiver,
            msg.value,
            success
        );

        /*
            Execution continues
            even if failed.
        */

        totalSent += msg.value;
    }

    /*
    =====================================================
    TRANSFER EXAMPLE
    =====================================================
    */

    function transferETH(
        address payable _receiver
    )
        external
        payable
    {

        /*
            transfer()
            auto reverts on failure.
        */
        _receiver.transfer(
            msg.value
        );

        totalSent += msg.value;

        emit TransferUsed(
            _receiver,
            msg.value
        );
    }

    /*
    =====================================================
    TRY/CATCH EXAMPLE
    =====================================================
    */

    function tryCatchExample(
        address _receiver
    )
        external
    {

        IPayableReceiver receiver =
            IPayableReceiver(
                _receiver
            );

        try receiver.getBalance()
            returns (
                uint256 balance
            )
        {

            balance;

        } catch Error(
            string memory reason
        ) {

            lastError = reason;

            emit TryCatchFailure(
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
    CONTRACT BALANCE
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