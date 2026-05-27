// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Add nested if conditions
CONCEPT: Branching logic
=========================================================

OBJECTIVE

- Learn nested if-condition execution
- Understand branching logic in Solidity
- Learn multi-level decision flow
- Understand auditor-style path tracing

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Nested if statements create:
multiple execution branches.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Different inputs cause:
different execution paths.

Auditors must trace:
EVERY possible branch.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Many vulnerabilities hide inside:
rare execution branches.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Nested branching appears in:

- access control
- DeFi fee systems
- staking rewards
- liquidation logic
- governance rules
- NFT minting limits

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- unreachable branches
- incorrect conditions
- missing else logic
- privilege escalation
- inconsistent state updates

=========================================================
*/

contract NestedIfConditionsval {

    /*
        OWNER ADDRESS
    */
    address public owner;

    /*
        USER SCORES
    */
    mapping(address => uint256) public scores;

    /*
        USER LEVELS
    */
    mapping(address => string) public levels;

    /*
        CONSTRUCTOR
    */
    constructor() {

        owner = msg.sender;
    }

    /*
    =====================================================
    NESTED IF LOGIC
    =====================================================
    */

    function evaluateUser(
        uint256 _score,
        bool _premium
    )
        external
    {

        /*
            FIRST BRANCH

            Check minimum score.
        */
        if (_score >= 50) {

            /*
                SECOND BRANCH

                Check premium status.
            */
            if (_premium == true) {

                /*
                    THIRD BRANCH

                    Check elite score.
                */
                if (_score >= 90) {

                    levels[msg.sender] =
                        "Elite Premium";

                } else {

                    levels[msg.sender] =
                        "Premium";
                }

            } else {

                /*
                    NON-PREMIUM USER
                */
                levels[msg.sender] =
                    "Standard";
            }

            /*
                SAVE SCORE
            */
            scores[msg.sender] = _score;

        } else {

            /*
                LOW SCORE BRANCH
            */
            levels[msg.sender] =
                "Rejected";
        }
    }

    /*
    =====================================================
    OWNER BONUS FUNCTION
    =====================================================
    */

    function ownerBonus(
        address _user
    )
        external
    {

        /*
            FIRST CONDITION:
            owner check
        */
        if (msg.sender == owner) {

            /*
                SECOND CONDITION:
                user must exist
            */
            if (scores[_user] > 0) {

                /*
                    THIRD CONDITION:
                    high score required
                */
                if (scores[_user] >= 80) {

                    scores[_user] += 20;
                }
            }
        }
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
evaluateUser(95, true)

=========================================================

STEP 1:
if (_score >= 50)

CHECK:
95 >= 50

RESULT:
true

---------------------------------------------------------

STEP 2:
if (_premium == true)

CHECK:
true == true

RESULT:
true

---------------------------------------------------------

STEP 3:
if (_score >= 90)

CHECK:
95 >= 90

RESULT:
true

---------------------------------------------------------

EXECUTION PATH:

Elite Premium branch

---------------------------------------------------------

FINAL STORAGE:

levels[user] = "Elite Premium"

scores[user] = 95

=========================================================
ANOTHER TRACE
=========================================================

CALL:
evaluateUser(60, false)

---------------------------------------------------------

STEP 1:
60 >= 50

RESULT:
true

---------------------------------------------------------

STEP 2:
premium == true

RESULT:
false

---------------------------------------------------------

EXECUTION PATH:

Standard branch

---------------------------------------------------------

FINAL STATE:

levels[user] = "Standard"

=========================================================
LOW SCORE TRACE
=========================================================

CALL:
evaluateUser(20, true)

---------------------------------------------------------

STEP 1:
20 >= 50

RESULT:
false

---------------------------------------------------------

EXECUTION JUMPS TO:

else branch

---------------------------------------------------------

FINAL STATE:

levels[user] = "Rejected"

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
evaluateUser(95, true)

---------------------------------------------------------

STEP 3:
Call:
levels(your_address)

EXPECTED:
"Elite Premium"

---------------------------------------------------------

STEP 4:
Call:
evaluateUser(60, false)

EXPECTED:
"Standard"

---------------------------------------------------------

STEP 5:
Call:
evaluateUser(20, true)

EXPECTED:
"Rejected"

---------------------------------------------------------

STEP 6:
Call:
ownerBonus(your_address)

FROM:
owner account

---------------------------------------------------------

STEP 7:
Call:
scores(your_address)

OBSERVE:
Bonus added if conditions met

=========================================================
IMPORTANT BRANCHING UNDERSTANDING
=========================================================

Nested if statements create:
multiple execution paths.

---------------------------------------------------------

Every branch may:
- modify state differently
- skip logic
- create vulnerabilities

=========================================================
EXECUTION TREE
=========================================================

Example:

IF score >= 50
    |
    +-- premium?
          |
          +-- elite?
          |
          +-- standard

---------------------------------------------------------

Auditors mentally trace:
ALL branches.

=========================================================
WHY NESTED LOGIC IS DANGEROUS
=========================================================

Complex branching may cause:

- forgotten edge cases
- inconsistent updates
- bypass conditions
- privilege escalation

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. MISSING ELSE BRANCH
---------------------------------------------------------

State may remain unchanged unexpectedly.

---------------------------------------------------------
2. UNREACHABLE CODE
---------------------------------------------------------

Incorrect condition order
may block execution paths.

---------------------------------------------------------
3. INCONSISTENT STATE
---------------------------------------------------------

Different branches may:
update state differently.

---------------------------------------------------------
4. PRIVILEGE ESCALATION
---------------------------------------------------------

Incorrect nested checks
may bypass authorization.

=========================================================
GAS OBSERVATION
=========================================================

More branching:
More execution complexity.

---------------------------------------------------------

Deeper nesting:
Harder auditing.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Can attacker reach hidden branch?
- Are all paths validated?
- Does every path maintain invariants?
- Are branches mutually exclusive?
- Is state updated consistently?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer forgets else branch.

Attacker triggers unexpected path.

Result:
stale or corrupted state.

---------------------------------------------------------

ANOTHER RISK

Incorrect nested access-control logic
may allow unauthorized execution.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Every condition
2. Every branch
3. Every state update
4. Every revert path
5. Every skipped operation

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add blacklist logic
2. Add VIP user branch
3. Add paused-contract branch

Then manually trace:
ALL execution paths.

BONUS:
Convert nested ifs into:
require() + early returns.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Nested if creates multiple execution paths
- Branching changes execution flow
- Auditors must trace every branch
- Missing branches create vulnerabilities
- Complex logic increases audit difficulty
- State updates differ across branches
- Incorrect nesting may bypass checks
- Edge cases matter heavily
- Branch analysis is critical in auditing
- Execution tracing is essential for security reviews

=========================================================
*/

/*
Title: Missing administrative controls (Blacklist, VIP classification, and pause Mechanism)

Severity: Medium

Reason: The contract lacks blacklist functionality, VIP user handling, and an emergency pause mechanism. These controls are commonly required to prevent malicious 
        users from interacting with the protocol and to allow administrators to halt operations during emergencies.

Location: Contract: NestedIfConditions
          Function: evaluateUser()
          Function: ownerBonus()

Vulnerability Description: The current implementation only evaluates user based on:
                          1. Score
                          2.  Premium status

    The contract does not:
    1. Block blacklisted users
    2. Support VIP user classification
    3. Allow pausing contract operations

As a result, any user can continue interacting with the contract even if thay should be retricted and the owner has no emergency stop mechanism

Impact: As attacker or unwanted participant can continue using the contract after being identified as malicious

- Unauthorize participation
- Abuse of scoring logic
- Abuse of owner bonus mechanism
- No emergency shutdown capability
- No differentiation between VIP and regular users

Proof of Concept:
1. Deploy contract
2. User receives a low score
3. Owner decides to blacklist the user
4. No blacklist mechanism exists
5. User continues calling evaluateUser()
6. During a protocol emergency, owner wants to disable interactions.
7. No pause functionality exists
8. Contract remains operational

Root Cause: The contract lacks

mapping(address => bool) public blacklisted;

mapping(address => bool) public vipUsers;

bool public paused;

- No validation is performed before user evaluation

Recommendation: 
- Blacklist management 
- VIP user management
- Pause/unpause mechanism
- Early-return architecture
- Access control modifiers

*/

// Patched code

contract NestedIfConditions {

    /*
        OWNER ADDRESS
    */
    address public owner;

    /*
        USER SCORES
    */
    mapping(address => uint256) public scores;

    /*
        USER LEVELS
    */
    mapping(address => string) public levels;

    mapping(address => bool) public blacklisted;

    mapping(address => bool) public vipUsers;

    bool public paused;

    /*
        CONSTRUCTOR
    */
    constructor() {

        owner = msg.sender;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "not the owner"); _;
    }
    
    function setPaused(bool _status) external onlyOwner
    {
        paused = _status;
    }

    function blacklistUser(address _user) external onlyOwner
    {
        blacklisted[_user] = true;
    }

    function removeBlacklist(address _user) external onlyOwner
    {
        blacklisted[_user] = false;
    }

    function setVIP(address _user) external onlyOwner
    {
        vipUsers[_user] = true;
    }

    function removeVIP(address _user) external onlyOwner
    {
        vipUsers[_user] = false;
    }

// EVALUATE USER

  function evaluateUser(
        uint256 _score,
        bool _premium
    )
        external
    {
        require(
            !paused,
            "Contract paused"
        );

        require(
            !blacklisted[msg.sender],
            "Blacklisted"
        );

        if (_score < 50) {

            levels[msg.sender] =
                "Rejected";

            return;
        }

        scores[msg.sender] =
            _score;

        if (
            vipUsers[msg.sender]
            &&
            _score >= 95
        ) {

            levels[msg.sender] =
                "VIP Elite";

            return;
        }

        if (_premium) {

            if (_score >= 90) {

                levels[msg.sender] =
                    "Elite Premium";

                return;
            }

            levels[msg.sender] =
                "Premium";

            return;
        }

        levels[msg.sender] =
            "Standard";
    }

    

    /*
    =====================================================
    OWNER BONUS FUNCTION
    =====================================================
    */

    function ownerBonus(
        address _user
    )
        external
    {

        /*
            FIRST CONDITION:
            owner check
        */
        if (msg.sender == owner) {

            /*
                SECOND CONDITION:
                user must exist
            */
            if (scores[_user] > 0) {

                /*
                    THIRD CONDITION:
                    high score required
                */
                if (scores[_user] >= 80) {

                    scores[_user] += 20;
                }
            }
        }
    }
}