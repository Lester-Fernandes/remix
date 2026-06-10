// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: tx.origin Authentication Contract
CONCEPT: Dangerous authentication pattern
=========================================================

WARNING:
This contract demonstrates a BAD PRACTICE.

DO NOT use tx.origin for authentication in production.
=========================================================
*/

contract TxOriginAuth {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /*
    =====================================================
    DANGEROUS AUTH CHECK
    =====================================================
    */

    function withdrawAll() external {

        /*
        ❌ BAD PRACTICE:
        using tx.origin for authentication
        */

        require(tx.origin == owner, "Not owner");

        payable(owner).transfer(address(this).balance);
    }

    /*
    =====================================================
    NORMAL DEPOSIT
    =====================================================
    */

    function deposit() external payable {}
}

/*
Title: Insecure Authentication using tx.origin

Severity: High

Reason: Using tx.origin for authorization allows phishing-style attacks through malicious intermediary contracts

Location: Contract: TxOriginAuth
          Function: withdrawAll()

Vulnerability Description: The withdrawAll() functions uses: require(tx.origin == owner, "Not owner");
for authentication.

Using tx.origin is dangerous because it checks the ORIGINAL external account that started the transaction, not the immediate caller.

An attacker can deploy a malicious contract that tricks the owner into interacting with it.

When the malicious contract calls withdrawAll(), the following occurs:

tx.origin = victim owner address
msg.sender = malicious contract address

The authentication passes incorrectly.

Impact: An attacker can
- bypass intended authorization
- trick teh owner into executing malicious transactions
- steal all ETH stored in the contract
Potential consequences
- complete loss of funds
- phishing-based contract compromise
- unauthorized privileged execution

Proof of Concept:
Step 1:

Victim deploys TxOriginAuth.

Step 2:

Victim deposits ETH into contract.

Step 3:

Attacker deploys malicious phishing contract.

Step 4:

Victim interacts with malicious contract.

Step 5:

Malicious contract internally calls:

withdrawAll()
Step 6:

Inside vulnerable contract:

tx.origin == owner

returns true because transaction originated from victim wallet.

Step 7:

All ETH is transferred to attacker-controlled flow.

Root Cause: The contract uses
tx.origin

instead of:

msg.sender

for authentication.

tx.origin tracks the ORIGINAL transaction initiator across the entire call chain.

This makes authentication vulnerable to intermediary malicious contracts.

*/

// PATCHED CODE

contract SecureAuth
{
    address public owner;

    event Deposit(address indexed user, uint256 amount);

    event Withdraw(address indexed owner, uint256 amount);

    constructor()
    {
        owner = msg.sender;
    }

    // SECURE AUTHENTICATION
    modifier onlyOwner()
    {
        require(msg.sender == owner, "Not owner"); _;
    }

    // SECURE WITHDRAW
    function withdrawAll() external onlyOwner
    {
        uint256 amount = address(this).balance;

        payable(owner).transfer(amount);

        emit Withdraw(owner, amount);
    }

    // DEPOSIT ETH
    function deposit() external payable 
    {
        emit Deposit(msg.sender, msg.value);
    }

    // CONTRACT BALANCE
    function getBalance() external view returns (uint256)
    {
        return address(this).balance;
    }
}