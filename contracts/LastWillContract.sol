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
        assert(_recipients.length != 0);
        assert(_recipients.length == _percents.length);
        uint8 summaryPercent = 0;
        for (uint i = 0; i < _recipients.length; i ++) {
            assert(_percents[i] > 0);
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
    event FundsSent(address indexed recipient, uint amount, uint percent);


    // ------------ EXTERNAL API ----------
    // Kill contract and return all founds to the target user.
    function kill() onlyTargetOrAdmin public {
        Killed(isTarget());
        selfdestruct(targetUser);
    }

    // Check and do accident if it required.
    function check() onlyAdmin public returns (bool) {
        if (doCheck()) {
            Accident(this.balance);
            doAccident();
            return true;
        }
        return false;
    }

    // for debug purposes only!
    function testDistribute(uint balance, address[] recipients, uint8[] percents)
    returns (address[] resultRecipients, uint[] amounts, uint change) {
        assert(recipients.length == percents.length);
        RecipientPercent[] memory rp = new RecipientPercent[](recipients.length);
        for (uint i = 0; i < recipients.length; i ++) {
            rp[i].recipient = recipients[i];
            rp[i].percent = percents[i];
        }
        RecipientAmount[] storage distributed = distribute(balance, rp);

        resultRecipients = new address[](distributed.length);
        amounts = new uint[](distributed.length);
        change = balance;

        for (uint m = 0; m < distributed.length; m ++) {
            resultRecipients[m] = distributed[m].recipient;
            amounts[m] = distributed[m].amount;
            change -= distributed[m].amount;
        }
    }

    // ------------ FALLBACK -------------
    // Must be less then 2300 gas
    function() payable {
//        FundsAdded(msg.sender, msg.value);
    }

    // ------------ INTERNAL -------------
    // Internal constant method for calculating payments.
    function distribute(uint balance, RecipientPercent[] percents) internal constant
        returns (RecipientAmount[] storage amounts) {
        for (uint i = 0; i < percents.length; i ++) {
            amounts.push(RecipientAmount(percents[i].recipient, balance * percents[i].percent / 100));
        }
    }

    // Do accident case.
    function doAccident() internal {
        RecipientAmount[] storage distributed = distribute(this.balance, recipientPercents);

        for (uint i = 0; i < distributed.length; i ++) {
            var amount = distributed[i].amount;
            distributed[i].recipient.transfer(amount);
            FundsSent(distributed[i].recipient, amount, recipientPercents[i].percent);
        }

        selfdestruct(targetUser);
    }

    // Do check (override it).
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
