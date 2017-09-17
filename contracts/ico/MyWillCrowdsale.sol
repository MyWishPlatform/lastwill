pragma solidity ^0.4.16;

import "./MyWillToken.sol";
import "./MyWillConsts.sol";
import "./MyWillRateProvider.sol";
import "./zeppelin/crowdsale/RefundableCrowdsale.sol";

contract MyWillCrowdsale is usingMyWillConsts, RefundableCrowdsale {
    uint constant teamTokens = 11000000 * tokenDecimalMultiplier;
    uint constant bountyTokens = 2000000 * tokenDecimalMultiplier;
    uint constant icoTokens = 3038800 * tokenDecimalMultiplier;
    uint constant minimalPurchase = 0.05 ether;
    address constant teamAddress = 0x001a041f7ABAb9871a22D2bEd0EC4dAb228866c3;
    address constant bountyAddress = 0x0025ea8bBBB72199cf70FE25F92d3B298C3B162A;
    address constant icoAccountAddress = 0x001a041f7ABAb9871a22D2bEd0EC4dAb228866c3;

    MyWillRateProviderI public rateProvider;

    function MyWillCrowdsale(
            uint32 _startTime,
            uint32 _endTime,
            uint _rate,
            address _wallet,
            uint _softCapWei,
            uint _hardCapTokens
    )
        RefundableCrowdsale(_startTime, _endTime, _rate, _hardCapTokens * tokenDecimalMultiplier, _wallet, _softCapWei) {

        token.mint(teamAddress,  teamTokens);
        token.mint(bountyAddress, bountyTokens);
        token.mint(icoAccountAddress, icoTokens);

        MyWillToken(token).addExcluded(teamAddress);
        MyWillToken(token).addExcluded(bountyAddress);
        MyWillToken(token).addExcluded(icoAccountAddress);

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

    function validPurchase(uint _amountWei, uint _actualRate, uint _totalSupply) internal constant returns (bool) {
        if (_amountWei < minimalPurchase) {
            return false;
        }
        return super.validPurchase(_amountWei, _actualRate, _totalSupply);
    }

    function finalization() internal {
        super.finalization();
        token.finishMinting();
        if (!goalReached()) {
            return;
        }
        MyWillToken(token).crowdsaleFinished();
        token.transferOwnership(owner);
    }
}