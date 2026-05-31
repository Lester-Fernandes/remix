// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call multiple state updates
CONCEPT: Order dependency
=========================================================

OBJECTIVE

- Learn how multiple storage updates execute
- Understand order dependency in Solidity
- Learn why update sequence matters
- Understand state consistency risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

State updates execute:
line-by-line in exact order.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Changing execution order can:
completely change final state.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Incorrect update ordering causes:

- accounting bugs
- balance corruption
- reentrancy vulnerabilities
- invariant violations

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Order dependency matters in:

- ERC20 transfers
- DeFi lending
- staking systems
- liquidation engines
- AMMs
- vault accounting

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- update sequencing
- external-call ordering
- invariant preservation
- partial state assumptions
- race-condition risks

=========================================================
*/

contract OrderDependencyExampleval {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        GLOBAL TOTAL
    */
    uint256 public totalSupply;

    /*
        REWARD TRACKER
    */
    mapping(address => uint256) public rewards;

    /*
    =====================================================
    CORRECT ORDER EXAMPLE
    =====================================================
    */

    function depositCorrect(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Validate input FIRST.
        */
        require(
            _amount > 0,
            "Invalid amount"
        );

        /*
            STEP 2:
            Update user balance.
        */
        balances[msg.sender] += _amount;

        /*
            STEP 3:
            Update total supply.

            Depends on balance update.
        */
        totalSupply += _amount;

        /*
            STEP 4:
            Reward based on NEW balance.
        */
        rewards[msg.sender] =
            balances[msg.sender] / 10;
    }

    /*
    =====================================================
    BAD ORDER EXAMPLE
    =====================================================
    */

    function depositWrong(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Reward calculated BEFORE
            balance update.
        */
        rewards[msg.sender] =
            balances[msg.sender] / 10;

        /*
            STEP 2:
            Balance updated later.
        */
        balances[msg.sender] += _amount;

        /*
            STEP 3:
            Total updated.
        */
        totalSupply += _amount;
    }

    /*
    =====================================================
    TRANSFER EXAMPLE
    =====================================================
    */

    function transfer(
        address _to,
        uint256 _amount
    )
        external
    {

        /*
            Validate sender balance FIRST.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            CORRECT ORDER:
            subtract sender first.
        */
        balances[msg.sender] -= _amount;

        /*
            Then add receiver.
        */
        balances[_to] += _amount;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

balances[Alice] = 100

rewards[Alice] = 0

=========================================================
TRACE:
depositCorrect(50)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

require(50 > 0)

RESULT:
true

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] += 50

NEW VALUE:
150

---------------------------------------------------------
STEP 3
---------------------------------------------------------

totalSupply += 50

---------------------------------------------------------
STEP 4
---------------------------------------------------------

rewards[Alice] =
balances[Alice] / 10

150 / 10 = 15

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 150

rewards[Alice] = 15

=========================================================
BAD ORDER TRACE
=========================================================

INITIAL:

balances[Alice] = 100

---------------------------------------------------------

CALL:
depositWrong(50)

---------------------------------------------------------
STEP 1
---------------------------------------------------------

rewards[Alice] =
balances[Alice] / 10

100 / 10 = 10

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] += 50

NEW VALUE:
150

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 150

rewards[Alice] = 10

---------------------------------------------------------

IMPORTANT:
Reward incorrect because
order was wrong.

=========================================================
IMPORTANT EXECUTION UNDERSTANDING
=========================================================

Solidity executes:
TOP -> DOWN

---------------------------------------------------------

Every storage update affects:
future lines immediately.

=========================================================
ORDER DEPENDENCY
=========================================================

Later logic depends on:
earlier state changes.

---------------------------------------------------------

Changing line order may:
change protocol behavior.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
depositCorrect(100)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
100

---------------------------------------------------------

STEP 4:
Call:
rewards(your_address)

EXPECTED:
10

---------------------------------------------------------

STEP 5:
Deploy fresh contract

---------------------------------------------------------

STEP 6:
Call:
depositWrong(100)

---------------------------------------------------------

STEP 7:
Call:
rewards(your_address)

EXPECTED:
0

---------------------------------------------------------

OBSERVE:
Reward used OLD balance.

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

Incorrect update order can create:

- stale reads
- broken accounting
- exploit opportunities

=========================================================
CHECKS-EFFECTS-INTERACTIONS
=========================================================

BEST PRACTICE:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

Known as:
CEI pattern.

=========================================================
WHY CEI MATTERS
=========================================================

Correct ordering helps prevent:
reentrancy vulnerabilities.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. STALE STATE READS
---------------------------------------------------------

Logic reads old values accidentally.

---------------------------------------------------------
2. EXTERNAL CALL BEFORE UPDATE
---------------------------------------------------------

