// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Make external call after state update
CONCEPT: Safer execution
=========================================================

OBJECTIVE

- Learn safer external-call ordering
- Understand CEI security pattern
- Prevent basic reentrancy vulnerabilities
- Learn secure execution sequencing

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Safe pattern:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

Known as:
CEI pattern.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

State must update BEFORE
external interaction.

---------------------------------------------------------

This reduces:
reentrancy attack surface.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Incorrect external-call ordering caused:
major DeFi hacks.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Safe ordering used in:

- vault withdrawals
- token redemptions
- staking systems
- lending protocols
- treasury payments

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- external-call timing
- storage-update order
- CEI violations
- reentrancy windows
- interaction safety

=========================================================
SAFE CONTRACT
=========================================================
*/

// contract SafeBankval {

//     /*
//         USER BALANCES
//     */
//     mapping(address => uint256) public balances;

//     /*
//         TRACK TOTAL ETH
//     */
//     uint256 public totalDeposits;

//     /*
//     =====================================================
//     DEPOSIT ETH
//     =====================================================
//     */

//     function deposit()
//         external
//         payable
//     {

//         /*
//             Store user balance.
//         */
//         balances[msg.sender] += msg.value;

//         /*
//             Update global accounting.
//         */
//         totalDeposits += msg.value;
//     }

//     /*
//     =====================================================
//     SAFE WITHDRAW
//     =====================================================

//     Follows:
//     Checks -> Effects -> Interactions
//     */

//     function withdraw(
//         uint256 _amount
//     )
//         external
//     {

//         /*
//         =================================================
//         CHECKS
//         =================================================

//         Validate user balance FIRST.
//         */

//         require(
//             balances[msg.sender] >= _amount,
//             "Insufficient balance"
//         );

//         /*
//         =================================================
//         EFFECTS
//         =================================================

//         Update storage BEFORE external call.
//         */

//         balances[msg.sender] -= _amount;

//         totalDeposits -= _amount;

//         /*
//         =================================================
//         INTERACTIONS
//         =================================================

//         External call happens LAST.
//         */

//         (bool success, ) =
//             payable(msg.sender).call{
//                 value: _amount
//             }("");

//         /*
//             Ensure ETH transfer succeeded.
//         */
//         require(
//             success,
//             "ETH transfer failed"
//         );
//     }

//     /*
//     =====================================================
//     CHECK CONTRACT BALANCE
//     =====================================================
//     */

//     function contractBalance()
//         external
//         view
//         returns (uint256)
//     {

//         return address(this).balance;
//     }
// }

// /*
// =========================================================
// MALICIOUS TEST CONTRACT
// =========================================================
// */

// contract ReentryTesterval {

//     /*
//         TARGET SAFE CONTRACT
//     */
//     SafeBank public target;

//     /*
//         TRACK REENTRY ATTEMPTS
//     */
//     uint256 public attackCounter;

//     /*
//         CONSTRUCTOR
//     */
//     constructor(address _target)
//     {

//         target = SafeBank(_target);
//     }

//     /*
//     =====================================================
//     DEPOSIT INTO TARGET
//     =====================================================
//     */

//     function depositToTarget()
//         external
//         payable
//     {

//         target.deposit{value: msg.value}();
//     }

//     /*
//     =====================================================
//     START WITHDRAW
//     =====================================================
//     */

//     function attack()
//         external
//     {

//         /*
//             Attempt withdrawal.
//         */
//         target.withdraw(1 ether);
//     }

//     /*
//     =====================================================
//     RECEIVE FUNCTION
//     =====================================================

//     Attempt reentrancy attack.
//     */

//     receive()
//         external
//         payable
//     {

//         attackCounter++;

//         /*
//             Try reentering target.
//         */
//         if (
//             address(target).balance >= 1 ether
//         ) {

//             /*
//                 THIS FAILS SAFELY

//                 Why?

//                 Balance already reduced.
//             */
//             try target.withdraw(1 ether) {

//             } catch {

//             }
//         }
//     }
// }

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy SafeBank

---------------------------------------------------------

STEP 2:
Deposit ETH into SafeBank

=========================================================
STEP 3
=========================================================

Deploy ReentryTester

Input:
SafeBank address

=========================================================
STEP 4
=========================================================

Call:
depositToTarget()

VALUE:
1 ETH

=========================================================
STEP 5
=========================================================

Call:
attack()

=========================================================
SAFE EXECUTION TRACE
=========================================================

STEP 1:
withdraw(1 ether)

---------------------------------------------------------

Balance validation passes.

=========================================================
STEP 2
=========================================================

Storage updated FIRST.

