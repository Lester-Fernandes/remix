// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call function from function
CONCEPT: Execution chaining
=========================================================

OBJECTIVE

- Learn how one function calls another
- Understand execution chaining
- Learn execution stack flow
- Understand chained state updates

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Functions can call:
other functions.

This creates:
execution chains.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Execution flows step-by-step:

Function A
   ->
Function B
   ->
Function C

Then returns backward.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most smart contracts use:
multi-function execution flow.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Execution chaining used in:

- ERC20 transfers
- DeFi swaps
- staking systems
- lending protocols
- liquidation systems
- governance execution

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- execution order
- hidden state updates
- reentrancy risk
- recursive loops
- validation propagation

=========================================================
*/

contract FunctionExecutionChainingval {

    /*
        STORAGE VARIABLES
    */
    mapping(address => uint256) public balances;

    uint256 public totalDeposits;

    /*
    =====================================================
    MAIN ENTRY FUNCTION
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Validate input.
        */
        validateAmount(_amount);

        /*
            STEP 2:
            Add balance.
        */
        addBalance(
            msg.sender,
            _amount
        );

        /*
            STEP 3:
            Update global total.
        */
        updateTotal(_amount);
    }

    /*
    =====================================================
    VALIDATION FUNCTION
    =====================================================
    */

    function validateAmount(
        uint256 _amount
    )
        internal
        pure
    {

        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 100,
            "Amount too large"
        );
    }

    /*
    =====================================================
    BALANCE UPDATE FUNCTION
    =====================================================
    */

    function addBalance(
        address _user,
        uint256 _amount
    )
        internal
    {

        /*
            Storage update.
        */
        balances[_user] += _amount;
    }

    /*
    =====================================================
    TOTAL UPDATE FUNCTION
    =====================================================
    */

    function updateTotal(
        uint256 _amount
    )
        internal
    {

        totalDeposits += _amount;
    }

    /*
    =====================================================
    CHAINED BONUS FLOW
    =====================================================
    */

    function depositWithBonus(
        uint256 _amount
    )
        external
    {

        /*
            Function calling another function.
        */
        depositInternal(_amount);

        /*
            Additional bonus logic.
        */
        addBalance(
            msg.sender,
            10
        );
    }

    /*
    =====================================================
    INTERNAL DEPOSIT FLOW
    =====================================================
    */

    function depositInternal(
        uint256 _amount
    )
        internal
    {

        /*
            Chained execution continues.
        */
        validateAmount(_amount);

        addBalance(
            msg.sender,
            _amount
        );

        updateTotal(_amount);
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(50)

=========================================================

STEP 1:
deposit() executes.

---------------------------------------------------------

STEP 2:
deposit() calls:

validateAmount(50)

---------------------------------------------------------

VALIDATION PASSES

---------------------------------------------------------

CONTROL RETURNS TO:
deposit()

---------------------------------------------------------

STEP 3:
deposit() calls:

addBalance(Alice, 50)

---------------------------------------------------------

STORAGE UPDATE:

balances[Alice] += 50

---------------------------------------------------------

CONTROL RETURNS TO:
deposit()

---------------------------------------------------------

STEP 4:
deposit() calls:

updateTotal(50)

---------------------------------------------------------

STORAGE UPDATE:

totalDeposits += 50

---------------------------------------------------------

FINAL STATE:

balances[Alice] = 50

totalDeposits = 50

=========================================================
CHAINED FLOW TRACE
=========================================================

CALL:
depositWithBonus(100)

=========================================================

STEP 1:
depositWithBonus() executes.

---------------------------------------------------------

STEP 2:
Calls:

depositInternal(100)

---------------------------------------------------------

depositInternal() calls:

validateAmount(100)

---------------------------------------------------------

Validation passes.

---------------------------------------------------------

depositInternal() calls:

addBalance(Alice, 100)

---------------------------------------------------------

depositInternal() calls:

updateTotal(100)

---------------------------------------------------------

depositInternal() finishes.

---------------------------------------------------------

CONTROL RETURNS TO:
depositWithBonus()

---------------------------------------------------------

STEP 3:
Bonus added:

addBalance(Alice, 10)

---------------------------------------------------------

FINAL STATE:

balances[Alice] += 110

=========================================================
IMPORTANT EXECUTION UNDERSTANDING
=========================================================

Function execution behaves like:
STACK FLOW.

---------------------------------------------------------

Execution enters:
called function

Then returns:
to caller function.

=========================================================
VISUAL FLOW
=========================================================

depositWithBonus()
    |
    +--> depositInternal()
             |
             +--> validateAmount()
             |
             +--> addBalance()
             |
             +--> updateTotal()

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(50)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
50

---------------------------------------------------------

STEP 4:
Call:
totalDeposits()

EXPECTED:
50

---------------------------------------------------------

STEP 5:
Call:
depositWithBonus(100)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
160

---------------------------------------------------------

STEP 7:
Call:
totalDeposits()

EXPECTED:
150

=========================================================
IMPORTANT FUNCTION CHAINING UNDERSTANDING
=========================================================

Functions may:
- validate
- compute
- mutate state
- call helper functions

---------------------------------------------------------

Execution order matters heavily.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. HIDDEN STATE MUTATIONS
---------------------------------------------------------

Called functions may:
modify storage unexpectedly.

---------------------------------------------------------
2. VALIDATION GAPS
---------------------------------------------------------

One chain path may skip validation.

---------------------------------------------------------
3. RECURSION RISK
---------------------------------------------------------

Functions calling each other recursively
may exhaust gas.

---------------------------------------------------------
4. EXECUTION ORDER BUGS
---------------------------------------------------------

Incorrect call ordering
may break invariants.

=========================================================
GAS OBSERVATION
=========================================================

More chained calls:
More gas usage.

---------------------------------------------------------

Deep chains:
Harder auditing.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Which functions call others?
- What state changes occur?
- Is validation always enforced?
- Can attacker influence flow?
- Are external calls involved?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer forgets validation
in one chain path.

Attacker uses unsafe path.

---------------------------------------------------------

ANOTHER RISK

External call inside chain
may enable reentrancy.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Call hierarchy
2. Execution order
3. State mutations
4. Validation propagation
5. Revert behavior

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw chain
2. Add fee deduction function
3. Add blacklist validation function
4. Trace full execution manually

BONUS:
Create recursive function
and observe gas behavior.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Functions can call other functions
- Execution follows stack-like flow
- Called function returns control to caller
- Function chains organize logic
- Hidden state mutations may occur
- Validation must propagate through chains
- Execution order matters heavily
- Recursive calls can be dangerous
- Auditors trace full call hierarchy
- Function chaining is core Solidity architecture

=========================================================
*/

/*
Title: Missing withdrawal excution chain, fee processing, and blacklist validation in function chaining architecture

Severity: Medium

Reason: The contract demonstrates chained internal function exection for deposits but lacks equivalent withdrawal flows, blacklist validation and fee deduction mechanisms. This create an 
        incomplete excution model and does not demonstrate how multiple internal function can work together during withdrawals.

Location: Contract: FunctionExecutionChaining
          Function: deposit()
          Function depositWithBonus()
          Function: depositInternal()

Vulnerability Description: The contract currently supports:
1. Validation chaining
2. Balance update chaining
3. Global state update chaining
- However it does not include:
1. Withdrawal execution chains
2. Fee deduction functions
3. Blacklist validation
4. Recursive execution examples
- As a result, the contract only demonstrates one-dirctional execution flow

Impact: potential issues include:
- Incomplete business logic
- No user retriction mechanism
- No fee collection demonstration
- Missing withdrawal execution path

Root Cause: The contract focuses exclusively on deposit exection chains and does not implement supporting withdrawal workflows or security validations.

Recommendation: Add
- Blacklist validation chain
- Fee deduction helper
- Withdrawal helper chain
- Recursive function demonstration

*/

contract FunctionExecutionChaining 
{

    /*
        STORAGE VARIABLES
    */
    mapping(address => uint256) public balances;

    mapping(address => bool) public blacklisted;

    uint256 public totalDeposits;

    /*
    =====================================================
    MAIN ENTRY FUNCTION
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
    {
        validateAmount(_amount);

        validateBlacklist(msg.sender);

        addBalance(
            msg.sender,
            _amount
        );

        updateTotal(_amount);
    }

    /*
    =====================================================
    WITHDRAW CHAIN
    =====================================================
    */

    function withdraw(
        uint256 _amount
    )
        external
    {
        withdrawInternal( msg.sender, _amount );
    }

    /*
    =====================================================
    INTERNAL WITHDRAW FLOW
    =====================================================
    */

    function withdrawInternal( address _user, uint256 _amount ) internal
    {
        validateBlacklist(_user);

        uint256 fee =
            calculateFee(_amount);

        require(
            balances[_user] >=
            (_amount + fee),
            "Insufficient balance"
        );

        deductBalance(
            _user,
            _amount + fee
        );

        decreaseTotal(
            _amount + fee
        );
    }

    /*
    =====================================================
    BLACKLIST VALIDATION
    =====================================================
    */

    function validateBlacklist( address _user )  internal view
    {
        require(
            !blacklisted[_user],
            "Blacklisted user"
        );
    }

    /*
    =====================================================
    VALIDATION FUNCTION
    =====================================================
    */

    function validateAmount( uint256 _amount )  internal  pure
    {
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 100,
            "Amount too large"
        );
    }

    /*
    =====================================================
    BALANCE UPDATE FUNCTION
    =====================================================
    */

    function addBalance(
        address _user,
        uint256 _amount
    )
        internal
    {
        balances[_user] += _amount;
    }

    /*
    =====================================================
    DEDUCT BALANCE
    =====================================================
    */

    function deductBalance(
        address _user,
        uint256 _amount
    )
        internal
    {
        balances[_user] -= _amount;
    }

    /*
    =====================================================
    TOTAL UPDATE FUNCTION
    =====================================================
    */

    function updateTotal(
        uint256 _amount
    )
        internal
    {
        totalDeposits += _amount;
    }

    /*
    =====================================================
    TOTAL DECREASE FUNCTION
    =====================================================
    */

    function decreaseTotal(
        uint256 _amount
    )
        internal
    {
        totalDeposits -= _amount;
    }

    /*
    =====================================================
    CHAINED BONUS FLOW
    =====================================================
    */

    function depositWithBonus(
        uint256 _amount
    )
        external
    {
        depositInternal(_amount);

        addBalance(
            msg.sender,
            10
        );
    }

    /*
    =====================================================
    INTERNAL DEPOSIT FLOW
    =====================================================
    */

    function depositInternal(
        uint256 _amount
    )
        internal
    {
        validateBlacklist(
            msg.sender
        );

        validateAmount(
            _amount
        );

        addBalance(
            msg.sender,
            _amount
        );

        updateTotal(
            _amount
        );
    }

    /*
    =====================================================
    FEE CALCULATION
    =====================================================
    */

    function calculateFee(
        uint256 _amount
    )
        internal
        pure
        returns (uint256)
    {
        return (_amount * 2) / 100;
    }

}