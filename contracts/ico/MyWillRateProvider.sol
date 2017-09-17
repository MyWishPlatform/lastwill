pragma solidity ^0.4.16;

import './zeppelin/math/SafeMath.sol';
import "./MyWillConsts.sol";
import "./zeppelin/ownership/Ownable.sol";

contract MyWillRateProviderI {
    /**
     * @dev Calculate actual rate using the specified parameters.
     * @param buyer     Investor (buyer) address.
     * @param totalSold Amount of sold tokens.
     * @param amountWei Amount of wei to purchase.
     * @return ETH to Token rate.
     */
    function getRate(address buyer, uint totalSold, uint amountWei) returns (uint rate);
}

contract MyWillRateProvider is usingMyWillConsts, MyWillRateProviderI, Ownable {
    using SafeMath for uint;
    uint constant step_30 = 20000000 * tokenDecimalMultiplier;
    uint constant step_20 = 40000000 * tokenDecimalMultiplier;
    uint constant step_10 = 60000000 * tokenDecimalMultiplier;
    uint16 constant rate_30 = 1950;
    uint16 constant rate_20 = 1800;
    uint16 constant rate_10 = 1650;

    struct ExclusiveRate {
        // be careful, accuracies this about 15 minutes
        uint32 workUntil;
        // exclusive rate or 0
        uint rate;
        // additional rate or 0
        uint16 bonusPercent1000;
        // flag to check, that record exists
        bool exists;
    }

    mapping(address => ExclusiveRate) exclusiveRate;

    function getRate(address buyer, uint totalSold, uint amountWei) returns (uint rate) {
        uint baseRate;
        // apply sale
        if (totalSold < step_30) {
            baseRate = rate_30;
        }
        else if (totalSold < step_20) {
            baseRate = rate_20;
        }
        else if (totalSold < step_10) {
            baseRate = rate_10;
        }
        else {
            baseRate = rate;
        }

        // apply bonus for amount
        if (amountWei >= 1000 * etherDecimalMultiplier) {
            baseRate += baseRate * 13 / 100;
        }
        else if (amountWei >= 500 * etherDecimalMultiplier) {
            baseRate += baseRate * 10 / 100;
        }
        else if (amountWei >= 100 * etherDecimalMultiplier) {
            baseRate += baseRate * 7 / 100;
        }
        else if (amountWei >= 50 * etherDecimalMultiplier) {
            baseRate += baseRate * 5 / 100;
        }
        else if (amountWei >= 30 * etherDecimalMultiplier) {
            baseRate += baseRate * 4 / 100;
        }
        else if (amountWei >= 10 * etherDecimalMultiplier) {
            baseRate += baseRate * 25 / 1000;
        }

        ExclusiveRate memory eRate = exclusiveRate[buyer];
        if (eRate.exists && eRate.workUntil >= now) {
            if (eRate.rate != 0) {
                baseRate = eRate.rate;
            }
            baseRate += baseRate * eRate.bonusPercent1000 / 1000;
        }
        return baseRate;
    }

    function setExclusiveRate(address _investor, uint _rate, uint16 _bonusPercent1000, uint32 _workUntil) onlyOwner {
        exclusiveRate[_investor] = ExclusiveRate(_workUntil, _rate, _bonusPercent1000, true);
    }

    function removeExclusiveRate(address _investor) onlyOwner {
        delete exclusiveRate[_investor];
    }
}