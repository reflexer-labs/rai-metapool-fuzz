pragma solidity ^0.6.7;


contract RedemptionPriceSnapMock {
    uint256 internal internalSnappedRedemptionPrice;

    constructor() public {
        // Set redemption price to $3 (ray)
        internalSnappedRedemptionPrice = 3000000000000000000000000000;
    }

    function setRedemptionPriceSnap(uint256 newPrice) external {
        internalSnappedRedemptionPrice = newPrice;
    }

    function snappedRedemptionPrice() public view returns (uint256) {
        return internalSnappedRedemptionPrice;
    }
}