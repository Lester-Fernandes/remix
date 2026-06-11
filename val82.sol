// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Simple Proxy Contract
CONCEPT: Upgradeable architecture (basic delegatecall proxy)
=========================================================

OBJECTIVE

- Understand proxy + implementation pattern
- Learn how upgrades work using delegatecall
- Separate logic (implementation) from storage (proxy)
- Build minimal upgradeable architecture

=========================================================
CORE IDEA
=========================================================

Proxy holds:
- storage
- implementation address

Logic contract holds:
- functions (code only)

Proxy executes logic via delegatecall.

=========================================================
IMPORTANT RULE

delegatecall = logic runs, but storage belongs to proxy

=========================================================
IMPLEMENTATION CONTRACT (LOGIC V1)
=========================================================
*/

contract LogicV1val {

    /*
        NOTE:
        These variables are stored in PROXY storage
    */

    uint256 public value;
    address public owner;

    function initialize(address _owner) external {
        owner = _owner;
    }

    function setValue(uint256 _value) external {
        value = _value;
    }
}

/*
=========================================================
IMPLEMENTATION CONTRACT (LOGIC V2 - UPGRADE)
=========================================================
*/

contract LogicV2val {

    /*
        MUST match storage layout of V1
    */

    uint256 public value;
    address public owner;

    function setValue(uint256 _value) external {
        value = _value * 2; // upgraded logic
    }

    function setValueIncrement(uint256 _value) external {
        value = value + _value;
    }
}

/*
=========================================================
PROXY CONTRACT (STORAGE OWNER)
=========================================================
*/

