// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Send ETH using transfer
CONCEPT: ETH transfer mechanics
=========================================================

OBJECTIVE

- Learn how transfer() sends ETH
- Understand native ETH movement
- Learn payable mechanics
- Understand transfer limitations + risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

transfer() sends native ETH
from one contract/address to another.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

ETH transfers:
trigger external execution.

---------------------------------------------------------

Receiving contracts may execute:
receive() or fallback().

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

ETH transfers are fundamental to:

- withdrawals
- payments
- staking
- refunds
- treasury systems
- DeFi protocols

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

ETH transfer logic used in:

- exchanges
- vaults
- DAOs
- staking systems
- NFT marketplaces
- lending protocols

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- transfer ordering
- reentrancy risk
- failed transfer handling
- locked ETH risks
- DOS vectors

=========================================================
*/

contract EthTransferMechanicsval {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================

    payable:
    function can receive ETH.
    */

    function deposit()
        external
        payable
    {

        /*
            msg.value:
            ETH sent with transaction.
        */
        require(
            msg.value > 0,
            "No ETH sent"
        );

        /*
            Store deposited ETH amount.
        */
        balances[msg.sender] += msg.value;
    }

    /*
    =====================================================
    SEND ETH USING transfer()
    =====================================================
    */

    function withdraw(
        uint256 _amount
    )
        external
    {

        /*
            CHECK:
            user must have balance.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            EFFECTS:
            update storage BEFORE transfer.

            CEI pattern:
            Checks -> Effects -> Interactions
        */
        balances[msg.sender] -= _amount;

        /*
            INTERACTION:
            send ETH externally.

            transfer():
            - sends ETH
            - forwards 2300 gas
            - reverts automatically if failed
        */
        payable(msg.sender).transfer(_amount);
    }

    /*
    =====================================================
    CHECK CONTRACT ETH BALANCE
    =====================================================
    */

    function contractBalance()
        external
        view
        returns (uint256)
    {

        /*
            address(this).balance

            Native ETH stored
            inside this contract.
        */
        return address(this).balance;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
User deposits ETH.

---------------------------------------------------------

CALL:
deposit()

VALUE:
1 ETH

=========================================================
DEPOSIT TRACE
=========================================================

STEP 1:
Transaction carries ETH.

---------------------------------------------------------

msg.value = 1 ETH

---------------------------------------------------------

STEP 2:
require(msg.value > 0)

RESULT:
true

---------------------------------------------------------

STEP 3:
Storage updated.

balances[Alice] += 1 ETH

---------------------------------------------------------

STEP 4:
Contract receives ETH.

---------------------------------------------------------

CONTRACT BALANCE:
1 ETH

=========================================================
WITHDRAW TRACE
=========================================================

CALL:
withdraw(1 ETH)

=========================================================

STEP 1:
Balance validation.

---------------------------------------------------------

balances[Alice] >= 1 ETH

RESULT:
true

---------------------------------------------------------
STEP 2:
Storage updated FIRST.

balances[Alice] -= 1 ETH

---------------------------------------------------------

NEW VALUE:
0

---------------------------------------------------------
STEP 3:
ETH transfer executes.

payable(msg.sender).transfer(1 ETH)

---------------------------------------------------------

ETH leaves contract.

---------------------------------------------------------

Alice receives ETH.

=========================================================
IMPORTANT transfer() UNDERSTANDING
=========================================================

transfer():

- sends native ETH
- forwards ONLY 2300 gas
- auto-reverts on failure

=========================================================
VERY IMPORTANT:
2300 GAS LIMIT
=========================================================

Receiving contract gets:

ONLY 2300 gas

---------------------------------------------------------

This usually prevents:
complex execution.

---------------------------------------------------------

Historically helped reduce:
reentrancy risk.

=========================================================
WHAT HAPPENS INTERNALLY
=========================================================

transfer():

1. deducts ETH from sender contract
2. sends ETH externally
3. triggers receiver execution
4. reverts if receiver fails

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Expand VALUE field in Remix

---------------------------------------------------------

STEP 3:
Enter:
1 ether

---------------------------------------------------------

STEP 4:
Call:
deposit()

---------------------------------------------------------

STEP 5:
Call:
contractBalance()

EXPECTED:
1000000000000000000

(1 ETH in wei)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
1 ETH in wei

---------------------------------------------------------

STEP 7:
Call:
withdraw(500000000000000000)

(0.5 ETH)

---------------------------------------------------------

STEP 8:
Call:
balances(your_address)

EXPECTED:
0.5 ETH remaining

=========================================================
IMPORTANT PAYABLE UNDERSTANDING
=========================================================

Functions receiving ETH
must be marked:

payable

---------------------------------------------------------

Otherwise:
transaction reverts.

=========================================================
WEI UNDERSTANDING
=========================================================

1 ETH =
1,000,000,000,000,000,000 wei

---------------------------------------------------------

Solidity stores ETH in:
wei internally.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

External ETH transfer dangerous
if state updated too late.

---------------------------------------------------------
2. DOS VIA transfer()
---------------------------------------------------------

2300 gas may break receivers.

---------------------------------------------------------
3. LOCKED ETH
---------------------------------------------------------

No withdraw path exists.

---------------------------------------------------------
4. FAILED TRANSFER ASSUMPTIONS
---------------------------------------------------------

Receiver may revert intentionally.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

External ETH transfer =
external interaction.

---------------------------------------------------------

Treat as:
UNTRUSTED execution.

=========================================================
CEI PATTERN
=========================================================

SAFE ORDER:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

Used in withdraw() above.

=========================================================
WHY transfer() BECAME LESS PREFERRED
=========================================================

Modern Solidity often prefers:

call{value: amount}()

---------------------------------------------------------

Reason:
2300 gas assumptions became unreliable.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Is ETH transfer ordered safely?
- Can receiver reenter?
- Can transfer fail unexpectedly?
- Is ETH permanently lockable?
- Are balances updated before transfer?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

State updated AFTER transfer.

---------------------------------------------------------

Attacker contract:
reenters withdraw repeatedly.

---------------------------------------------------------

Result:
fund theft.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. ETH movement
2. State-update ordering
3. External interaction timing
4. Revert behavior
5. Receiver execution flow

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add vulnerable withdraw()
2. Move transfer BEFORE balance update
3. Analyze reentrancy risk
4. Fix using CEI pattern

BONUS:
Implement withdraw using:
call{value: amount}()

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- transfer() sends native ETH
- payable functions receive ETH
- msg.value contains sent ETH
- transfer() forwards 2300 gas
- External ETH transfers are dangerous
- CEI pattern improves security
- State must update before transfer
- ETH stored internally as wei
- Auditors trace ETH movement carefully
- Interactions create reentrancy risk

=========================================================
*/

/*
Title: Reentrancy vulnerability due to incorrect withdrawal order

Severity: High

Reason: External ETH transfer occurs before updating the user's balance, allowing a malicious contract to re-enter the withdrawal function and drain funds.

Location: Contract: EthTransferMechanics
          Function: valnerableWithdraw()

Vulnerability Description: The vulnerable withdrawal implementation performs the external ETH transfer before updating the user's stored balance.

Impact: An attacker may
- Withdraw funds multiple times
- Drain ETH belonging to other users
- Cause complete loss of contract funds
- Break accounting invariants

proof of Concept:
Step 1

Attacker deposits:

deposit{value: 1 ether}()

Stored balance:

balances[attacker] = 1 ETH
Step 2

Attacker calls:

vulnerableWithdraw(1 ether)
Step 3

Contract executes:

payable(msg.sender).call{
    value: 1 ether
}("");

Balance is still:

balances[attacker] = 1 ETH
Step 4

Attacker's fallback function executes and calls:

vulnerableWithdraw(1 ether)

again.

Step 5

The balance check passes repeatedly because storage has not yet been updated.

Attacker receives ETH multiple times.

Result: Contract funds can be drained.

Root Cause: The ontract violates the CEI pattern
Checks
-> Interactions
-> Effects

instead of
Checks
-> Effects
-> Interactions

State changes occur after the external call

Recommendation: Follow the CEI(Checks-Effects-Interactions) pattern

Correct order:
1. Validate
2. Update storage
3. Perform external transfer

Optionally add: nonReentrant

*/

// PATCHED CODE

contract EthTransferMechanics {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    // REENTRANCY LOCK

    bool private locked;

    // REENTRANCY GUARD

    modifier nonReentrant()
    {
        require(!locked, "Reentrant call blocked");

        locked = true; _; 

        locked = false;
    }

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================

    payable:
    function can receive ETH.
    */

    function deposit()
        external
        payable
    {

        /*
            msg.value:
            ETH sent with transaction.
        */
        require(
            msg.value > 0,
            "No ETH sent"
        );

        /*
            Store deposited ETH amount.
        */
        balances[msg.sender] += msg.value;
    }

    /*
    =====================================================
    SEND ETH USING transfer()
    =====================================================
    */

    function withdraw(
        uint256 _amount
    )
        external nonReentrant
    {

        /*
            CHECK:
            user must have balance.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            EFFECTS:
            update storage BEFORE transfer.

            CEI pattern:
            Checks -> Effects -> Interactions
        */
        balances[msg.sender] -= _amount;

        /*
            INTERACTION
        */

        (bool success, ) = payable(msg.sender).call
        {
            value: _amount
        } ("");

        require(success, "transfer failed");
    }

// VULNERABLE WITHDRAW

    function vulnerableWithdraw(uint256 _amount) external 
    {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        (bool success, ) = payable(msg.sender).call 
        {
            value: _amount
        }("");

        require(success, "Transfer failed");

        balances[msg.sender] -= _amount;
    }

    /*
    =====================================================
    CHECK CONTRACT ETH BALANCE
    =====================================================
    */

    function contractBalance()
        external
        view
        returns (uint256)
    {

        /*
            address(this).balance

            Native ETH stored
            inside this contract.
        */
        return address(this).balance;
    }

    // RECEIVE ETH

    receive() external payable {}
}
