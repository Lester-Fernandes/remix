// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Fail require after state update
CONCEPT: Transaction atomicity
=========================================================

OBJECTIVE

- Learn Ethereum transaction atomicity
- Understand rollback after require() failure
- Observe temporary vs permanent state changes
- Learn why partial updates cannot persist

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

If require() fails:

EVERYTHING inside the transaction
is reverted.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Even if:
- storage updated
- balances changed
- counters incremented

A revert removes ALL changes.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Atomicity is a core EVM guarantee.

Without atomicity:
partial state corruption would occur.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Atomicity protects:

- ERC20 transfers
- DeFi accounting
- lending protocols
- AMMs
- auctions
- governance systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- state updates before revert points
- external call ordering
- partial execution assumptions
- transaction rollback behavior
- CEI pattern compliance

=========================================================
*/

contract TransactionAtomicityval {

    /*
        STORAGE VARIABLES

        Persist only if transaction succeeds.
    */
    uint256 public globalCounter;

    mapping(address => uint256) public balances;

    /*
    =====================================================
    FAIL REQUIRE AFTER STATE UPDATE
    =====================================================
    */

    function brokenExecution(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            UPDATE GLOBAL COUNTER

            Temporary state update.
        */
        globalCounter =
            globalCounter + _amount;

        /*
            STEP 2:
            UPDATE USER BALANCE

            Temporary state update.
        */
        balances[msg.sender] =
            balances[msg.sender] + _amount;

        /*
            STEP 3:
            REQUIRE FAILURE

            If _amount > 5:
            transaction reverts completely.
        */
        require(
            _amount <= 5,
            "Amount too large"
        );
    }

    /*
    =====================================================
    SAFE EXECUTION
    =====================================================

    Validation first.
    */

    function safeExecution(
        uint256 _amount
    )
        external
    {

        /*
            VALIDATE BEFORE CHANGES
        */
        require(
            _amount <= 5,
            "Amount too large"
        );

        /*
            UPDATE STATE AFTER VALIDATION
        */
        globalCounter =
            globalCounter + _amount;

        balances[msg.sender] =
            balances[msg.sender] + _amount;
    }
}

/*
=========================================================
INITIAL STATE
=========================================================

globalCounter = 0

balances[Alice] = 0

=========================================================
TRACE:
brokenExecution(3)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

globalCounter =
0 + 3

TEMP VALUE:
3

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] =
0 + 3

TEMP VALUE:
3

---------------------------------------------------------
STEP 3
---------------------------------------------------------

require(3 <= 5)

RESULT:
true

---------------------------------------------------------
TRANSACTION SUCCEEDS
---------------------------------------------------------

FINAL STATE:

globalCounter = 3

balances[Alice] = 3

=========================================================
TRACE:
brokenExecution(10)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

globalCounter =
3 + 10

TEMP VALUE:
13

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] =
3 + 10

TEMP VALUE:
13

---------------------------------------------------------
STEP 3
---------------------------------------------------------

require(10 <= 5)

RESULT:
false

---------------------------------------------------------
TRANSACTION REVERTS
---------------------------------------------------------

ALL STATE CHANGES UNDONE.

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

globalCounter = 3

balances[Alice] = 3

---------------------------------------------------------

IMPORTANT:
Temporary values disappear.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
brokenExecution(3)

---------------------------------------------------------

STEP 3:
Call:
globalCounter()

EXPECTED:
3

---------------------------------------------------------

STEP 4:
Call:
balances(your_address)

EXPECTED:
3

---------------------------------------------------------

STEP 5:
Call:
brokenExecution(10)

EXPECTED:
Transaction reverts

---------------------------------------------------------

STEP 6:
Call:
globalCounter()

EXPECTED:
Still 3

---------------------------------------------------------

STEP 7:
Call:
balances(your_address)

EXPECTED:
Still 3

---------------------------------------------------------

OBSERVE:
Failed transaction changed NOTHING.

=========================================================
IMPORTANT EVM UNDERSTANDING
=========================================================

ETHEREUM TRANSACTIONS ARE:

ATOMIC

---------------------------------------------------------

Meaning:

Either:
- entire transaction succeeds

OR:
- entire transaction reverts

=========================================================
WHAT REVERT DOES
=========================================================

When require() fails:

EVM:
- undoes storage writes
- restores old state
- stops execution
- refunds remaining gas

=========================================================
TEMPORARY EXECUTION STATE
=========================================================

During execution:

Temporary storage updates exist internally.

---------------------------------------------------------

BUT:
They persist ONLY if transaction succeeds.

=========================================================
WHY VALIDATION-FIRST MATTERS
=========================================================

BEST PRACTICE:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

This is:
Checks-Effects-Interactions pattern.

=========================================================
BAD PATTERN
=========================================================

1. update storage
2. validate later

---------------------------------------------------------

Problems:
- wasted gas
- dangerous with external calls
- harder to audit

=========================================================
GAS OBSERVATION
=========================================================

Even reverted transactions:
consume gas.

---------------------------------------------------------

Reason:
Computation already executed.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. TRACE EXECUTION ORDER
---------------------------------------------------------

Auditors inspect:
what changes BEFORE revert points.

---------------------------------------------------------
2. PARTIAL STATE ASSUMPTIONS
---------------------------------------------------------

Partial updates cannot survive revert.

---------------------------------------------------------
3. EXTERNAL CALL DANGER
---------------------------------------------------------

External interactions before revert
may create reentrancy risks.

---------------------------------------------------------
4. CEI PATTERN
---------------------------------------------------------

Checks -> Effects -> Interactions
improves security.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker repeatedly triggers:
expensive computation + revert.

Result:
gas griefing DOS.

---------------------------------------------------------

ANOTHER RISK

Improper external-call ordering
before revert may expose vulnerabilities.

=========================================================
REAL AUDITOR QUESTIONS
=========================================================

Auditors ask:

- What happens before require()?
- Can external calls occur first?
- What reverts?
- What persists?
- Is rollback behavior understood?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add external token transfer logic
2. Trigger revert after external call
3. Observe rollback behavior carefully

BONUS:
Implement proper CEI ordering.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Ethereum transactions are atomic
- require() failure reverts all state changes
- Temporary updates disappear after revert
- Storage persists only on success
- Validation-first is preferred
- Reverted transactions still consume gas
- CEI pattern improves security
- Execution order matters heavily
- Auditors trace rollback behavior carefully
- Partial state corruption is prevented by EVM atomicity

=========================================================
*/

