// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Vulnerable Reentrancy Bank
CONCEPT: Root reentrancy logic
=========================================================

WARNING:
This contract is INTENTIONALLY VULNERABLE.

DO NOT use in production.
=========================================================
*/

contract VulnerableBankval {

    mapping(address => uint256) public balance;

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================
    */

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    /*
    =====================================================
    WITHDRAW ETH (VULNERABLE)
    =====================================================
    */

    function withdraw(uint256 amount) external {

        /*
        STEP 1:
        Check balance
        */
        require(balance[msg.sender] >= amount, "Not enough balance");

        /*
        STEP 2:
        EXTERNAL CALL FIRST ❌ (DANGER)
        */
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        /*
        STEP 3:
        STATE UPDATE AFTER CALL ❌ (ROOT ISSUE)
        */
        balance[msg.sender] -= amount;
    }

    /*
    =====================================================
    VIEW BALANCE
    =====================================================
    */

    function getBalance(address user)
        external
        view
        returns (uint256)
    {
        return balance[user];
    }
}

/*
Title: Reentrancy Vulnerability in withdraw()

Severity: High

Reason: External call executed before state update allows recursive withdrawals

Location: Contract: VulnerableBank
          Function: withdraw(uint256 amount)

Vulnerability Description: The withdraw() function performs an external ETH transfer before updating the user's balance
(bool success, ) = msg.sender.call{value: amount}("");
    Because control is transferred to the external address before storage updates occur a malicious contract can reenter the withdraw() function
    multiple times before the balance is reduced. This creates a classic reentrancy vulnerability.

Impact: An attacker can
- recursively call withdraw()
- drain ETH from the contract
- bypass intended balance accounting
- stral funds belonging to other users
Potential consequences include
- complete protocol fund loss
- insolvency
- denial of withdrawals for legitimate users

Proof Of Concept
Step 1:

Attacker deposits 1 ETH into the bank.

Step 2:

Attacker calls:

withdraw(1 ether)

Step 3:

During ETH transfer, attack contract receive() executes automatically.

Step 4:

Attacker reenters withdraw() before:

balance[msg.sender] -= amount;

executes.

Step 5:

Funds are repeatedly withdrawn until contract ETH is drained.

Root Cause: The contract violates the
Check -> Effects -> Interactions pattern

Specifically
- external interaction occurs before state update
- no reentrancy guard exists
- recursive execution is possible

*/

// PATCHED CODE

contract SecureBank
{
    // USER BALANCES
    mapping(address => uint256) public balance;

    // REENTRANCY LOCK
    bool private locked;

    // EVENTS
    event Deposit(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event ReentrancyBlocked(address attacker);

    // NON-REENTRANT MODIFIER
    modifier nonReentrant()
    {
        require(!locked,"Reentrancy detected");

        locked = true; _;

        locked = false;
    }

    // DEPOSIT ETH
    function deposit() external payable 
    {
        require(msg.value > 0,"Zero ETH");

        balance[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    // SECURE WITHDRAW
    function withdraw(uint256 amount) external nonReentrant
    {
        // CHECKS
        require(balance[msg.sender] >= amount, "Insufficient baance");

        // EVENTS
        balance[msg.sender] -= amount;

        // INTERACTIONS
        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    // VIEW USER BALANCE
    function gatBalance(address user) external view returns (uint256)
    {
        return balance[user];
    }

    //CONTRACT BALANCE
    function contractBalance() external view returns (uint256)
    {
        return address(this).balance;
    }
}