---------------------------------------------------------

balances[attacker] -= 1 ether

---------------------------------------------------------

NEW VALUE:
0

=========================================================
STEP 3
=========================================================

External call executes:

call{value: 1 ether}()

---------------------------------------------------------

Control transfers to:
ReentryTester.receive()

=========================================================
STEP 4
=========================================================

Attacker attempts reentrancy.

---------------------------------------------------------

Calls:
target.withdraw(1 ether)

=========================================================
IMPORTANT
=========================================================

Balance already reduced.

---------------------------------------------------------

balances[attacker] = 0

---------------------------------------------------------

require() fails.

---------------------------------------------------------

Reentrancy blocked naturally.

=========================================================
WHY SAFE ORDERING WORKS
=========================================================

Attacker sees:
UPDATED state.

---------------------------------------------------------

Temporary inconsistent state
never exposed.

=========================================================
IMPORTANT SECURITY PRINCIPLE
=========================================================

Update internal accounting
BEFORE external interaction.

=========================================================
CEI PATTERN
=========================================================

---------------------------------------------------------
1. CHECKS
---------------------------------------------------------

Validate conditions.

---------------------------------------------------------
2. EFFECTS
---------------------------------------------------------

Update storage.

---------------------------------------------------------
3. INTERACTIONS
---------------------------------------------------------

External calls LAST.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy SafeBank

---------------------------------------------------------

STEP 2:
Deposit several ETH

---------------------------------------------------------

STEP 3:
Deploy ReentryTester

Input:
SafeBank address

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

Attack fails safely.

---------------------------------------------------------

STEP 7:
Call:
attackCounter()

EXPECTED:
receive() triggered,
but reentrancy unsuccessful.

=========================================================
IMPORTANT AUDITOR UNDERSTANDING
=========================================================

Safe ordering:
reduces reentrancy risk greatly.

---------------------------------------------------------

BUT:
not always sufficient alone.

=========================================================
ADDITIONAL DEFENSES
=========================================================

Modern contracts also use:

- ReentrancyGuard
- pull-payment model
- minimal external calls

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. STATE UPDATED TOO LATE
---------------------------------------------------------

Classic reentrancy issue.

---------------------------------------------------------
2. CROSS-FUNCTION REENTRANCY
---------------------------------------------------------

Different functions interact dangerously.

---------------------------------------------------------
3. CALLBACK MANIPULATION
---------------------------------------------------------

External contracts alter execution.

---------------------------------------------------------
4. UNCHECKED EXTERNAL CALLS
---------------------------------------------------------

Transfer failures ignored.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers search for:

- external calls
- delayed storage updates
- recursive entry points
- callback execution

---------------------------------------------------------

Safe ordering blocks many attacks.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. State before call
2. State after call
3. External execution timing
4. Reentrancy windows
5. Invariant preservation

=========================================================
WHY CEI IS IMPORTANT
=========================================================

CEI reduces exposure to:

- reentrancy
- inconsistent state
- recursive withdrawals
- accounting corruption

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Are effects before interactions?
- Can attacker reenter?
- Is temporary state exposed?
- Are balances updated safely?
- Can callbacks manipulate logic?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add ReentrancyGuard
2. Add event logging
3. Add vulnerable version
4. Compare safe vs unsafe behavior

BONUS:
Create cross-function reentrancy test.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- External calls are dangerous
- State should update before interaction
- CEI pattern improves security
- Reentrancy exploits delayed updates
- Safe ordering reduces attack surface
- External contracts are untrusted
- receive()/fallback() enable callbacks
- Auditors inspect execution order carefully
- Reentrancy depends heavily on timing
- Safer execution prevents many exploits

