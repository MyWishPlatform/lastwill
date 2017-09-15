pragma solidity ^0.4.16;

import "./MyWillConsts.sol";
import "./zeppelin/token/MintableToken.sol";

contract MyWillToken is usingMyWillConsts, MintableToken {
    bool public paused = false;

    function name() constant public returns (string _name) {
        return "MyWillToken";
    }

    function symbol() constant public returns (bytes32 _symbol) {
        return "WIL";
    }

    function decimals() constant public returns (uint8 _decimals) {
        return tokenDecimals8;
    }

    function setPaused(bool _paused) onlyOwner {
        paused = _paused;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(!paused);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        require(!paused);
        return super.transfer(_to, _value);
    }

}