pragma solidity ^0.4.16;

import "./LastWillContract.sol";
import "lib/oraclizeAPI.sol";
import "lib/strings.sol";

contract LastWillContractOraclize is LastWillContract, usingOraclize {
    using strings for *;

    /**
     * Period of time (in seconds) without activity.
     */
    uint public noActivityPeriod;
    /**
     * Last active timestamp.
     */
    uint public lastActiveTs;
    /**
     * Last check block number.
     */
    uint public lastCheckBlockNo;

    /**
     * To inform LastWill system that it should repeat check immediately.
     */
    event NeedRepeatCheck(bool isAccident);
    /**
     * To inform LastWill system about latest oraclize price in wei.
     */
    event Price(uint);
    /**
     * Occurs when check finished.
     */
    event Checked(bool isAccident);

    /**
     * Oraclize query ids.
     */
    mapping(bytes32 => bool) private validIds;

    /**
     * Flag means no activity was detected for the specified period of time.
     */
    bool private noActivity = false;

    // ------------ CONSTRUCT -------------
    function LastWillContractOraclize(address _targetUser, address[] _recipients, uint8[] _percents, uint _noActivityPeriod)
             LastWillContract(_targetUser, _recipients, _percents) {
        noActivityPeriod = _noActivityPeriod;
        lastActiveTs = block.timestamp;
        lastCheckBlockNo = block.number;
    }

    // ------------ INTERNAL --------------
    function internalCheck() internal returns (bool) {
        if (noActivity) {
            msg.sender.transfer(msg.value);
            return true;
        }
        uint price = oraclize_getPrice("URL");
        if (price > msg.value) {
            revert();
        }
        string memory url = buildUrl(targetUser, lastCheckBlockNo, block.number);
        bytes32 queryId = oraclize_query("URL", url);
        validIds[queryId] = true;

        uint change = msg.value - price;
        if (change != 0) {
            msg.sender.transfer(change);
        }
        return false;
    }

    /**
     * The result look like '["1469624867", "1469624584",...'
     */
    function __callback(bytes32 queryId, string result) {
        if (msg.sender != oraclize_cbAddress()) revert();
        if (!validIds[queryId]) revert();
        delete validIds[queryId];
        if (noActivity) return;
        // empty string means not transaction timestamps (no output transaction)
        if (bytes(result).length == 0) {
            // accident if there is more time from last active then check interval
            noActivity = block.timestamp >= lastActiveTs ? (block.timestamp - lastActiveTs >= noActivityPeriod) : false;
        }
        else {
            // set not actual timestamp, but bock timestamp.
            // It might cause time gap, which in worst case equals to poll interval
            lastActiveTs = block.timestamp;
        }
        Checked(noActivity);
        if (noActivity) {
            NeedRepeatCheck(true);
        }
    }

    /**
     * This method is useful when we need to know last transaction ts
     */
    function parseJsonArrayAndGetFirstElementAsNumber(string json) internal returns (uint) {
        var jsonSlice = json.toSlice();
        strings.slice memory firstResult;
        jsonSlice.split(", ".toSlice(), firstResult);
        var ts = firstResult.beyond("[\"".toSlice()).toString();
        return parseInt(ts);
    }

    // json(https://api.etherscan.io/api?module=account&action=txlist&address=0xddbd2b932c763ba5b1b7ae3b362eac3e8d40121a&startblock=0&endblock=99999999&page=0&offset=0&sort=desc&apikey=FJ39P2DIU8IX8U9N2735SUKQWG3HPPGPX8).result[?(@.from=='<address>')].timeStamp
    function buildUrl(address target, uint startBlock, uint endBlock) internal returns (string) {
        strings.slice memory strAddress = toHex(target).toSlice();
        uint8 i = 0; // count of the strings below
        var parts = new strings.slice[](9);
        parts[i++] = "json(https://api.etherscan.io/api?module=account&action=txlist&address=0x".toSlice();
        parts[i++] = strAddress;
        //     // &page=0&offset=0 - means not pagination, but it might be a problem if there will be page limit
        parts[i++] = "&startblock=".toSlice();
        parts[i++] = uint2str(startBlock).toSlice();
        parts[i++] = "&endblock=".toSlice();
        parts[i++] = uint2str(endBlock).toSlice();
        parts[i++] = "&sort=desc&apikey=FJ39P2DIU8IX8U9N2735SUKQWG3HPPGPX8).result[?(@.from=='0x".toSlice();
        parts[i++] = strAddress;
        parts[i++] = "')].timeStamp".toSlice();
        return "".toSlice()
                 .join(parts);
    }

    function toHex(address adr) internal constant returns (string) {
        var ss = new bytes(40);
        var t = uint(adr);
        for (uint i = 0; i < 40; i ++) {
            uint c;
            assembly {
                c := and(t, 0xf)
                t := div(t, 0xf)
                c := add(add(c, 0x30), mul(0x27, gt(c, 9)))
            }
            ss[i] = byte(c);
        }
        return string(ss);
    }
}
