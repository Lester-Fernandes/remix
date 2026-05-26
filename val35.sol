// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Validate calldata input manually
CONCEPT: Input security
=========================================================

OBJECTIVE

- Learn how to validate external calldata inputs
- Understand why all external input is untrusted
- Learn manual validation techniques
- Understand security risks from unchecked input

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

ALL calldata input is attacker-controlled.

Never trust:
- numbers
- addresses
- arrays
- strings
- booleans

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Without validation:
attackers may:
- break logic
- bypass rules
- exhaust gas
- corrupt accounting

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Input validation is one of the MOST IMPORTANT
smart contract security practices.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Validation used in:

- token transfers
- staking systems
- governance voting
- DeFi routers
- NFT minting
- access control

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Missing require() checks
- Unbounded arrays
- Invalid addresses
- Overflow assumptions
- Authorization validation
- Business logic validation

=========================================================
*/

contract ValidateCalldataInputval {

    /*
        STATE VARIABLES

        Permanent blockchain state.
    */
    uint256 public storedAmount;

    address public lastReceiver;

    /*
    =====================================================
    VALIDATE UINT INPUT
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
    {

        /*
            VALIDATION:
            Amount must be greater than zero.
        */
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        /*
            VALIDATION:
            Prevent excessively large deposits.
        */
        require(
            _amount <= 1000 ether,
            "Amount too large"
        );

        /*
            Store validated value.
        */
        storedAmount = _amount;
    }

    /*
    =====================================================
    VALIDATE ADDRESS INPUT
    =====================================================
    */

    function setReceiver(
        address _receiver
    )
        external
    {

        /*
            VALIDATION:
            Prevent zero address.
        */
        require(
            _receiver != address(0),
            "Invalid address"
        );

        lastReceiver = _receiver;
    }

    /*
    =====================================================
    VALIDATE ARRAY INPUT
    =====================================================
    */

    function processArray(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {

        /*
            VALIDATION:
            Prevent huge arrays.
        */
        require(
            _numbers.length <= 100,
            "Array too large"
        );

        uint256 total = 0;

        for (uint256 i = 0; i < _numbers.length; i++) {

            /*
                VALIDATION:
                Reject zero values.
            */
            require(
                _numbers[i] > 0,
                "Invalid number"
            );

            total += _numbers[i];
        }

        return total;
    }

    /*
    =====================================================
    VALIDATE STRING INPUT
    =====================================================
    */

    function validateMessage(
        string calldata _message
    )
        external
        pure
        returns (bool)
    {

        /*
            Convert string to bytes
            to check length.
        */
        bytes calldata messageBytes =
            bytes(_message);

        /*
            VALIDATION:
            Reject empty strings.
        */
        require(
            messageBytes.length > 0,
            "Empty message"
        );

        /*
            VALIDATION:
            Prevent excessively large input.
        */
        require(
            messageBytes.length <= 50,
            "Message too long"
        );

        return true;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(100)

EVM ACTIONS:

1. Input arrives in calldata
2. require() validation checks run
3. Validation passes
4. Storage updated permanently

---------------------------------------------------------

FINAL STORAGE:

storedAmount = 100

=========================================================

CALL:
deposit(0)

EVM ACTIONS:

1. Input arrives
2. require() fails
3. Transaction reverts
4. State unchanged

---------------------------------------------------------

ERROR:

"Amount must be > 0"

=========================================================

CALL:
processArray([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Array length validated
3. Loop validates each element
4. Total calculated
5. Result returned

---------------------------------------------------------

RESULT:
6

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(100)

EXPECTED:
Success

---------------------------------------------------------

STEP 3:
Call:
deposit(0)

EXPECTED:
Revert

---------------------------------------------------------

STEP 4:
Call:
setReceiver(address(0))

EXPECTED:
Revert

---------------------------------------------------------

STEP 5:
Call:
processArray([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 6:
Call:
processArray([1,0,3])

EXPECTED:
Revert

---------------------------------------------------------

STEP 7:
Call:
validateMessage("Hello")

EXPECTED:
true

---------------------------------------------------------

STEP 8:
Call:
validateMessage("")

EXPECTED:
Revert

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Very large arrays

EXPECTED:
Rejected

---------------------------------------------------------

TEST:
Huge numbers

EXPECTED:
Rejected if above limit

---------------------------------------------------------

TEST:
Zero addresses

EXPECTED:
Rejected

---------------------------------------------------------

TEST:
Very long strings

EXPECTED:
Rejected

=========================================================
IMPORTANT SECURITY UNDERSTANDING
=========================================================

ALL EXTERNAL INPUT IS:

- attacker-controlled
- untrusted
- potentially malicious

---------------------------------------------------------

NEVER ASSUME:
inputs are safe.

=========================================================
COMMON VALIDATION CHECKS
=========================================================

---------------------------------------------------------
NUMBERS
---------------------------------------------------------

- > 0
- within limits
- no overflow assumptions

---------------------------------------------------------
ADDRESSES
---------------------------------------------------------

- not zero address
- authorized user
- expected contract

---------------------------------------------------------
ARRAYS
---------------------------------------------------------

- max length
- valid elements
- bounded loops

---------------------------------------------------------
STRINGS
---------------------------------------------------------

- non-empty
- max length

=========================================================
WHY VALIDATION MATTERS
=========================================================

WITHOUT VALIDATION:

Attackers may:
- trigger DOS
- bypass logic
- corrupt state
- break accounting

=========================================================
GAS OBSERVATION
=========================================================

MORE VALIDATION:
More gas

---------------------------------------------------------

BUT:
Security is more important
than minimal gas savings.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MISSING VALIDATION
---------------------------------------------------------

Most common vulnerability class.

---------------------------------------------------------
2. DOS VIA LARGE INPUTS
---------------------------------------------------------

Huge arrays may:
- exhaust gas
- break loops

---------------------------------------------------------
3. ZERO ADDRESS RISKS
---------------------------------------------------------

May:
- burn funds
- break ownership logic

---------------------------------------------------------
4. BUSINESS LOGIC VALIDATION
---------------------------------------------------------

Auditors inspect:
whether protocol rules
are enforced correctly.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker sends:
- massive arrays
- zero addresses
- invalid values
- unexpected inputs

Without validation:
protocol behavior breaks.

---------------------------------------------------------

REAL-WORLD IMPACT

Many exploits occurred because:
developers trusted external input.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Validate nested calldata arrays
2. Reject arrays larger than 50x50
3. Reject duplicate values

BONUS:
Add custom errors instead of require strings.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- All calldata is attacker-controlled
- External input must be validated
- require() enforces rules
- Arrays need size limits
- Addresses need zero-address checks
- Strings need length validation
- Validation prevents DOS and logic bugs
- Security more important than tiny gas savings
- Untrusted input is a major attack surface
- Auditors inspect validation carefully

=========================================================
*/

/*
Title: Missing validation for nested calldata arrays and duplicate values

Severity: Medium

Reason: The contract validates simple arrays but does not validate nested arrays. without limits and duplicate detection, attackers can submit
large or repetitive datasets that increase gas consumption and may lead to unexpected business logic behavior

Location: Contract: ValidateCalldataInput
          New Function: validateNestedArray()

Vulnerability Description: The contract currently validates
1. uint inputs
2. address inputs
3. single-dimensional arrays
4. strings

However it does not validate:
1. nested array dimensions
2. duplicate values inside nested arrays

Impact: An attacker could
- Increase gas coust through large nested arrays
- Cause transactions to run out of gas
- Submit duplicate records that may affect protocol logic

Proof of Concept: 
Input:

[[1,2,3],[4,5,6]]

Result:

Valid

Input:

[[1,2],[2,3]]

Result:

Duplicate value detected

Input:

Outer length > 50

Result:

Transaction reverts

Root Cause: The contract lacks
- nested array size validation
- duplicate detection logic
- custom errors for efficient reverts

Recommendation:
1. Limit outer array length to 50
2. Limit inner array length to 50
3. Reject duplicate values
4. Use custom errors instead of require strings to save gas


*/

// Patched code

contract ValidateCalldataInput {

    /*
        STATE VARIABLES

        Permanent blockchain state.
    */
    uint256 public storedAmount;

    address public lastReceiver;

    // CUSTOM ERRORS
    error AmountMustBeGreaterThanZero();
    error AmountTooLarge();
    error InvalidAddress();
    error OuterArrayTooLarge();
    error InnerArrayTooLarge();
    error DuplicateValue(uint256 value);

    /*
    =====================================================
    VALIDATE UINT INPUT
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
    {
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 1000 ether,
            "Amount too large"
        );

        storedAmount = _amount;
    }

    /*
    =====================================================
    VALIDATE ADDRESS INPUT
    =====================================================
    */

    function setReceiver(
        address _receiver
    )
        external
    {
        require(
            _receiver != address(0),
            "Invalid address"
        );

        lastReceiver = _receiver;
    }

    /*
    =====================================================
    VALIDATE NESTED ARRAY INPUT
    =====================================================
    */

    function validateNestedArray(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (bool)
    {
        if (_matrix.length > 50) {
            revert OuterArrayTooLarge();
        }

        uint256[] memory seen = new uint256[](2500);

        uint256 count = 0;

        for (uint256 i = 0; i < _matrix.length; i++) {

            // Validate inner array length
            if (_matrix[i].length > 50) {
                revert InnerArrayTooLarge();
            }

            for (uint256 j = 0; j < _matrix[i].length; j++) {

                uint256 value = _matrix[i][j];

                // Check for duplicates
                for (uint256 k = 0; k < count; k++) {

                    if (seen[k] == value) {
                        revert DuplicateValue(value);
                    }
                }

                seen[count] = value;
                count++;
            }
        }

        return true;
    }

    /*
    =====================================================
    VALIDATE STRING INPUT
    =====================================================
    */

    function validateMessage(
        string calldata _message
    )
        external
        pure
        returns (bool)
    {
        bytes calldata messageBytes =
            bytes(_message);

        require(
            messageBytes.length > 0,
            "Empty message"
        );

        require(
            messageBytes.length <= 50,
            "Message too long"
        );

        return true;
    }
}