Major reentrancy risk.

---------------------------------------------------------
3. INVARIANT BREAKAGE
---------------------------------------------------------

Incorrect order corrupts accounting.

---------------------------------------------------------
4. DOUBLE-SPEND RISKS
---------------------------------------------------------

Incorrect balance sequencing dangerous.

=========================================================
GAS OBSERVATION
=========================================================

More state updates:
higher gas usage.

---------------------------------------------------------

Repeated storage reads/writes:
especially expensive.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- What updates happen first?
- Which values depend on prior state?
- Are stale reads possible?
- Are invariants preserved?
- Does execution order prevent exploits?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

External call before balance reduction.

Attacker reenters repeatedly.

Result:
fund theft.

---------------------------------------------------------

ANOTHER RISK

Reward calculated before update.

Attacker gains incorrect rewards.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Exact execution order
2. Storage reads/writes
3. Dependency chains
4. External-call timing
5. Invariant preservation

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw function
2. Intentionally place external call
   before balance update
3. Observe vulnerability risk
4. Fix using CEI pattern

BONUS:
Track previousBalance and newBalance.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Solidity executes line-by-line
- State updates affect later execution immediately
- Execution order changes final behavior
- Incorrect ordering creates vulnerabilities
- CEI pattern improves security
- Stale reads are dangerous
- External-call ordering is critical
- Auditors trace exact state-update sequence
- Dependency chains matter heavily
- Order dependency is fundamental in smart contracts

=========================================================
*/

/*
Title: External call before state update creates reentrancy risk

Severity: High

Reason: The contract can become vulnerable to reentrancy attacks if an external call is executed before updating balances.

Location: Contract: OrderDependencyExampleval
          Function: withdrawWorng()

Vulnerability Description:
A withdrawal function that persorms an external call before reducing the user's balance violates the Checks-Effects-Interactions (CEI) pattern

An attacker contract can use its fallback/receive function to call withdrawWong() again before the balance is updated.

This allows repeated withdrawals using the same balance.

Impact: An attacker may
- Withdraw multiple times
- Drain contract funds
- Manipulate protocol accounting
- Cause insolvency

Root Cause: The contract performs

Checks
↓
External Call
↓
Balance Update

- instead of:

Checks
↓
Balance Update
↓
External Call

Recommendation: Apply the Checks-Effects-Interactions (CEI) pattern
1. Validate conditions
2. Update state
3. Perform external interaction

*/

// PATCHED CODE

contract OrderDependencyExample {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        GLOBAL TOTAL
    */
    uint256 public totalSupply;

    /*
        REWARD TRACKER
    */
    mapping(address => uint256) public rewards;

    /*
    =====================================================
    CORRECT ORDER EXAMPLE
    =====================================================
    */

    function depositCorrect(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Validate input FIRST.
        */
        require(
            _amount > 0,
            "Invalid amount"
        );

        /*
            STEP 2:
            Update user balance.
        */
        balances[msg.sender] += _amount;

        /*
            STEP 3:
            Update total supply.

            Depends on balance update.
        */
        totalSupply += _amount;

        /*
            STEP 4:
            Reward based on NEW balance.
        */
        rewards[msg.sender] =
            balances[msg.sender] / 10;
    }

    /*
    =====================================================
    BAD ORDER EXAMPLE
    =====================================================
    */

    function depositWrong(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Reward calculated BEFORE
            balance update.
        */
        rewards[msg.sender] =
            balances[msg.sender] / 10;

        /*
            STEP 2:
            Balance updated later.
        */
        balances[msg.sender] += _amount;

        /*
            STEP 3:
            Total updated.
        */
        totalSupply += _amount;
    }

    /*
    =====================================================
    TRANSFER EXAMPLE
    =====================================================
    */

    function transfer(
        address _to,
        uint256 _amount
    )
        external
    {

        /*
            Validate sender balance FIRST.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            CORRECT ORDER:
            subtract sender first.
        */
        balances[msg.sender] -= _amount;

        /*
            Then add receiver.
        */
        balances[_to] += _amount;
    }

// VULNERABLE WITHDRAW
    function withdrawWrong(uint256 _amount) external 
    {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        (bool success,) = payable(msg.sender).call
        {
            value: _amount
        } ("");

        require(success, "Transfer failed");

        balances[msg.sender] -= _amount;

        totalSupply -= _amount;
    }

// SAFE WITHDRAW (CEI)
    function withdrawSafe(uint256 _amount) external 
    {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        totalSupply -= _amount;

        (bool success,) = payable(msg.sender).call
        {
            value: _amount
        } ("");

        require(success, "Transfer failed");
    }

    receive() external payable {}
    
}