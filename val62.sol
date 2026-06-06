// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Chain multiple external calls
CONCEPT: Complex execution
=========================================================

OBJECTIVE

- Learn chained external execution flow
- Understand multi-contract interactions
- Learn failure propagation behavior
- Think like protocol auditor

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

One contract may call:
another contract,
which calls another contract.

---------------------------------------------------------

Execution chains become:

Contract A
    ->
Contract B
    ->
Contract C

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Every external call:

- changes execution context
- changes msg.sender
- creates attack surface
- may revert entire chain

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Modern DeFi heavily relies on:

multi-contract execution chains.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Chained calls appear in:

- swaps
- lending
- flash loans
- routers
- bridges
- multicall systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- nested external calls
- failure propagation
- trust assumptions
- reentrancy windows
- state consistency

=========================================================
CONTRACT C
FINAL TARGET
=========================================================
*/

contract ContractC {

    /*
        TRACK EXECUTION
    */
    uint256 public counter;

    /*
    =====================================================
    FINAL EXECUTION
    =====================================================
    */

    function finalStep()
        external
    {

        /*
            Increment execution counter.
        */
        counter++;
    }

    /*
    =====================================================
    FAILING FUNCTION
    =====================================================
    */

    function failStep()
        external
        pure
    {

        revert("Contract C failure");
    }
}

/*
=========================================================
CONTRACT B
MIDDLE CONTRACT
=========================================================
*/

contract ContractB {

    /*
        STORE CONTRACT C
    */
    ContractC public contractC;

    /*
        TRACK EXECUTION
    */
    uint256 public middleCounter;

    /*
        CONSTRUCTOR
    */
    constructor(address _contractC)
    {

        contractC = ContractC(_contractC);
    }

    /*
    =====================================================
    CALL CONTRACT C
    =====================================================
    */

    function callFinalStep()
        external
    {

        /*
            Local state update.
        */
        middleCounter++;

        /*
            EXTERNAL CALL:
            Contract B -> Contract C
        */
        contractC.finalStep();
    }

    /*
    =====================================================
    CALL FAILING FUNCTION
    =====================================================
    */

    function callFailingStep()
        external
    {

        /*
            State update.
        */
        middleCounter++;

        /*
            External call that reverts.
        */
        contractC.failStep();
    }
}

/*
=========================================================
CONTRACT A
ENTRY CONTRACT
=========================================================
*/

