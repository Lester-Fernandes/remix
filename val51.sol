// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call another contract
CONCEPT: Inter-contract communication
=========================================================

OBJECTIVE

- Learn how contracts call other contracts
- Understand inter-contract execution flow
- Learn external call behavior
- Understand cross-contract risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Smart contracts can:
call functions in other contracts.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Cross-contract calls create:
NEW execution context.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most real protocols interact with:

- tokens
- vaults
- oracles
- DEXes
- lending protocols
- bridges

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Inter-contract communication used in:

- ERC20 transfers
- AMM swaps
- lending protocols
- NFT marketplaces
- staking systems
- governance execution

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- external call safety
- trust assumptions
- reentrancy risk
- return-value handling
- cross-contract state assumptions

=========================================================
CONTRACT 1:
TARGET CONTRACT
=========================================================
*/

// contract Bankval {

//     /*
//         USER BALANCES
//     */
//     mapping(address => uint256) public balances;

//     /*
//     =====================================================
//     DEPOSIT FUNCTION
//     =====================================================
//     */

//     function deposit(
//         uint256 _amount
//     )
//         external
//     {

//         /*
//             Update storage.
//         */
//         balances[msg.sender] += _amount;
//     }

//     /*
//     =====================================================
//     READ BALANCE
//     =====================================================
//     */

//     function getBalance(
//         address _user
//     )
//         external
//         view
//         returns (uint256)
//     {

//         return balances[_user];
//     }
// }

// /*
// =========================================================
// CONTRACT 2:
// CALLER CONTRACT
// =========================================================
// */

// contract InterContractCallerval {

//     /*
//         STORE TARGET CONTRACT ADDRESS
//     */
//     address public bankAddress;

//     /*
//         LAST READ VALUE
//     */
//     uint256 public lastBalance;

//     /*
//         CONSTRUCTOR

//         Save target contract address.
//     */
//     constructor(
//         address _bankAddress
//     )
//     {

//         bankAddress = _bankAddress;
//     }

//     /*
//     =====================================================
//     CALL DEPOSIT FUNCTION
//     =====================================================
//     */

//     function callDeposit(
//         uint256 _amount
//     )
//         external
//     {

//         /*
//             Create contract reference.

//             Tells Solidity:
//             "bankAddress is a Bank contract"
//         */
//         Bank bank =
//             Bank(bankAddress);

//         /*
//             EXTERNAL CONTRACT CALL

//             Execution jumps into:
//             Bank.deposit()
//         */
//         bank.deposit(_amount);
//     }

//     /*
//     =====================================================
//     READ ANOTHER CONTRACT STATE
//     =====================================================
//     */

//     function readBalance(
//         address _user
//     )
//         external
//     {

//         /*
//             Create contract reference.
//         */
//         Bank bank =
//             Bank(bankAddress);

//         /*
//             External view call.

//             Reads state from another contract.
//         */
//         uint256 balance =
//             bank.getBalance(_user);

//         /*
//             Save locally.
//         */
//         lastBalance = balance;
//     }
// }

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy Bank contract.

---------------------------------------------------------

Bank deployed at:

0xABC...

=========================================================
STEP 2:
Deploy InterContractCaller

constructor input:
0xABC...

---------------------------------------------------------

Caller now knows:
Bank contract address.

=========================================================
TRACE:
callDeposit(100)
=========================================================

STEP 1:
User calls:

InterContractCaller.callDeposit(100)

---------------------------------------------------------

STEP 2:
Contract reference created:

Bank bank =
Bank(bankAddress)

---------------------------------------------------------

STEP 3:
External contract call occurs:

bank.deposit(100)

---------------------------------------------------------

EXECUTION CONTEXT SWITCHES

---------------------------------------------------------

Execution enters:
Bank.deposit()

=========================================================
INSIDE BANK CONTRACT
=========================================================

balances[msg.sender] += 100

---------------------------------------------------------

IMPORTANT:

msg.sender is:
InterContractCaller contract

NOT original user.

=========================================================
VERY IMPORTANT msg.sender UNDERSTANDING
=========================================================

Cross-contract call changes:

msg.sender

---------------------------------------------------------

FLOW:

User
  ->
Caller Contract
  ->
Bank Contract

---------------------------------------------------------

Inside Bank:

msg.sender =
Caller contract address

=========================================================
READ FLOW TRACE
=========================================================

CALL:
readBalance(user)

=========================================================

STEP 1:
Caller contract executes.

---------------------------------------------------------

STEP 2:
External view call:

bank.getBalance(user)

---------------------------------------------------------

STEP 3:
Execution enters Bank contract.

---------------------------------------------------------

STEP 4:
Balance returned.

---------------------------------------------------------

STEP 5:
Caller stores result:

lastBalance = returned balance

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy Bank contract

---------------------------------------------------------

STEP 2:
Copy Bank address

---------------------------------------------------------

STEP 3:
Deploy InterContractCaller

Constructor input:
Bank address

---------------------------------------------------------

STEP 4:
Call:
callDeposit(100)

---------------------------------------------------------

STEP 5:
Open Bank contract

---------------------------------------------------------

STEP 6:
Call:
balances(caller_contract_address)

EXPECTED:
100

---------------------------------------------------------

IMPORTANT:
Balance stored for CALLER contract.

=========================================================
IMPORTANT CROSS-CONTRACT UNDERSTANDING
=========================================================

External calls create:

