pragma solidity ^0.4.16;

import "./MyWillToken.sol";
import "./MyWillConsts.sol";
import "./MyWillRateProvider.sol";
import "./zeppelin/crowdsale/RefundableCrowdsale.sol";

contract MyWillCrowdsale is usingMyWillConsts, RefundableCrowdsale {
    uint constant teamTokens = 11000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant bountyTokens = 2000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant icoTokens = 3038800 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant minimalPurchase = 0.05 ether;
    address constant teamAddress = 0x001a041f7ABAb9871a22D2bEd0EC4dAb228866c3;
    address constant bountyAddress = 0x0025ea8bBBB72199cf70FE25F92d3B298C3B162A;
    address constant icoAccountAddress = 0x003b3f928c428525e9836C1d1b52016F4833c2f0;

    MyWillRateProviderI public rateProvider;

    function MyWillCrowdsale(
            uint32 _startTime,
            uint32 _endTime,
            address _wallet,
            uint _softCapWei,
            uint _hardCapTokens
    )
        RefundableCrowdsale(_startTime, _endTime, 1500, _hardCapTokens * TOKEN_DECIMAL_MULTIPLIER, _wallet, _softCapWei) {

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

    /**
     * @dev override token creation to integrate with MyWill token.
     */
    function createTokenContract() internal returns (MintableToken) {
        return new MyWillToken();
    }

    /**
     * @dev override getRate to integrate with rate provider.
     */
    function getRate(uint _value) internal constant returns (uint) {
        return rateProvider.getRate(msg.sender, soldTokens, _value);
    }

    /**
     * @dev override getRateScale to integrate with rate provider.
     */
    function getRateScale() internal constant returns (uint) {
        return rateProvider.getRateScale();
    }

    /**
     * @dev Admin can set new rate provider.
     * @param New rate provider.
     */
    function setRateProvider(address _rateProviderAddress) onlyOwner {
        require(_rateProviderAddress != 0);
        rateProvider = MyWillRateProviderI(_rateProviderAddress);
    }

    /**
     * @dev Admin can move end time.
     * @param _endTime New end time.
     */
    function setEndTime(uint32 _endTime) onlyAdmin {
        endTime = _endTime;
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