contract ContractA {

    /*
        STORE CONTRACT B
    */
    ContractB public contractB;

    /*
        TRACK EXECUTION
    */
    uint256 public entryCounter;

    /*
        CONSTRUCTOR
    */
    constructor(address _contractB)
    {

        contractB = ContractB(_contractB);
    }

    /*
    =====================================================
    START EXECUTION CHAIN
    =====================================================
    */

    function startChain()
        external
    {

        /*
            Local state update.
        */
        entryCounter++;

        /*
            EXTERNAL CALL:
            Contract A -> Contract B
        */
        contractB.callFinalStep();
    }

    /*
    =====================================================
    START FAILING CHAIN
    =====================================================
    */

    function startFailingChain()
        external
    {

        /*
            State update.
        */
        entryCounter++;

        /*
            Nested call chain eventually fails.
        */
        contractB.callFailingStep();
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

DEPLOY ORDER:

1. Deploy ContractC
2. Deploy ContractB
3. Deploy ContractA

---------------------------------------------------------

Constructor wiring:

ContractB -> ContractC
ContractA -> ContractB

=========================================================
TRACE:
startChain()
=========================================================

STEP 1:
User calls:

ContractA.startChain()

=========================================================
STEP 2
=========================================================

ContractA updates storage.

---------------------------------------------------------

entryCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
STEP 3
=========================================================

External call:

ContractA
    ->
ContractB.callFinalStep()

=========================================================
STEP 4
=========================================================

Execution enters:
ContractB

---------------------------------------------------------

middleCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
STEP 5
=========================================================

Another external call:

ContractB
    ->
ContractC.finalStep()

=========================================================
STEP 6
=========================================================

Execution enters:
ContractC

---------------------------------------------------------

counter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
FINAL RESULT
=========================================================

All contracts updated successfully.

---------------------------------------------------------

ContractA.entryCounter = 1

ContractB.middleCounter = 1

ContractC.counter = 1

=========================================================
IMPORTANT EXECUTION UNDERSTANDING
=========================================================

Execution CONTEXT switches
during every external call.

=========================================================
msg.sender FLOW
=========================================================

---------------------------------------------------------
Inside ContractA
---------------------------------------------------------

msg.sender = User

---------------------------------------------------------
Inside ContractB
---------------------------------------------------------

msg.sender = ContractA

---------------------------------------------------------
Inside ContractC
---------------------------------------------------------

msg.sender = ContractB

=========================================================
VERY IMPORTANT
=========================================================

msg.sender changes at EACH hop.

=========================================================
FAILING CHAIN TRACE
=========================================================

CALL:
startFailingChain()

=========================================================

STEP 1:
ContractA updates:

entryCounter++

=========================================================
STEP 2
=========================================================

ContractA calls:
ContractB

=========================================================
STEP 3
=========================================================

ContractB updates:

middleCounter++

=========================================================
STEP 4
=========================================================

ContractB calls:
ContractC.failStep()

=========================================================
STEP 5
=========================================================

ContractC reverts:

"Contract C failure"

=========================================================
IMPORTANT
=========================================================

Revert propagates upward.

---------------------------------------------------------

ContractC
    ->
ContractB
    ->
ContractA

=========================================================
FINAL RESULT
=========================================================

ENTIRE transaction reverts.

---------------------------------------------------------

ALL previous state updates rollback.

=========================================================
ROLLBACK OBSERVATION
=========================================================

Even though:

entryCounter++

and

middleCounter++

already executed,

---------------------------------------------------------

ALL changes revert atomically.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy ContractC

---------------------------------------------------------

STEP 2:
Deploy ContractB

Input:
ContractC address

---------------------------------------------------------

STEP 3:
Deploy ContractA

Input:
ContractB address

---------------------------------------------------------

STEP 4:
Call:
startChain()

---------------------------------------------------------

STEP 5:
Check all counters

EXPECTED:
all incremented

=========================================================
STEP 6
=========================================================

Call:
startFailingChain()

---------------------------------------------------------

EXPECTED:
full transaction revert

=========================================================
STEP 7
=========================================================

Check counters again.

---------------------------------------------------------

IMPORTANT:
No new increments occurred.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Nested external calls create:

---------------------------------------------------------
COMPLEX EXECUTION FLOW
---------------------------------------------------------

and

---------------------------------------------------------
LARGER ATTACK SURFACE
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

Nested calls may reenter earlier contracts.

---------------------------------------------------------
2. FAILURE PROPAGATION
---------------------------------------------------------

One revert breaks entire chain.

---------------------------------------------------------
3. msg.sender CONFUSION
---------------------------------------------------------

Authentication assumptions fail.

---------------------------------------------------------
4. TRUST ASSUMPTIONS
---------------------------------------------------------

External contracts may behave maliciously.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers abuse:

- nested execution
- callback chains
- external state assumptions
- recursive interactions

---------------------------------------------------------

Complexity increases risk heavily.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors trace:

- every external jump
- every state mutation
- every revert path
- msg.sender transitions
- reentrancy windows

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors build:

---------------------------------------------------------
FULL EXECUTION GRAPH
---------------------------------------------------------

to understand:

- control flow
- state dependencies
- attack surface

=========================================================
WHY COMPLEXITY IS DANGEROUS
=========================================================

More external calls =
more assumptions.

---------------------------------------------------------

More assumptions =
more vulnerabilities.

=========================================================
MINI CHALLENGE
=========================================================

Modify contracts so that:

1. Add ETH transfers
2. Add low-level call()
3. Add try/catch handling
4. Add malicious reentrant contract

BONUS:
Create mini DeFi router chain.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Contracts can chain external calls
- msg.sender changes across contracts
- Nested execution increases complexity
- Reverts propagate upward
- Transactions rollback atomically
- External calls create attack surface
- Multi-contract systems are harder to audit
- Auditors trace full execution chains
- Complex execution increases security risk
- Inter-contract trust assumptions matter heavily

=========================================================
*/
/*
Audit Report
Title: Unsafe Low-Level Calls and Reentrancy Risk in Nested Contract Chain

Severity: High

Reason:
The Protocol performs external low-level calls nd ETH transfers across multiple
contracts without implementing proper reentrancy protection or strict
validation patterns.

Location:
Contract: Contract B
Function: callFinalStep()

Contract: MaliciousReentrant
Function: receive()

Vulnerability Description:
The ContractB contract uses low-level call() to invoke ContractC.finalStep() while
forwarding ETH

Example:
(bool success, bytes memory data) =
address(contractC).call{value: msg.value}(
    abi.encodeWithSignature(
        "finalStep()"
    )
    );
Although success is checked, the system does not implement:

reentrancy guards
checks-effects-interactions pattern
call-depth protection

A malicious contract can exploit demonstrares how recursive receive()
execution can repeatedly triger:

target.startChain{value: 1 ether}();

Impact:
An attacker could:

trigger recrsive execution
drain ETH from protocol contracts
cause denial-of-service conditions
manipulate execution counters
consume excessive gas

If integrated into real DeFi logic, this could lead to:

fund loss
pool imbalance
protocol insolvency

Proof of Concept:

Deploy:
Contract C
Contract B
Contract A
MaliciousReentrant

Fund ContractA with ETH.

Call:
attack()

The malicious receive() function recursively reentants:
startChain()

Repeated nested execution occurs until gas exhaustion or balance depletion.

Root Cause:

The protocol performs external ETH calls before finalizing execution safety.

Issues Include:

Usage of low-level call()
external interaction without reentrancy guard
recursive receive() callback exposure

Recommendation:
Implement ReentrancyGuard.
Example:
modifier nonReentrant() {
    require(!locked, "Reentrant");
    locked = true;
    _;
    locked = false;
}

Apply checks-effects-interactions pattern.

Avoid recursive ETH-triggered execution paths.

*/

//PATCHED CODE:


contract SecureContractB {

bool internal locked;

ContractC public contractC;

modifier nonReentrant() {
    require(!locked, "Reentrant");
    locked = true;
    _;
    locked = false;
}

constructor(address _contractC) {
    contractC = ContractC(_contractC);
}

function callFinalStep()
    external
    payable
    nonReentrant
{
    (bool success,) =
        address(contractC).call{
            value: msg.value
        }(
            abi.encodeWithSignature(
                "finalStep()"
            )
        );

    require(
        success,
        "Low-level call failed"
    );
}

}