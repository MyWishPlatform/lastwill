pragma solidity ^0.4.16;

import "LastWill.sol";

contract LastWillWallet is LastWill {

    uint256 private lastOwnerActivity;
    uint256 private noActivityPeriod;

    event Withdraw(address _sender, uint256 amount, address _beneficiary);

    function LastWillWallet(address _targetUser, address[] _recipients, uint8[] _percents, uint32 _noActivityPeriod)
        LastWill(_targetUser, _recipients, _percents) {
            noActivityPeriod = _noActivityPeriod;
            lastOwnerActivity = block.timestamp;
    }

    function internalCheck() internal returns (bool) {
        return block.timestamp > lastOwnerActivity && (block.timestamp - lastOwnerActivity) >= noActivityPeriod;
    }

    function sendFunds(uint256 _amount, address _receiver) onlyTarget() onlyAlive() external returns (uint256) {
        require(this.balance >= _amount);
        require(_receiver != address(0));
        require(_receiver.send(_amount));

        Withdraw(msg.sender, _amount, _receiver);
        lastOwnerActivity = block.timestamp;
        return this.balance;
    }
}
