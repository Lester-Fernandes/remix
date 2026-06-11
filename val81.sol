// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Storage Collision Demo
CONCEPT: Upgrade/Proxy Risk (delegatecall mismatch)
=========================================================

OBJECTIVE

- Understand storage layout collision in proxy patterns
- See how delegatecall can corrupt state
- Learn why upgradeable contracts are dangerous if misaligned
- Observe proxy vs logic storage interaction

=========================================================
CORE IDEA
=========================================================

delegatecall uses CALLER STORAGE.

If storage layouts differ between:
- Proxy contract
- Logic contract

→ storage collision occurs ❌

=========================================================
VULNERABLE LOGIC CONTRACT (V1)
=========================================================
*/

contract LogicV1val {

    // SLOT 0
    uint256 public value;

    // SLOT 1
    address public owner;

    function setValue(uint256 _value) external {
        value = _value;
    }

    function setOwner(address _owner) external {
        owner = _owner;
    }
}

/*
=========================================================
PROXY CONTRACT (WRONG STORAGE LAYOUT)
=========================================================
*/

contract ProxyBad {

    /*
        ❌ STORAGE MISMATCH STARTS HERE
    */

    // SLOT 0 (EXPECTED: maybe admin)
    address public admin;

    // SLOT 1 (EXPECTED: implementation)
    address public implementation;

    /*
        BUT LogicV1 expects:
        slot0 = value
        slot1 = owner
    */

    constructor(address _impl) {
        admin = msg.sender;
        implementation = _impl;
    }

    /*
    =====================================================
    DELEGATECALL EXECUTION
    =====================================================
    */

    function setValue(uint256 _value) external {

        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature(
                "setValue(uint256)",
                _value
            )
        );

        require(success, "delegatecall failed");
    }

    function setOwner(address _owner) external {

        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature(
                "setOwner(address)",
                _owner
            )
        );

        require(success, "delegatecall failed");
    }
}

/*
=========================================================
ATTACK / COLLISION RESULT
=========================================================

CALL:
setValue(100)

=========================================================

LogicV1 executes:

value = 100

BUT STORAGE ACTUALLY WRITES INTO PROXY:

slot0 → admin ❌ overwritten

=========================================================

CALL:
setOwner(attacker)

=========================================================

LogicV1 executes:

owner = attacker

BUT STORAGE WRITES INTO:

slot1 → implementation ❌ overwritten

=========================================================
FINAL BROKEN STATE IN PROXY
=========================================================

admin         = 100 (CORRUPTED)
implementation = attacker address (BROKEN)
value         = NOT stored correctly
owner         = attacker (misplaced slot)

=========================================================
💥 THIS IS STORAGE COLLISION
=========================================================

Logic assumes one layout
Proxy has another layout

→ delegatecall causes memory mismatch

=========================================================
WHY THIS IS CRITICAL
=========================================================

This leads to:

- admin takeover
- implementation hijack
- proxy corruption
- full protocol compromise

=========================================================
SECURE PATTERN (FIX IDEA)
=========================================================

Use consistent storage layout:

---------------------------------------------------------
Proxy:
slot0 = implementation
slot1 = admin
---------------------------------------------------------

OR use OpenZeppelin standard proxies:
- Transparent Proxy
- UUPS Proxy

=========================================================
SAFE PROXY EXAMPLE (CONCEPT ONLY)
=========================================================
*/

contract ProxySafe {

    // MUST MATCH expected layout carefully
    address public implementation;
    address public admin;

    constructor(address _impl) {
        implementation = _impl;
        admin = msg.sender;
    }

    function setValue(uint256 _value) external {
        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        require(success);
    }
}

