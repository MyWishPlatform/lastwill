pragma solidity ^0.4.16;

import "./MyWillToken.sol";
import "./MyWillConsts.sol";
import "./MyWillRateProvider.sol";
import "./zeppelin/crowdsale/RefundableCrowdsale.sol";

contract MyWillCrowdsale is usingMyWillConsts, RefundableCrowdsale {
    uint constant teamTokens = 11000000 * tokenDecimalMultiplier;
    uint constant bountyTokens = 2000000 * tokenDecimalMultiplier;
    address constant teamAddress = 0x1;
    address constant bountyAddress = 0x2;

    MyWillRateProviderI rateProvider;

    function MyWillCrowdsale(
            uint32 _startTime,
            uint32 _endTime,
            uint _rate,
            address _wallet,
            uint _softCap,
            uint _hardCap
    )
        RefundableCrowdsale(_startTime, _endTime, _rate, _hardCap * tokenDecimalMultiplier, _wallet, _softCap * tokenDecimalMultiplier) {

        token.mint(teamAddress,  teamTokens);
        token.mint(bountyAddress, bountyTokens);

        MyWillRateProvider provider = new MyWillRateProvider();
        provider.transferOwnership(owner);
        rateProvider = provider;

        // pre ICO
    }

    function createTokenContract() internal returns (MintableToken) {
        return new MyWillToken();
    }

    function getRate(uint _value) internal constant returns (uint) {
        return rateProvider.getRate(msg.sender, soldTokens, _value);
    }

    function transferTokenOwnership(address _newOwner) onlyOwner {
        token.transferOwnership(_newOwner);
    }

    function setRateProvider(address _rateProviderAddress) onlyOwner {
        require(_rateProviderAddress != 0);
        rateProvider = MyWillRateProviderI(_rateProviderAddress);
    }
}