// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Fix Reentrancy using CEI Pattern
CONCEPT: Secure execution order
=========================================================

OBJECTIVE

- Fix reentrancy vulnerability
- Apply Checks → Effects → Interactions pattern
- Ensure secure ETH withdrawal flow
- Prevent recursive external calls exploitation

---------------------------------------------------------
CORE IDEA (CEI PATTERN)
---------------------------------------------------------

✔ CHECKS        → validate conditions
✔ EFFECTS       → update state FIRST
✔ INTERACTIONS  → external calls LAST

---------------------------------------------------------

This prevents reentrancy because:

state is already updated
before external contract can re-enter

=========================================================
SECURE BANK CONTRACT
=========================================================
*/

// contract SecureBankval {

//     /*
//         USER BALANCES
//     */
//     mapping(address => uint256) public balance;

//     /*
//     =====================================================
//     DEPOSIT ETH
//     =====================================================
//     */

//     function deposit() external payable {
//         balance[msg.sender] += msg.value;
//     }

//     /*
//     =====================================================
//     SECURE WITHDRAW (FIXED)
//     =====================================================
//     */

//     function withdraw(uint256 amount) external {

//         /*
//         =================================================
//         1. CHECKS
//         =================================================
//         */
//         require(balance[msg.sender] >= amount, "Insufficient balance");

//         /*
//         =================================================
//         2. EFFECTS (STATE UPDATE FIRST) ✅ FIX
//         =================================================
//         */

//         balance[msg.sender] -= amount;

//         /*
//         =================================================
//         3. INTERACTIONS (EXTERNAL CALL LAST)
//         =================================================
//         */

//         (bool success, ) = msg.sender.call{value: amount}("");
//         require(success, "Transfer failed");
//     }

//     /*
//     =====================================================
//     VIEW BALANCE
//     =====================================================
//     */

//     function getBalance(address user)
//         external
//         view
//         returns (uint256)
//     {
//         return balance[user];
//     }
// }
/*
Title: Reentrancy Vulnerability Fixed Using Checks-Effects-Interactions and Reentrancy Guard

Severity: High

Reason: The original withdrawal logic was vulnerable to recursive external call exploitation if state updates occurred after ETH transfer execution.

Location: Contract: SecureBank
          Affected Function: withdraw()

Vulnerability Description: Reentrancy vulnerabilities occur when
1. ETH is transferred externally
2. control leaves the contract
3. attacker callback executes
4. withdrawal function is called again before state updates complete

Impact: Without protection an attacker could
- repeatedly reenter withdrawal logic,
- drain contract ETH,
- bypass intended balance accounting,
- steal protocol funds.

Proof Of Concept
Step 1 — Deploy Contracts

Deploy:

SecureBank

and:

ReentrancyAttacker
Step 2 — Deposit ETH

User deposits ETH:

deposit()
Step 3 — Start Attack

Attacker executes:

attack()
Step 4 — Observe Protection

Reentrancy attempt fails because:

- balance updated first,
- nonReentrant lock activated,
- recursive execution blocked.

Root Cause: The Vulnerability exists when:
- external calls occur before state updates,
- no reentrancy lock exists,
- recursive execution is possible.

*/

// PATCHED CODE

/*
=========================================================
SECURE BANK CONTRACT
=========================================================
*/

contract SecureBank {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balance;

    /*
        REENTRANCY LOCK
    */
    bool private locked;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event Deposit(address indexed user,uint256 amount);

    event Withdraw(address indexed user,uint256 amount);

    event AttackBlocked( address attacker);

    /*
    =====================================================
    NON REENTRANT MODIFIER
    =====================================================
    */

    modifier nonReentrant() {

        require(
            !locked,
            "Reentrant call detected"
        );

        locked = true; _;

        locked = false;
    }

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================
    */

    function deposit()
        external
        payable
    {

        require(
            msg.value > 0,
            "Zero ETH not allowed"
        );

        balance[msg.sender] += msg.value;

        emit Deposit(
            msg.sender,
            msg.value
        );
    }

    /*
    =====================================================
    SECURE WITHDRAW
    =====================================================

    CHECKS
    → EFFECTS
    → INTERACTIONS
    */

    function withdraw(
        uint256 amount
    )
        external
        nonReentrant
    {

        /*
        =================================================
        1. CHECKS
        =================================================
        */

        require(
            balance[msg.sender] >= amount,
            "Insufficient balance"
        );

        require(
            amount > 0,
            "Invalid amount"
        );

        /*
        =================================================
        2. EFFECTS
        =================================================

        State updated BEFORE
        external interaction.
        */

        balance[msg.sender] -= amount;

        /*
        =================================================
        3. INTERACTIONS
        =================================================
        */

        (bool success, ) =
            payable(msg.sender).call{
                value: amount
            }("");

        require(
            success,
            "Transfer failed"
        );

        emit Withdraw(
            msg.sender,
            amount
        );
    }

    /*
    =====================================================
    VIEW USER BALANCE
    =====================================================
    */

    function getBalance(
        address user
    )
        external
        view
        returns (uint256)
    {

        return balance[user];
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

/*
=========================================================
MALICIOUS ATTACKER CONTRACT
=========================================================
*/

contract ReentrancyAttacker {

    /*
        TARGET CONTRACT
    */
    SecureBank public target;

    /*
        TRACK ATTACKS
    */
    uint256 public attackCounter;

    /*
        OWNER
    */
    address public owner;

    /*
    =====================================================
    CONSTRUCTOR
    =====================================================
    */

    constructor(
        address _target
    ) {

        target =
            SecureBank(_target);

        owner = msg.sender;
    }

    /*
    =====================================================
    DEPOSIT INTO TARGET
    =====================================================
    */

    function depositToBank()
        external
        payable
    {

        target.deposit{
            value: msg.value
        }();
    }

    /*
    =====================================================
    START ATTACK
    =====================================================
    */

    function attack()
        external
    {

        /*
            Attempt withdrawal.
        */
        target.withdraw(
            1 ether
        );
    }

    /*
    =====================================================
    RECEIVE FUNCTION
    =====================================================

    Reentrancy attempt.
    */

    receive()
        external
        payable
    {

        attackCounter++;

        /*
            Reentrancy blocked by:
            nonReentrant modifier.
        */

        if (
            address(target).balance >= 1 ether
        ) {

            try target.withdraw(
                1 ether
            ) {

            } catch {

            }
        }
    }

    /*
    =====================================================
    WITHDRAW ATTACKER FUNDS
    =====================================================
    */

    function withdrawLoot()
        external
    {

        require(
            msg.sender == owner,
            "Not owner"
        );

        payable(owner).transfer(
            address(this).balance
        );
    }
}