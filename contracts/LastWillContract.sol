pragma solidity ^0.4.0;

contract LastWillContract {
    struct RecipientPercent {
    address recipient;
    uint8 percent;
    }

    struct RecipientAmount {
    address recipient;
    uint amount;
    }

    // User which received all the ETH on kill or accident.
    address public targetUser;
    // Last will admin account.
    address public lastWillAccount;
    // How many amount of contract's balance will be payed to recipients when accident occurs.
    RecipientPercent[] public recipientPercents;

    // ------------ CONSTRUCT -------------
    function LastWillContract(address _targetUser, address[] _recipients, uint8[] _percents) {
        targetUser = _targetUser;
        lastWillAccount = msg.sender;
        assert(_recipients.length == _percents.length);
        uint8 summaryPercent = 0;
        for (uint i = 0; i < _recipients.length; i ++) {
            recipientPercents.push(RecipientPercent(_recipients[i], _percents[i]));
            summaryPercent += _percents[i];
        }
        assert(summaryPercent == 100);
    }

    // ------------ EVENTS ----------------
    // Occurs when contract was killed.
    event Killed(bool byUser);
    // Occurs when founds were sent.
    event FundsAdded(address indexed from, uint amount);
    // Occurs when accident happened.
    event Accident(uint balance);
    // Occurs when accident leads to sending funds to recipient.
    event FundsSent(address recipient, uint amount, uint8 percent);
    // Occurs when accident leads to sending funds to recipient.
    event FundsChange(uint change);

    // ------------ EXTERNAL API ----------
    // Kill contract and return all founds to the target user.
    function kill() onlyTargetOrAdmin public {
        Killed(isTarget());
        selfdestruct(targetUser);
    }

    function check() onlyAdmin public {
        if (doCheck()) {
            Accident(this.balance);
            accident();
        }
    }
    // for debug purposes only!
    function testDistribute(uint balance, address[] recipients, uint8[] percents) {
        assert(recipients.length == percents.length);
        RecipientPercent[] memory rp = new RecipientPercent[](recipients.length);
        for (uint i = 0; i < recipients.length; i ++) {
            rp[i].recipient = recipients[i];
            rp[i].percent = percents[i];
        }
        uint[] memory amounts = new uint[](recipients.length);
        uint change = distribute(balance, rp, amounts);

        for (uint m = 0; m < amounts.length; m ++) {
            FundsSent(recipients[m], amounts[m], percents[m]);
        }
        FundsChange(change);
    }

    // ------------ FALLBACK -------------
    // Must be less then 2300 gas
    function() payable {
        FundsAdded(msg.sender, msg.value);
    }

    // ------------ INTERNAL -------------
    // Internal constant method for calculating payments.
    function distribute(uint balance, RecipientPercent[] percents, uint[] amounts) internal constant
    returns (uint change) {
        assert(amounts.length == percents.length);
        change = balance;
        for (uint i = 0; i < percents.length; i ++) {
            var amount = balance * percents[i].percent / 100;
            amounts[i] = amount;
            change -= amount;
        }
    }

    // Do accident logic - transfer found and destruct contract.
    function accident() internal {
        uint[] memory amounts = new uint[](recipientPercents.length);
        uint change = distribute(this.balance, recipientPercents, amounts);

        for (uint i = 0; i < recipientPercents.length; i ++) {
            var amount = amounts[i];
            recipientPercents[i].recipient.transfer(amount);
            FundsSent(recipientPercents[i].recipient, amount, recipientPercents[i].percent);
        }

        FundsChange(change);
        selfdestruct(targetUser);
    }

    function doCheck() internal returns (bool);

    function isTarget() internal constant returns (bool) {
        return targetUser == msg.sender;
    }


    // ------------ MODIFIERS -----------
    modifier onlyTarget() {
        require(isTarget());
        _;
    }

    modifier onlyAdmin() {
        require(lastWillAccount == msg.sender);
        _;
    }

    modifier onlyTargetOrAdmin() {
        require(targetUser == msg.sender || lastWillAccount == msg.sender);
        _;
    }

}
