// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/NftLaunchpad.sol";
import "../src/interfaces/INftLaunchpad.sol";

contract NftLaunchpadHarness is NftLaunchpad {
    constructor(
        string memory name,
        string memory symbol,
        LaunchConfig memory _config,
        address vrfCoordinatorAddress,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _royaltyReceiver,
        uint96 _royaltyFeeBps
    ) NftLaunchpad(name, symbol, _config, vrfCoordinatorAddress, _subscriptionId, _keyHash, _royaltyReceiver, _royaltyFeeBps) {}

    function currentPrice() external view returns (uint256) {
        return _currentPrice();
    }
}

contract NftLaunchpadPriceTest is Test {
    NftLaunchpadHarness launchpad;

    function setUp() public {
        INftLaunchpad.LaunchConfig memory config = INftLaunchpad.LaunchConfig({
            maxSupply: 1000,
            ogPrice: 0.05 ether,
            wlPrice: 0.08 ether,
            publicPrice: 0.1 ether, 
            auctionStartPrice: 1 ether,
            auctionEndPrice: 0.1 ether,
            auctionDuration: 1 hours,
            ogMaxPerWallet: 2,
            wlMaxPerWallet: 3,
            publicMaxPerWallet: 5
        });

        launchpad = new NftLaunchpadHarness(
            "LaunchpadNFT",
            "LPNFT",
            config,
            address(1), 
            1,
            bytes32(0),
            address(2), 
            500 
        );
    }

    function test_DutchAuctionPricing() public {
        // Switch to PUBLIC phase
        launchpad.setPhase(INftLaunchpad.MintPhase.PUBLIC);

        // At t=0 (auction start)
        uint256 priceAtStart = launchpad.currentPrice();
        assertEq(priceAtStart, 1 ether, "Price at start should be 1 ether");

        // Warp to half duration (t = 30 mins)
        skip(30 minutes);
        uint256 priceAtHalf = launchpad.currentPrice();
        // Drop: ((1 - 0.1) * 30 mins) / 60 mins = 0.9 / 2 = 0.45 ether
        // Expected price: 1 - 0.45 = 0.55 ether
        assertEq(priceAtHalf, 0.55 ether, "Price at half duration should be 0.55 ether");

        // Warp to exact duration (t = 60 mins from start)
        skip(30 minutes);
        uint256 priceAtEnd = launchpad.currentPrice();
        assertEq(priceAtEnd, 0.1 ether, "Price at end should be 0.1 ether");

        // Warp past duration (t = 90 mins from start)
        skip(30 minutes);
        uint256 pricePastEnd = launchpad.currentPrice();
        assertEq(pricePastEnd, 0.1 ether, "Price past end should remain bounded at 0.1 ether");
    }
}