contract SimpleProxyval {

    /*
        STORAGE LAYOUT
    */

    address public implementation;
    address public admin;

    /*
    =====================================================
    CONSTRUCTOR
    =====================================================
    */

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    /*
    =====================================================
    UPGRADE FUNCTION
    =====================================================
    */

    function upgrade(address _newImplementation) external {
        require(msg.sender == admin, "Not admin");
        implementation = _newImplementation;
    }

    /*
    =====================================================
    DELEGATECALL FALLBACK EXECUTION
    =====================================================
    */

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    /*
    =====================================================
    INTERNAL DELEGATECALL
    =====================================================
    */

    function _delegate() internal {

        address impl = implementation;

        assembly {
            /*
                Copy calldata
            */
            calldatacopy(0, 0, calldatasize())

            /*
                delegatecall:
                gas, implementation, input, output
            */
            let result := delegatecall(
                gas(),
                impl,
                0,
                calldatasize(),
                0,
                0
            )

            /*
                Copy return data
            */
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1: DEPLOY

1. Deploy LogicV1
2. Deploy SimpleProxy with LogicV1 address

=========================================================
STEP 2: INITIALIZE VIA PROXY

CALL:
proxy.call("initialize(address)", owner)

=========================================================

delegatecall happens:
- LogicV1 runs
- Proxy storage updated

Proxy storage becomes:
owner = set owner

=========================================================
STEP 3: SET VALUE (V1 LOGIC)

CALL:
proxy.call("setValue(uint256)", 10)

RESULT:
value = 10 (stored in proxy)

=========================================================
STEP 4: UPGRADE LOGIC

CALL:
upgrade(LogicV2 address)

Only admin can upgrade.

=========================================================
STEP 5: NEW LOGIC EXECUTION

CALL:
proxy.call("setValue(uint256)", 10)

NOW:

LogicV2 runs:
value = 20 (10 * 2)

=========================================================
WHY THIS WORKS

- Storage stays in proxy
- Logic can be swapped anytime
- State remains unchanged across upgrades

=========================================================
IMPORTANT SECURITY INSIGHTS

✔ Proxy holds storage
✔ Logic holds behavior
✔ delegatecall connects both
✔ upgrade changes behavior only

=========================================================
AUDITOR RISKS

- storage collision
- unauthorized upgrade
- broken initialization
- delegatecall injection
- unsafe implementation switching

=========================================================
BEST PRACTICES

- protect upgrade function (onlyOwner / timelock)
- ensure storage layout compatibility
- use audited proxy patterns (UUPS / Transparent)
- never expose implementation directly

=========================================================
KEY TAKEAWAYS

- proxy = storage layer
- implementation = logic layer
- delegatecall = execution bridge
- upgrade = swap logic, not state
- storage safety is critical

=========================================================
*/
/*
Title:Upgradeable proxy architecture using delegatecall()

Seveerity: High 

Reason: The contract implements a minimal upgradeable proxy architecture using delegatecall().

This pattern allows:
- upgrading logic contracts
- preserving proxy storage
- separating logic from state

Location: Contracts: LogicV1
                     LogicV2
                     SimpleProxy
          Critical Function: _delegate()

Vnlnerability Description: The proxy uses raw assembly based delegatecall() forwarding
let result := delegatecall(
    gas(),
    impl,
    0,
    calldatasize(),
    0,
    0
)

This architecture is powerful but dangerous.

Any implementation contract executed through delegatecall() gains full write access to proxy storage.

Impact: 
Calling: setValue()

through proxy overwrites: implementation

Calling: initialize()

overwrites: admin

This may lead to:
- proxy takeover
- malicious upgrades
- permanent protocol compromise
- delegatecall hijacking
- denial of service

Proof of Concept:
Step 1 — Deploy LogicV1
Step 2 — Deploy SimpleProxy

Constructor sets:

implementation = logicV1
admin = deployer
Step 3 — Call Proxy
setValue(999)

via proxy ABI.

Result

Inside proxy storage:

implementation = address(uint160(999))

Proxy implementation becomes corrupted.

Step 4 — Call
initialize(attacker)
Result
admin = attacker

Attacker becomes proxy admin.

Root Cause: The vulnerability exists because:
- proxy storage layout differs from logic layout
- delegatecall writes into proxy storage
- no EIP-1967 storage slot separation used
- raw delegatecall forwarding implemented
- upgrade safety check missing

*/

// PATCHED CODE

/*
=========================================================
SAFE LOGIC V1
=========================================================
*/

contract LogicV1 {

    /*
        STORAGE LAYOUT
        MUST MATCH PROXY
    */

    uint256 public value;
    address public owner;

    bool internal initialized;

    event ValueUpdated(uint256 value);

    function initialize(
        address _owner
    )
        external
    {

        require(
            !initialized,
            "Already initialized"
        );

        owner = _owner;

        initialized = true;
    }

    function setValue(
        uint256 _value
    )
        external
    {

        value = _value;

        emit ValueUpdated(
            _value
        );
    }
}

/*
=========================================================
SAFE LOGIC V2
=========================================================
*/

contract LogicV2 {

    uint256 public value;
    address public owner;

    bool internal initialized;

    event ValueUpdated(uint256 value);

    function setValue(
        uint256 _value
    )
        external
    {

        value = _value * 2;

        emit ValueUpdated(
            value
        );
    }

    function setValueIncrement(
        uint256 _value
    )
        external
    {

        value =
            value + _value;

        emit ValueUpdated(
            value
        );
    }
}

/*
=========================================================
SAFE PROXY CONTRACT
=========================================================
*/

contract SafeProxy {

    /*
        STORAGE LAYOUT
        MATCHES IMPLEMENTATION
    */

    uint256 public value;
    address public owner;
    bool internal initialized;

    /*
        PROXY VARIABLES
        ADDED AFTER LOGIC STORAGE
    */

    address public implementation;
    address public admin;

    /*
    =====================================================
    EVENTS
    =====================================================
    */

    event Upgraded(
        address implementation
    );

    /*
    =====================================================
    CONSTRUCTOR
    =====================================================
    */

    constructor(
        address _implementation
    ) {

        implementation =
            _implementation;

        admin = msg.sender;
    }

    /*
    =====================================================
    ONLY ADMIN
    =====================================================
    */

    modifier onlyAdmin() {

        require(
            msg.sender == admin,
            "Not admin"
        );

        _;
    }

    /*
    =====================================================
    UPGRADE IMPLEMENTATION
    =====================================================
    */

    function upgrade(
        address _newImplementation
    )
        external
        onlyAdmin
    {

        require(
            _newImplementation !=
            address(0),
            "Invalid implementation"
        );

        implementation =
            _newImplementation;

        emit Upgraded(
            _newImplementation
        );
    }

    /*
    =====================================================
    FALLBACK
    =====================================================
    */

    fallback()
        external
        payable
    {
        _delegate();
    }

    receive()
        external
        payable
    {
        _delegate();
    }

    /*
    =====================================================
    INTERNAL DELEGATE
    =====================================================
    */

    function _delegate()
        internal
    {

        address impl = implementation;

        require(
            impl != address(0),
            "Implementation missing"
        );

        assembly {

            calldatacopy(0,0,calldatasize() )

            let result :=
                delegatecall(
                    gas(),
                    impl,
                    0,
                    calldatasize(),
                    0,
                    0
                )

            returndatacopy(0,0,returndatasize() )

            switch result

            case 0 {

                revert(
                    0,
                    returndatasize()
                )
            }

            default {

                return(
                    0,
                    returndatasize()
                )
            }
        }
    }
}