/*
Title: Violation of Checks-Effects-Interactions (CEI) pattern in external tocken transfer logic

Severity: High

Reason: External calls are executed before validation, which can cause unexpected behavior and increase attack suface. Although a revert
        rolls back state changes within the same transaction, the contract follows an unsafe execution pattern

Location: Contract: TransactionAtomicity
          Function: transferAndRevert()

Vulnerability Description: the transferAndRevert() function performs an external tocken transfer before executing a validation check.
Example vulnerable flow:
function transferAndRevert(
    address token,
    address recipient,
    uint256 amount
)
    external
{
    IERC20(token).transfer(
        recipient,
        amount
    );

    require(
        amount <= 100,
        "Amount too large"
    );
}

The contract interacts with an external token contract before performing all required checks.

This violates the Checks → Effects → Interactions security pattern.

Impact: Potential consequences include:
- Unnecessary gas consumption
- Increased attack surface
- Reentrancy risk when interacting with malicious contracts
- Complex transaction behavior that is harder to audit
If the external contains contains unexpected logic, execution may behave differently that intended

Proof of Concept:

Scenario
Deploy the contract.
Call:
transferAndRevert(
    tokenAddress,
    recipientAddress,
    500
);
Execution flow:
Step 1:
External token transfer executes

Step 2:
require(amount <= 100)

Step 3:
Condition fails

Step 4:
Transaction reverts
Entire transaction rolls back.

Result:

globalCounter unchanged
balances unchanged
token transfer reverted

Root Cause: The contract performs an external interaction before completing validation.

IERC20(token).transfer(
    recipient,
    amount
);

require(
    amount <= 100,
    "Amount too large"
);

Security best practice requires:

Checks
→ Effects
→ Interactions

Recommendation: Follow the CEI pattern
1. Validate inputs first 
2. Update internal sate
3. Perform external interactions last
Also verify transfer success

Example:
require(
    amount <= 100,
    "Amount too large"
);

balances[msg.sender] -= amount;

bool success =
    IERC20(token).transfer(
        recipient,
        amount
    );

require(
    success,
    "Transfer failed"
);

*/
// Patched code

contract SimpleContract{
    mapping (address=>uint256) public balances;
    //adds tokens to any address
    function mint(address _to,uint256 _amt)external  {
        balances[_to]=balances[_to]+_amt;
    }
}

contract TransactionAtomicity {
    
    SimpleContract public token;

    mapping (address=>uint256) public balances;

    constructor(address _token){
        token=SimpleContract(_token);
    }
     /*
    =====================================================
    BAD VERSION
    =====================================================

    External call BEFORE validation.
    */
    function badExecution(uint256 _amt) external {
        balances[msg.sender]+=_amt;
        /*
            EXTERNAL CALL
        */
        token.mint(msg.sender,_amt);
        /*
            LATE VALIDATION

            If this fails:
            ENTIRE TRANSACTION REVERTS.
        */
        require(_amt <= 5,"Amount too large");
    }

     /*
    =====================================================
    SAFE VERSION
    =====================================================

    CHECKS -> EFFECTS -> INTERACTIONS
    */

     function safeExecution(uint256 _amount)external {   /*
            CHECKS
        */
        require(_amount <= 5,"Amount too large");

        /*
            EFFECTS
        */
        balances[msg.sender] += _amount;

        /*
            INTERACTIONS
        */
        token.mint(msg.sender, _amount);
    }
}