pragma solidity ^0.4.16;

import "./MyWillToken.sol";
import "./zeppelin/crowdsale/RefundableCrowdsale.sol";

contract MyWillCrowdsale is RefundableCrowdsale {
    uint constant step_30 = 20000000 * 10 ** 18;
    uint constant step_20 = 40000000 * 10 ** 18;
    uint constant step_10 = 60000000 * 10 ** 18;
    uint16 constant rate_30 = 1950;
    uint16 constant rate_20 = 1800;
    uint16 constant rate_10 = 1650;

    uint constant teamTokens = 11000000 * 10 ** 18;
    uint constant bountyTokens = 2000000 * 10 ** 18;
    address constant teamAddress = 0x1;
    address constant bountyAddress = 0x2;

    function MyWillCrowdsale(
            uint32 _startTime,
            uint32 _endTime,
            uint _rate,
            address _wallet,
            uint _softCap,
            uint _hardCap
    )
        RefundableCrowdsale(_startTime, _endTime, _rate, _hardCap * 10 ** 18, _wallet, _softCap * 10 ** 18) {

        token.mint(teamAddress,  teamTokens);
        token.mint(bountyAddress, bountyTokens);

        // pre ICO
    }

    function createTokenContract() internal returns (MintableToken) {
        return new MyWillToken();
    }

    function getRate(uint value) internal constant returns (uint) {
        uint totalSupply = token.totalSupply();
        uint baseRate;
        // apply sale
        if (totalSupply < step_30) {
            baseRate = rate_30;
        }
        else if (totalSupply < step_20) {
            baseRate = rate_20;
        }
        else if (totalSupply < step_10) {
            baseRate = rate_10;
        }
        else {
            baseRate = rate;
        }

        // apply bonus for amount
        if (value >= 5000 * 10 ** 18) {
            baseRate += 50;
        }
        else if (value >= 3000 * 10 ** 18) {
            baseRate += 30;
        }
        else if (value >= 1000 * 10 ** 18) {
            baseRate += 10;
        }
        return baseRate;
    }

    function transferTokenOwnership(address newOwner) onlyOwner {
        token.transferOwnership(newOwner);
    }
}