pragma solidity ^0.4.16;

import "./zeppelin/token/MintableToken.sol";

contract MyWillToken is MintableToken {
    function name() constant public returns (string _name) {
        return "MyWillToken";
    }

    function symbol() constant public returns (bytes32 _symbol) {
        return "WIL";
    }

    function decimals() constant public returns (uint8 _decimals) {
        return 18;
    }
}