=========================================================
*/
/*
Title: Reentrancy Vulnerability in vulnerableWithdraw()

Severity: Critical

Reason: External ETH transfer occurs before updating internal balances, allowing attackers to recursively re-enter the contract and drain funds

Location: Contract: SafeBank
          Function: vulnerableWithdraw(uint256 _amount)

Vulnerability Description: The vulnerableWithdraw() function performs an external ETH transfer before updating user balances
(bool success, ) =
    payable(msg.sender).call{
        value: _amount
    }("");

Because control is transferred to msg.sender before the contract updates storage variables, a malicious contract can execute a reentrancy attack through its receive() function

The attacker repeatedly calls: traget.vulnerableWithdraw(1 ether);

Before the victim contract reduces the attacker's balance.

This allows multiple withdrawals using a simgle deposited balance

Impact: An attacker can
- Drain ETH from the contract
- Withdraw more funds than deposited
- Steal funds from honest users
- Cause accounting inconsistencies in totalDeposits
- Potentially empty the entire contract balance

Proof of Concept:
1. Deploy SafeBank
2. Honest users Deposit ETH into the contract
3. Deploy ReentryTester
4. Deposit 1 ETH through: depositToTarget()
5. Start the attack:attackVulnerable()
6. vulnerableWithdraw() sends ETH before updating balances.
7. The attacker's receive() function executes automatically
8. The attacker re-enters: target.valnerableWithdraw(1 ether);
9. Multiple withdrawals occur before storage updates happen
10. The attacker drains additional ETH from the contract

Root Cause: The vulnerability exists because the contract violates the Check-Effects-Interactions pattern.

Recommendation:
1. Use a nonReentrant modifier
2. Follow the Checks-Effects-Interactions pattern.
3. Update balances before external calls.
4.Use secure withdrawal logic in all ETH transfer functions.
5. Emit events for monitoring withdrawals and attack attempts.
*/

// PATCHED CODE

contract SafeBank {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        TRACK TOTAL ETH
    */
    uint256 public totalDeposits;

    // REENTRANCY LOCK
    bool private locked;

    // EVENTS
    event Deposit(address indexed user, uint256 amount);

    event SafeWithdrawEvent(address indexed user, uint256 amount);

    event VulnerableWithdrawEvent(address indexed user, uint256 amount);

    event ReentrancyBlocked(address indexed attacker);

    // REENTRANCY GUARD

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

        /*
            Store user balance.
        */
        balances[msg.sender] += msg.value;

        /*
            Update global accounting.
        */
        totalDeposits += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /*
    =====================================================
    SAFE WITHDRAW
    =====================================================

    Follows:
    Checks -> Effects -> Interactions
    */

    function withdraw(
        uint256 _amount
    )
        external nonReentrant
    {

        /*
        =================================================
        CHECKS
        =================================================

        Validate user balance FIRST.
        */

        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
        =================================================
        EFFECTS
        =================================================

        Update storage BEFORE external call.
        */

        balances[msg.sender] -= _amount;

        totalDeposits -= _amount;

        /*
        =================================================
        INTERACTIONS
        =================================================

        External call happens LAST.
        */

        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        /*
            Ensure ETH transfer succeeded.
        */
        require(
            success,
            "ETH transfer failed"
        );

        emit SafeWithdrawEvent(msg.sender, _amount);
    }

     // VULNERABLE WITHDRAW

    function vulnerableWithdraw(uint256 _amount) external 
    {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        (bool success, ) = payable(msg.sender).call 
        {
            value: _amount
        }("");

        require(success, "ETH transfer failed");

        balances[msg.sender] -= _amount;

        totalDeposits -= _amount;

        emit VulnerableWithdrawEvent(msg.sender, _amount);

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
MALICIOUS TEST CONTRACT
=========================================================
*/

contract ReentryTester {

    /*
        TARGET SAFE CONTRACT
    */
    SafeBank public target;

    /*
        TRACK REENTRY ATTEMPTS
    */
    uint256 public attackCounter;

    // MAX ATTACK LOOPS
    uint256 public constant MAX_ATTACKS = 3;

    // EVENTS

    event AttackStarted(address attacker);

    event Reentered(uint256 attackNumber);

    event AttackFailed();

    event AttackSucceeded(uint256 totalReentries);

    /*
        CONSTRUCTOR
    */
    constructor(address _target)
    {

        target = SafeBank(_target);
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

        target.deposit{value: msg.value}();
    }

    // ATTACK VULNERABLE FUNCTION
    function attackVulnerable() external 
    {
        emit AttackStarted(msg.sender);

        target.vulnerableWithdraw(1 ether);

        emit AttackSucceeded(attackCounter);
    }

    /*
    =====================================================
    ATTACK SAFE FUNCTION
    =====================================================
    */
function attacSafe() external {

    emit AttackStarted(msg.sender);
    try target.withdraw(1 ether) {} 
    catch { emit AttackFailed(); }
}

    /*
    =====================================================
    RECEIVE FUNCTION
    =====================================================

    Attempt reentrancy attack.
    */

    receive()
        external
        payable
    {

        attackCounter++;

        emit Reentered(attackCounter);

        /*
            Try reentering target.
        */
        if (
            address(target).balance >= 1 ether && attackCounter < MAX_ATTACKS) 
        {

            /*
                THIS FAILS SAFELY

                Why?

               due to nonReentrant.
            */
          try target.vulnerableWithdraw(1 ether)  {

            } catch {
                    emit AttackFailed();
            }
        }
    }
}
