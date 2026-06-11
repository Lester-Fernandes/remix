// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: selfdestruct forces ETH into contract
CONCEPT: Forced balance behavior
=========================================================

OBJECTIVE

- Understand how selfdestruct can send ETH to any address
- Learn that ETH can be forced into contracts without payable functions
- Observe balance change without fallback/receive
- Learn historical + modern Ethereum behavior

=========================================================
CORE IDEA
=========================================================

selfdestruct(target) → sends ALL contract ETH to target

IMPORTANT:
No fallback() or receive() is required.

=========================================================
FORCED ETH CONTRACT (TARGET)
=========================================================
*/

// contract VictimContractval {

//     /*
//         This contract CANNOT reject ETH sent via selfdestruct
//     */

//     uint256 public balanceTracker;

//     function update() external payable {
//         balanceTracker += msg.value;
//     }

//     function getBalance() external view returns (uint256) {
//         return address(this).balance;
//     }
// }

// /*
// =========================================================
// ATTACK CONTRACT USING selfdestruct
// =========================================================
// */

// contract ForceEtherSenderval {

//     /*
//     =====================================================
//     FORCE ETH INTO TARGET
//     =====================================================
//     */

//     function forceSend(address payable target) external payable {

//         /*
//             Step 1:
//             Contract receives ETH
//         */

//         /*
//             Step 2:
//             selfdestruct sends ETH to target
//         */

//         selfdestruct(target);
//     }
// }

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy VictimContract

STEP 2:
Deploy ForceEtherSender

STEP 3:
Call:

forceSend(VictimContract, 5 ether)

=========================================================

STEP-BY-STEP RESULT
=========================================================

1. ForceEtherSender holds 5 ETH
2. selfdestruct executed
3. ALL ETH transferred to VictimContract
4. ForceEtherSender is destroyed

=========================================================
IMPORTANT OBSERVATION
=========================================================

VictimContract receives ETH:

- WITHOUT calling receive()
- WITHOUT calling fallback()
- WITHOUT user interaction

=========================================================
STATE IMPACT

address(victim).balance increases

BUT:

balanceTracker DOES NOT update automatically

=========================================================
WHY THIS IS IMPORTANT

Contracts cannot block selfdestruct ETH transfers.

=========================================================
REAL SECURITY IMPLICATIONS

This behavior affects:

- DAO accounting systems
- invariant checks
- balance-based logic
- reward calculations

=========================================================
AUDITOR INSIGHT

Auditors check:

✔ Can contract receive ETH unexpectedly?
✔ Does logic rely on msg.value only?
✔ Are balance assumptions trusted?
✔ Are invariants based on address(this).balance?

=========================================================
MODERN NOTE (IMPORTANT)

In newer Ethereum upgrades:
- selfdestruct behavior is being restricted
- but legacy behavior still matters for audits

=========================================================
COMMON BUGS CAUSED

- stuck accounting mismatches
- reward inflation/deflation bugs
- incorrect total supply assumptions
- invariant breakage in DeFi protocols

=========================================================
KEY TAKEAWAYS

- selfdestruct bypasses receive/fallback
- ETH can be forced into any contract
- balance != accounting state
- protocols must not fully trust address.balance
- forced ETH breaks assumptions in DeFi systems

=========================================================
*/
/*
Title: Forced ETH injection via selfdestruct

Severity: Medium

Vulnerable: selfdestruct(target);
selfdestruct() forcibly transfers ETH to the target contract

This transfer:
- bypasses receive()
- bypasses fallback()
- bypasses payable restrictions
- cannot be rejected

Impact: Attacker can
- maniplulate contract balances
- break accounting assumptions
- interfere with balance-based logic
- invalidate invariant checks

Proof of Concept:
Step 1 — Deploy Victim
VictimContract victim = new VictimContract();
Step 2 — Deposit Normally
victim.update{value: 1 ether}();

State:

Variable	Value
balanceTracker	1 ETH
actual balance	1 ETH
Step 3 — Force ETH

Attacker executes:

forceSend(victim);

using selfdestruct.

Step 4 — State Corruption

Now:

Variable	Value
balanceTracker	1 ETH
actual balance	2 ETH

Accounting mismatch occurs.
*/

// PATCHED CODE

contract SafeVault {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        TRACK ONLY LEGITIMATE DEPOSITS
    */
    uint256 public trackedDeposits;

    /*
        OWNER
    */
    address public owner;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event Deposited(
        address indexed user,
        uint256 amount
    );

    event Withdrawn(
        address indexed user,
        uint256 amount
    );

    event ForcedETHDetected(
        uint256 unexpectedAmount
    );

    event RescueETH(
        uint256 amount
    );

    /*
    =====================================================
    MODIFIER
    =====================================================
    */

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Not owner"
        );
        _;
    }

    /*
    =====================================================
    CONSTRUCTOR
    =====================================================
    */

    constructor() {
        owner = msg.sender;
    }

    /*
    =====================================================
    RECEIVE ETH
    =====================================================

    Accept ETH safely.
    */

    receive()
        external
        payable
    {

    }

    /*
    =====================================================
    SAFE DEPOSIT
    =====================================================
    */

    function deposit()
        external
        payable
    {
        require(
            msg.value > 0,
            "Zero ETH"
        );

        balances[msg.sender] += msg.value;

        trackedDeposits += msg.value;

        emit Deposited(
            msg.sender,
            msg.value
        );
    }

    /*
    =====================================================
    SAFE WITHDRAW
    =====================================================
    */

    function withdraw(
        uint256 amount
    )
        external
    {
        require(
            balances[msg.sender] >= amount,
            "Insufficient balance"
        );

        /*
            CHECKS -> EFFECTS -> INTERACTIONS
        */

        balances[msg.sender] -= amount;

        trackedDeposits -= amount;

        (bool success, ) =
            payable(msg.sender).call{
                value: amount
            }("");

        require(
            success,
            "Transfer failed"
        );

        emit Withdrawn(
            msg.sender,
            amount
        );
    }

    /*
    =====================================================
    DETECT FORCED ETH
    =====================================================

    Compare actual balance vs tracked deposits.
    */

    function detectForcedETH()
        public
        returns (uint256)
    {
        uint256 actualBalance =
            address(this).balance;

        if (
            actualBalance > trackedDeposits
        ) {

            uint256 extra =
                actualBalance -
                trackedDeposits;

            emit ForcedETHDetected(
                extra
            );

            return extra;
        }

        return 0;
    }

    /*
    =====================================================
    RESCUE UNEXPECTED ETH
    =====================================================

    Withdraw ONLY extra forced ETH.
    */

    function rescueForcedETH()
        external
        onlyOwner
    {
        uint256 extra =
            detectForcedETH();

        require(
            extra > 0,
            "No forced ETH"
        );

        (bool success, ) =
            payable(owner).call{
                value: extra
            }("");

        require(
            success,
            "Rescue failed"
        );

        emit RescueETH(extra);
    }

    /*
    =====================================================
    VIEW FUNCTIONS
    =====================================================
    */

    function getActualBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    function getTrackedBalance()
        external
        view
        returns (uint256)
    {
        return trackedDeposits;
    }
}

/*
=========================================================
ATTACK CONTRACT
FORCE SEND ETH USING SELFDESTRUCT
=========================================================
*/

contract ForceEtherSender {

    /*
    =====================================================
    FORCE SEND ETH
    =====================================================
    */

    function forceSend(
        address payable target
    )
        external
        payable
    {

        /*
            Force ETH into target.

            Cannot be blocked.
        */

        selfdestruct(target);
    }
}