- new execution context
- new msg.sender
- possible reentrancy window
- trust assumptions

=========================================================
INTERFACE-LIKE BEHAVIOR
=========================================================

This line:

Bank(bankAddress)

means:

"Treat this address as Bank contract"

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

External contract may call back unexpectedly.

---------------------------------------------------------
2. TRUST ASSUMPTIONS
---------------------------------------------------------

Target contract may behave maliciously.

---------------------------------------------------------
3. RETURN VALUE IGNORED
---------------------------------------------------------

Dangerous if call fails silently.

---------------------------------------------------------
4. msg.sender CONFUSION
---------------------------------------------------------

Critical authentication mistakes possible.

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

External contract calls are:

UNTRUSTED INTERACTIONS

---------------------------------------------------------

Never assume:
target contract behaves safely.

=========================================================
GAS OBSERVATION
=========================================================

Cross-contract calls:
cost more gas.

---------------------------------------------------------

Reason:
context switching + external execution.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Which contracts are trusted?
- Can target contract reenter?
- Is msg.sender handled correctly?
- Are return values checked?
- Are external calls ordered safely?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Malicious contract called externally.

---------------------------------------------------------

During execution:
it reenters vulnerable function.

---------------------------------------------------------

Result:
fund theft.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Cross-contract execution flow
2. msg.sender changes
3. External interaction timing
4. State-update ordering
5. Reentrancy windows

=========================================================
MINI CHALLENGE
=========================================================

Modify system so that:

1. Add withdraw() function
2. Add external ETH transfer
3. Observe msg.sender changes
4. Add interface contract

BONUS:
Build simple token interaction.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Contracts can call other contracts
- External calls create new execution context
- msg.sender changes during contract calls
- Cross-contract interactions are risky
- External calls may enable reentrancy
- Contract references treat addresses as contracts
- Return values must be checked carefully
- Auditors trace inter-contract execution carefully
- Trust assumptions are security critical
- Inter-contract communication powers DeFi systems

=========================================================
*/

/*
Title: Missing ETH reception Logic in inter-contract withdrawal flow

Severity: Medium

Reason: The caller contract was unable to receive ETH returned from the bank contract during withdrawals, causing withdrawal transactions to fail.

Location: Contract: InterContractcaller
          Function: callWithdraw()
          Related Function: bank.withdraw()

Vulnerability Description: The original implementation allowed the caller contract to invoke Bank.withdraw(), Which sends ETH back to msg.sender

When InterContractcaller calls Bank.withdraw() the bank contract sees
msg.sender == InterContractCaller

Therefore, the ETH is sent back to the InterContractCaller contract, not directly to the external user

The original caller contract did not imlement a 
receive() external payable{}
or
fallback() external payable{}
function

As a result, ETH transfers sent back from the bank contract would fail and cause the entire withdrawal transaction to revert

Impact: Users interacting through the caller contract would be uable to successfully withdraw ETH

Potential consequences include
- Withdrawal transactions reverting
- Funds becoming temporarily inaccessible through the proxy contract
- Failed inter-contract interaction workflows
- Unexpected user experience and transaction failures

Proof of Concept
Step 1

Deploy:

Bank
Step 2

Deploy:

InterContractCaller

using the Bank contract address.

Step 3

Call:

callDeposit()

with ETH.

The deposit succeeds.

Step 4

Call:

callWithdraw(amount)
Step 5

Execution flow:

InterContractCaller
        ↓
Bank.withdraw()
        ↓
Bank sends ETH to:
InterContractCaller
Step 6

Because the caller contract cannot receive ETH:

receive() external payable {}

is missing.

The transfer fails.

Result: Transaction reverts.

Root Cause: The caller contract acts as an intermediary contract

During withdrawal:
(bool success, ) = payable(msg.sender).call{value: _amount}("");

sends ETH to the caller contract address.

However the caller contrack lacked an ETH receiver function

Recommendation: Add an ETH receiver function:
receive() external payable {}

This allows the contract to accept ETH returned from external contracts

Optionally implement: fallback() external payable {}

for additional compatibility

*/

// PATCHED CODE

/*
=========================================================
BANK CONTRACT
=========================================================
*/
contract Bank {

    mapping(address => uint256) public balances;

    // Modified deposit to accept actual ETH (payable)
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /*
    =====================================================
    WITHDRAW FUNCTION WITH EXTERNAL ETH TRANSFER
    =====================================================
    */
    function withdraw(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // Effects (CEI pattern)
        balances[msg.sender] -= _amount;

        // Interaction: External ETH transfer
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
}

/*
=========================================================
CALLER CONTRACT
=========================================================
*/
contract InterContractCaller {

    address public bankAddress;
    uint256 public lastBalance;

    constructor(address _bankAddress) {
        bankAddress = _bankAddress;
    }

    // Explicitly fallback to allow this contract to receive ETH back from Bank
    receive() external payable {}

    function callDeposit() external payable {
        // Direct referencing by casting the address straight to the Bank contract type
        Bank bank = Bank(bankAddress);

        // Forward the exact ETH received by this function to the Bank
        bank.deposit{value: msg.value}();
    }

    function callWithdraw(uint256 _amount) external {
        Bank bank = Bank(bankAddress);
        
        // Triggers the Bank's withdrawal function
        bank.withdraw(_amount);
    }

    function readBalance(address _user) external {
        Bank bank = Bank(bankAddress);
        lastBalance = bank.getBalance(_user);
    }
}

