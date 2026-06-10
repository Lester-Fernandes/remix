// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: delegatecall Demo
CONCEPT: Context execution (storage of caller contract)
=========================================================

OBJECTIVE

- Understand delegatecall execution model
- See how storage of caller contract is modified
- Learn why delegatecall is powerful AND dangerous
- Observe context (msg.sender, msg.value, storage)

=========================================================
CORE IDEA
=========================================================

delegatecall:

- runs code from another contract
- BUT uses caller’s storage, msg.sender, msg.value

=========================================================
KEY DIFFERENCE

call        → changes callee storage
delegatecall → changes caller storage ❗

=========================================================
LIBRARY CONTRACT (LOGIC ONLY)
=========================================================
*/

contract LogicContractval {

    // NOTE: storage layout MUST match caller
    uint256 public num;
    address public sender;

    /*
    =====================================================
    SET FUNCTION (RUNS IN CALLER CONTEXT)
    =====================================================
    */

    function set(uint256 _num) external payable {

        /*
            These variables actually belong to CALLER
            when used via delegatecall
        */

        num = _num;
        sender = msg.sender;
    }
}

/*
=========================================================
CALLER CONTRACT (STATE HOLDER)
=========================================================
*/

contract ProxyContract {

    uint256 public num;
    address public sender;

    /*
        Address of logic contract
    */
    address public logic;

    constructor(address _logic) {
        logic = _logic;
    }

    /*
    =====================================================
    DELEGATECALL EXECUTION
    =====================================================
    */

    function setViaDelegate(uint256 _num) external payable {

        (bool success, ) = logic.delegatecall(
            abi.encodeWithSignature(
                "set(uint256)",
                _num
            )
        );

        require(success, "delegatecall failed");
    }
}

/*
Title: Unsafe delegatecall() Usage in ProxyContract

Severity: High

Reason: delegatecall() executes external contract code inside the storage context of the caller contract
If the logic contract is malicious, compromised or incorrectly upgraded, it can overwrite the proxy contract's storage and fully control contract behavior

Location: Contract: ProxyContract
          Function: setViaDelegate(uint256 _num)

Vulnerability Description: The proxyContract uses delegatecall() to execute the set() function from LogicContract
(bool success, ) = logic.delegatecall(
    abi.encodeWithSignature(
        "set(uint256)",
        _num
    )
);

During delegatecall()
- storage changes affect the proxycontract
- msg.sender remains the original caller
- External logic executes with full storage access
This creates a dangerous trust dependency on the logic contract

If the logic contract contains malicious code it can
- overwrite ownership variables
- destroy storage
- steal ETH
- executes arbitrary logic

Impact: An attacker controlling the logic contract can manipulate the proxy contract state
Possible consequences include:
- unauthorized ownership takeover
- storage corruption
- permanent protocol damage
- arbitrary ETH withdrawals
- malicious upgrades
Because delegatecall() executes with caller storage privileges the proxy becomes fully dependent on the security of the logic contract

Proof of Concept:
Step 1 — Deploy LogicContract
contract LogicContract {

    uint256 public num;
    address public sender;

    function set(uint256 _num) external payable {
        num = _num;
        sender = msg.sender;
    }
}
Step 2 — Deploy ProxyContract

Constructor stores logic contract address.

Step 3 — Call:
setViaDelegate(999)
Result

Storage inside ProxyContract changes:

num = 999
sender = external caller

Even though execution code exists inside LogicContract.

This proves that delegatecall() modifies caller storage.

Root Cause: The vulnerability exists because
- delegatecall() executes external code using caller storage
- proxy fully trusts external logic contract
- no access control exists for logic upgrades
- no validation of delegatecall target
- storage layout dependency is dangerous

*/

// PATCHED CODE

// SAFE LOGIC CONTRACT
contract LogicContract
{
    uint256 public num;

    address public sender;

    event ValueUpdated(address caller, uint256 value);

    function set(uint256 _num) external payable 
    {
        num = _num;

        sender = msg.sender;

        emit ValueUpdated(msg.sender, _num);
    }
}

// SAFE PROXY CONTRACT
contract SafeProxyContract
{
    uint256 public num;

    address public sender;

    address public owner;

    // LOGIC CONTRACT
    address public logic;

    // EVENTS
    event DelegateExecuted(address caller, uint256 value);

    event LogicUpdated(address oldLogic, address newLogic);

    // CONSTRUCTOR

    constructor(address _logic)
    {
        owner = msg.sender;

        logic = _logic;
    }

    // ONLY OWNER MODIFIER
    modifier onlyOwner()
    {
        require(msg.sender == owner, "Not owner"); _;
    }

    // UPDATE LOGIC CONTRACT
    function updateLogic(address _newLogic) external onlyOwner
    {
        require(_newLogic != address(0), "Invalid address");

        emit LogicUpdated(logic, _newLogic);
    }
    
    // SAFE DELEGATECALL
    function setViaDelegate(uint256 _num) external payable 
    {
        require(logic != address(0),"Logic not set");

        (bool success, bytes memory data) = logic.delegatecall(abi.encodeWithSignature("set(uint256", _num));

        require(success, "delegatecall failed");

        data;

        emit DelegateExecuted(msg.sender, _num);
    }

    // VIEW CONTRACT BALANCE
    function getBalace() external view returns (uint256)
    {
        return address(this).balance;
    }
}