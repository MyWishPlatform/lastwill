pragma solidity ^0.4.0;

/**
 * Base logic for "soft" destruct contract. In other words - to return funds to the target user.
 */
contract SoftDestruct {
    /**
     * Target user, who will received funds in case of soft destruct.
     */
    address public targetUser;

    /**
     * Flag that the contract is already destroyed.
     */
    bool public destroyed = false;

    function SoftDestruct(address _targetUser) {
        targetUser = _targetUser;
    }

    /**
     * Kill the contract and return funds to the target user.
     */
    function kill() public onlyTarget() onlyAlive() {
        destroyed = true;
        targetUser.transfer(this.balance);
    }

    /**
     * Accept ether only of alive.
     */
    function () payable onlyAlive() {}

    function isTarget() internal constant returns (bool) {
        return targetUser == msg.sender;
    }

    // ------------ MODIFIERS -----------
    /**
     * Check that contract is not detroyed.
     */
    modifier onlyAlive() {
        require(!destroyed);
        _;
    }

    /**
     * Check that msg.sender is target user.
     */
    modifier onlyTarget() {
        require(isTarget());
        _;
    }
}