/*
=========================================================
KEY SECURITY INSIGHTS
=========================================================

- delegatecall shares storage with proxy
- storage slot order MUST match exactly
- mismatch = silent corruption (very dangerous)
- upgradeable contracts require strict layout control

=========================================================
AUDITOR CHECKLIST
=========================================================

✔ Does proxy and logic share identical storage layout?
✔ Are new variables appended safely?
✔ Is upgrade mechanism controlled?
✔ Is implementation address protected?
✔ Is storage collision possible via delegatecall?

=========================================================
REAL-WORLD IMPACT
=========================================================

Many DeFi hacks come from:

- broken upgradeable proxies
- storage slot mismatch
- unsafe delegatecall usage
- logic contract upgrades without layout checks

=========================================================
KEY TAKEAWAYS
=========================================================

- delegatecall = shared storage execution
- storage order matters more than logic
- mismatch causes silent corruption
- proxy patterns must be strictly standardized

=========================================================
*/
/*
Title: Storage layout collision in proxyBAd using delegatecall()

Severity: Critical

Reason: The proxy contract storage layout does not match the logic contract storage layout.  Because delegatecall() executes logic contract code inside the proxy storage context, mismatched storage slots cause unintended storage overwrites.

Location: Vulnerable Contract: ProxyBad

          Affected Functions: setValue(uint256)
                    setOwner(address)
          External Logic Contract: LogicV1

Vulnerability Description: The proxyBad contract uses delegatecall() to execute function from LogicV1. However the storage layout between both contracts is different

Impact: An attacker can overwrite critical proxy variables
- admin takeover
- implementation replacement
- malicious upgrade injection
- permanent storage corruption
- full protocol compromise

Proof of concept:
Step 1 — Deploy LogicV1
contract LogicV1 {

    uint256 public value;
    address public owner;

    function setValue(uint256 _value) external {
        value = _value;
    }

    function setOwner(address _owner) external {
        owner = _owner;
    }
}
Step 2 — Deploy ProxyBad

Constructor sets:

admin = deployer;
implementation = logicAddress;
Step 3 — Call
setValue(999)

via proxy.

Actual Result

Because value maps to SLOT 0:

admin = address(uint160(999))

Admin storage becomes corrupted.

Step 4 — Call
setOwner(attackerAddress)
Actual Result

Because owner maps to SLOT 1:

implementation = attackerAddress

The proxy now points to malicious logic.

Root Cause: The vulnerability exists because:
- delegatecall() shares caller storage
- proxy storage layout differs from logic layout
- no reserved storage slot strategy is used
- no upgrade-safe proxy architecture implemented


*/

// PATCHED CODE

/*
=========================================================
LOGIC CONTRACT
=========================================================
*/

contract LogicV1 {

    // SLOT 0
    uint256 public value;

    // SLOT 1
    address public owner;

    function setValue(
        uint256 _value
    )
        external
    {
        value = _value;
    }

    function setOwner(
        address _owner
    )
        external
    {
        owner = _owner;
    }
}

/*
=========================================================
SAFE PROXY CONTRACT
=========================================================
*/

contract ProxyGood {

    /*
        STORAGE LAYOUT MATCHES LOGIC

        SLOT 0 -> value
        SLOT 1 -> owner
    */

    uint256 public value;

    address public owner;

    /*
        NEW VARIABLES ADDED AFTER
        EXISTING STORAGE LAYOUT
    */

    address public implementation;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event DelegateExecuted(
        string functionName,
        bool success
    );

    /*
    =====================================================
    CONSTRUCTOR
    =====================================================
    */

    constructor(
        address _implementation
    ) {

        owner = msg.sender;

        implementation =
            _implementation;
    }

    /*
    =====================================================
    SET VALUE
    =====================================================
    */

    function setValue(
        uint256 _value
    )
        external
    {

        (
            bool success,
        ) =
            implementation.delegatecall(abi.encodeWithSignature("setValue(uint256)",_value ) );

        emit DelegateExecuted("setValue", success);

        require(success,"delegatecall failed" );
    }

    /*
    =====================================================
    SET OWNER
    =====================================================
    */

    function setOwner(
        address _owner
    )
        external
    {

        (
            bool success,
        ) =
            implementation.delegatecall(
                abi.encodeWithSignature(
                    "setOwner(address)",
                    _owner
                )
            );

        emit DelegateExecuted(
            "setOwner",
            success
        );

        require(
            success,
            "delegatecall failed"
        );
    }
}