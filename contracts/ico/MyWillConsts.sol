pragma solidity ^0.4.7;

contract usingMyWillConsts {
    uint constant tokenDecimals = 18;
    uint8 constant tokenDecimals8 = 18;
    uint constant tokenDecimalMultiplier = 10 ** tokenDecimals;
    uint constant etherDecimalMultiplier = 10 ** 18;
}