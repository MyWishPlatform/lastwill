pragma solidity ^0.4.16;

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
        uint16 rate;
        // additional rate or 0
        uint16 additionalRate;
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
        // TODO
        if (amountWei >= 5000 * tokenDecimalMultiplier) {
            baseRate += 50;
        }
        else if (amountWei >= 3000 * tokenDecimalMultiplier) {
            baseRate += 30;
        }
        else if (amountWei >= 1000 * tokenDecimalMultiplier) {
            baseRate += 10;
        }

        ExclusiveRate memory eRate = exclusiveRate[buyer];
        if (eRate.exists && eRate.workUntil >= now) {
            if (eRate.rate != 0) {
                baseRate = eRate.rate;
            }
            baseRate += eRate.additionalRate;
        }
        return baseRate;
    }

    function setExclusiveRate(address _investor, uint16 _rate, uint16 _additionalRate, uint32 _workUntil) onlyOwner {
        exclusiveRate[_investor] = ExclusiveRate(_workUntil, _rate, _additionalRate, true);
    }

    function removeExclusiveRate(address _investor) onlyOwner {
        delete exclusiveRate[_investor];
    }
}