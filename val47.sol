// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Emit events during execution
CONCEPT: Execution tracking
=========================================================

OBJECTIVE

- Learn how Solidity events work
- Understand execution tracking through logs
- Learn event emission flow
- Understand off-chain monitoring architecture

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Events create blockchain logs.

These logs help:
- frontend apps
- indexers
- explorers
- monitoring systems

track contract activity.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Events are NOT contract storage.

They are stored inside:
transaction logs.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Without events:
off-chain systems cannot efficiently
track contract activity.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Events used in:

- ERC20 transfers
- NFT minting
- swaps
- staking
- governance voting
- liquidations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- missing events
- incorrect event ordering
- misleading logs
- sensitive-data leakage
- inconsistent state vs event emission

=========================================================
*/

contract EventExecutionTrackingval {

    /*
        STORAGE VARIABLES
    */
    mapping(address => uint256) public balances;

    uint256 public totalDeposits;

    /*
    =====================================================
    EVENT DEFINITIONS
    =====================================================

    Events create blockchain logs.
    */

    event DepositStarted(
        address indexed user,
        uint256 amount
    );

    event BalanceUpdated(
        address indexed user,
        uint256 newBalance
    );

    event DepositCompleted(
        address indexed user,
        uint256 amount,
        uint256 totalDeposits
    );

    event ExecutionFailed(
        address indexed user,
        string reason
    );

    /*
    =====================================================
    DEPOSIT FUNCTION
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Emit execution-start event.
        */
        emit DepositStarted(
            msg.sender,
            _amount
        );

        /*
            STEP 2:
            Validate input.
        */
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 100,
            "Amount too large"
        );

        /*
            STEP 3:
            Update storage.
        */
        balances[msg.sender] += _amount;

        /*
            STEP 4:
            Emit balance-update event.
        */
        emit BalanceUpdated(
            msg.sender,
            balances[msg.sender]
        );

        /*
            STEP 5:
            Update global storage.
        */
        totalDeposits += _amount;

        /*
            STEP 6:
            Emit completion event.
        */
        emit DepositCompleted(
            msg.sender,
            _amount,
            totalDeposits
        );
    }

    /*
    =====================================================
    MANUAL FAILURE TRACKING
    =====================================================
    */

    function validateNumber(
        uint256 _number
    )
        external
    {

        /*
            Emit failure event before revert.
        */
        if (_number > 10) {

            emit ExecutionFailed(
                msg.sender,
                "Number too large"
            );

            revert("Validation failed");
        }
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
emit DepositStarted()

---------------------------------------------------------

LOG CREATED:

user = Alice
amount = 50

---------------------------------------------------------

STEP 2:
Validation checks pass.

---------------------------------------------------------

STEP 3:
Storage updated.

balances[Alice] += 50

---------------------------------------------------------

STEP 4:
emit BalanceUpdated()

---------------------------------------------------------

LOG CREATED:

newBalance = 50

---------------------------------------------------------

STEP 5:
totalDeposits += 50

---------------------------------------------------------

STEP 6:
emit DepositCompleted()

---------------------------------------------------------

LOG CREATED:

amount = 50
totalDeposits = 50

---------------------------------------------------------

TRANSACTION SUCCEEDS

=========================================================
IMPORTANT EVENT UNDERSTANDING
=========================================================

Events are stored in:
transaction logs.

---------------------------------------------------------

NOT inside contract storage.

=========================================================
EVENTS VS STORAGE
=========================================================

---------------------------------------------------------
STORAGE
---------------------------------------------------------

- readable on-chain
- expensive
- persistent state

---------------------------------------------------------
EVENTS
---------------------------------------------------------

- cheaper
- optimized for off-chain reading
- not readable by contracts

=========================================================
IMPORTANT REVERT BEHAVIOR
=========================================================

If transaction reverts:

ALL emitted events disappear.

---------------------------------------------------------

Very important EVM property.

=========================================================
REVERT TRACE
=========================================================

CALL:
validateNumber(50)

=========================================================

STEP 1:
emit ExecutionFailed()

---------------------------------------------------------

Temporary log created.

---------------------------------------------------------

STEP 2:
revert()

---------------------------------------------------------

TRANSACTION REVERTS

---------------------------------------------------------

EVENT LOG ALSO REMOVED

---------------------------------------------------------

FINAL RESULT:

NO event persists on-chain.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Open:
Deployed Contracts panel

---------------------------------------------------------

STEP 3:
Call:
deposit(50)

---------------------------------------------------------

STEP 4:
Open transaction log section

---------------------------------------------------------

OBSERVE EVENTS:

- DepositStarted
- BalanceUpdated
- DepositCompleted

---------------------------------------------------------

STEP 5:
Call:
deposit(500)

EXPECTED:
Revert

---------------------------------------------------------

OBSERVE:
No events persist after revert.

---------------------------------------------------------

STEP 6:
Call:
validateNumber(50)

EXPECTED:
Revert

---------------------------------------------------------

OBSERVE:
ExecutionFailed event disappears too.

=========================================================
IMPORTANT INDEXED UNDERSTANDING
=========================================================

indexed parameters:

allow efficient filtering/searching.

---------------------------------------------------------

Example:

event Deposit(
    address indexed user,
    uint amount
)

---------------------------------------------------------

Frontend can efficiently search:
all events for specific user.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. MISSING EVENTS
---------------------------------------------------------

Critical actions not trackable.

---------------------------------------------------------
2. MISLEADING EVENTS
---------------------------------------------------------

Event says success,
but state update failed.

---------------------------------------------------------
3. EVENT BEFORE EXTERNAL CALL
---------------------------------------------------------

May create misleading logs.

---------------------------------------------------------
4. SENSITIVE DATA LEAKAGE
---------------------------------------------------------

Events are publicly visible forever.

=========================================================
GAS OBSERVATION
=========================================================

Events:
cost less gas than storage.

---------------------------------------------------------

Indexed fields:
slightly more expensive.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Are critical actions logged?
- Do events match state changes?
- Can events mislead monitoring systems?
- Is sensitive data exposed?
- Are events emitted in correct order?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Malformed event emitted before revert.

Off-chain bots incorrectly react.

---------------------------------------------------------

ANOTHER RISK

Missing liquidation event
prevents monitoring systems
from detecting dangerous activity.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Event emission order
2. State updates
3. Revert behavior
4. Off-chain monitoring assumptions
5. Event consistency

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add Withdraw event
2. Add AdminAction event
3. Emit event AFTER modifier execution
4. Add indexed tokenId field

BONUS:
Build mini ERC20-style Transfer event.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Events create blockchain logs
- Events help off-chain tracking
- Events are not contract storage
- Events disappear if transaction reverts
- indexed enables efficient searching
- Event ordering matters heavily
- Incorrect events may mislead systems
- Events are cheaper than storage
- Auditors verify event consistency
- Execution tracking is critical in smart contracts

=========================================================
*/
/*
Title: Missing withdraw events, Admin action tracking, Post-Modifier Event Emission and Indexed token identifiers

Severity: Low

Reason: The contract demonstrates event-based execution tracking but does not log withdrawals, administrative actions, or demonstrate events
        emitted after modifier evecution. it also lacks indexed token identifiers for efficient log filtering.

Location: Contract: EventExecutionTracking
          Function: deposit()
          Function: validateNumber()

Vulnerability Description: The contract currently emits
1. DepositStarted
2. balanceUpdated
3. DepositCompleted
4. ExecutionFailed
However, it does not include
1. Withdrawal events
2. Adminstrative action events
3. Events emitted after modifier execution
4. Indexed tokenId fields for filtering

Impact: 
- Withdrawal activity cannot be tracked
- Administrative operations leave no audit trail
- Event execution order is not demonstrated
- Log filtering by token ID is unavailable

recommendation:
- WithdrawCompleted event
- AdminAction event
- Modifier that emits an event after function execution
- Indexed tockenId parameter
*/

// PATCHED CODE

contract EventExecutionTracking {

    /*
        STORAGE VARIABLES
    */
    mapping(address => uint256) public balances;

    uint256 public totalDeposits;

    address public owner;

    /*
    =====================================================
    EVENT DEFINITIONS
    =====================================================

    Events create blockchain logs.
    */

    event DepositStarted(
        address indexed user,
        uint256 amount,
        uint256 indexed tokenId
    );

    event BalanceUpdated(
        address indexed user,
        uint256 newBalance,
        uint256 indexed tokenId
    );

    event DepositCompleted(
        address indexed user,
        uint256 amount,
        uint256 totalDeposits,
        uint256 indexed tokenId
    );

    event ExecutionFailed(
        address indexed user,
        string reason
    );

    event AdminAction(
        address indexed admin,
        string action,
        uint256 indexed tockenId
    );

    event WithdrawCompleted(
        address indexed user,
        uint256 amount,
        uint256 remainingBalance,
        uint256 indexed tokenId
    );

    event ModifierExecuted(
        address indexed caller,
        string action
    );


    constructor()
    {
        owner = msg.sender;
    }
// MODIFIER
     modifier trackModifierExecution()
     {
        _; 

        emit ModifierExecuted(msg.sender, "Modifier Completed");
     }
    
    /*
    =====================================================
    DEPOSIT FUNCTION
    =====================================================
    */

    function deposit(
        uint256 _amount,
        uint256 _tokenId
    )
        external
        trackModifierExecution
    {

        /*
            STEP 1:
            Emit execution-start event.
        */
        emit DepositStarted(
            msg.sender,
             _amount,
             _tokenId
        );

        /*
            STEP 2:
            Validate input.
        */
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 100,
            "Amount too large"
        );

        /*
            STEP 3:
            Update storage.
        */
        balances[msg.sender] += _amount;

        /*
            STEP 4:
            Emit balance-update event.
        */
        emit BalanceUpdated(
            msg.sender,
            balances[msg.sender],
            _tokenId
        );

        /*
            STEP 5:
            Update global storage.
        */
        totalDeposits += _amount;

        /*
            STEP 6:
            Emit completion event.
        */
        emit DepositCompleted(
            msg.sender,
            _amount,
            totalDeposits,
            _tokenId
        );
    }

// WITHDRAW
    function withdraw(
    uint256 _amount,
    uint256 _tokenId)
    external 
    trackModifierExecution
    {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        totalDeposits -= _amount;

        emit WithdrawCompleted(
            msg.sender,
            _amount,
            balances[msg.sender],
            _tokenId
        );
    }

// ADMIN ACtION
    function resetBalance(
        address _user,
        uint256 _tokenId
    )
    external 
   // trackModifierExcution
    {
        require(
            msg.sender == owner, "Not owner"
        );

        balances[_user] = 0;

        emit AdminAction(msg.sender, "Balance reset", _tokenId);
    }


    /*
    =====================================================
    MANUAL FAILURE TRACKING
    =====================================================
    */

    function validateNumber(
        uint256 _number
    )
        external
    {

        /*
            Emit failure event before revert.
        */
        if (_number > 10) {

            emit ExecutionFailed(
                msg.sender,
                "Number too large"
            );

            revert("Validation failed");
        }
    }
}