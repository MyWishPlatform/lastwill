pragma solidity ^0.4.16;

import "SoftDestruct.sol";

/**
 * The base LastWill contract. Check method must be overrided.
 */
contract LastWill is SoftDestruct {
    /**
     * LastWill service admin account.
     */
    address private lastWillAccount;
    /**
     * Linked arrays: recipient addresses and corresponding % of funds.
     */
    address[] public recipients;
    uint8[] public percents;
    /**
     * Flag means that contract accident already occurs.
     */
    bool private triggered = false;

    // ------------ CONSTRUCT -------------
    function LastWill(address _targetUser, address[] _recipients, uint8[] _percents)
             SoftDestruct(_targetUser) {
        assert(_recipients.length == _percents.length);
        // check percents
        uint8 summaryPercent = 0;
        for (uint i = 0; i < _recipients.length; i ++) {
            assert(_recipients[i] != 0x0);
            summaryPercent += _percents[i];
        }
        assert(summaryPercent == 100);

        lastWillAccount = msg.sender;
        recipients = _recipients;
        percents = _percents;
    }

    // ------------ EVENTS ----------------
    // Occurs when contract was killed.
    event Killed(bool byUser);
    // Occurs when founds were sent.
    event FundsAdded(address indexed from, uint amount);
    // Occurs when accident happened.
    event Triggered(uint balance);
    // Occurs when accident leads to sending funds to recipient.
    event FundsSent(address recipient, uint amount, uint8 percent);

    /**
     * Public check method.
     */
    function check() onlyAdmin() onlyAlive() notTriggered() payable public {
        if (internalCheck()) {
            Triggered(this.balance);
            triggered = true;
            distributeFunds();
        }
    }

    // ------------ FALLBACK -------------
    // Must be less then 2300 gas
    function() payable onlyAlive() notTriggered() {
        FundsAdded(msg.sender, msg.value);
    }

    // ------------ INTERNAL -------------
    /**
     * Calculate amounts to transfer corresponding to the percents.
     */
    function calculateAmounts(uint balance, uint[] amounts) internal constant
                    returns (uint change) {
        change = balance;
        for (uint i = 0; i < percents.length; i ++) {
            var amount = balance * percents[i] / 100;
            amounts[i] = amount;
            change -= amount;
        }
    }

    /**
     * Distribute funds between recipients in corresponding by percents.
     */
    function distributeFunds() internal {
        uint[] memory amounts = new uint[](recipients.length);
        uint change = calculateAmounts(this.balance, amounts);

        for (uint i = 0; i < amounts.length; i ++) {
            var amount = amounts[i];
            var recipient = recipients[i];
            var percent = percents[i];

            if (amount == 0) {
                continue;
            }

            recipient.transfer(amount + change);
            FundsSent(recipient, amount, percent);
        }
    }

    /**
     * Do inner check.
     *
     * @return bool true of accident triggered, flase otherwise.
     */
    function internalCheck() internal returns (bool) {}

    /**
     * Extends super method to add event producing.
     */
    function kill() public {
        super.kill();
        Killed(true);
    }

    modifier onlyAdmin() {
        require(lastWillAccount == msg.sender);
        _;
    }

    modifier onlyTargetOrAdmin() {
        require(isTarget() || lastWillAccount == msg.sender);
        _;
    }

    modifier notTriggered() {
        require(!triggered);
        _;
    }
}
