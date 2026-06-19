// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/NftLaunchpad.sol";
import "./mocks/MockVRFCoordinator.sol";
import "../src/interfaces/INftLaunchpad.sol";

contract NftLaunchpadFuzzTest is Test {
    NftLaunchpad public launchpad;
    MockVRFCoordinator public vrfCoordinator;

    address public owner = address(0x1);
    address public royaltyReceiver = address(0x2);
    address public referrer = address(0x3);

    address public og1 = address(0x11);
    address public og2 = address(0x12);
    address public og3 = address(0x13);
    address public ogDummy = address(0x14);

    address public wl1 = address(0x21);
    address public wl2 = address(0x22);
    address public wl3 = address(0x23);
    address public wl4 = address(0x24);
    address public wl5 = address(0x25);

    bytes32 public ogRoot;
    bytes32 public wlRoot;

    bytes32[] public proofOg1;
    bytes32[] public proofWl1;

    function setUp() public {
        vrfCoordinator = new MockVRFCoordinator(0.1 ether, 1e9, 4e15);
        _setupMerkleTrees();

        INftLaunchpad.LaunchConfig memory config = INftLaunchpad.LaunchConfig({
            maxSupply: 100,
            ogPrice: 0.01 ether,
            wlPrice: 0.02 ether,
            publicPrice: 0.05 ether,
            auctionStartPrice: 0.1 ether,
            auctionEndPrice: 0.01 ether,
            auctionDuration: 1 hours,
            ogMaxPerWallet: 2,
            wlMaxPerWallet: 3,
            publicMaxPerWallet: 5
        });

        vm.prank(owner);
        launchpad = new NftLaunchpad(
            "NFT Launchpad Fuzz", "NLF",
            config, address(vrfCoordinator), 1, bytes32(0), royaltyReceiver, 500
        );

        vm.startPrank(owner);
        launchpad.setOgMerkleRoot(ogRoot);
        launchpad.setWlMerkleRoot(wlRoot);
        vm.stopPrank();

        vm.deal(og1, 10 ether);
        vm.deal(wl1, 10 ether);
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }

    function _setupMerkleTrees() internal {
        bytes32 l0 = keccak256(abi.encodePacked(og1));
        bytes32 l1 = keccak256(abi.encodePacked(og2));
        bytes32 l2 = keccak256(abi.encodePacked(og3));
        bytes32 l3 = keccak256(abi.encodePacked(ogDummy));
        bytes32 n01 = _hashPair(l0, l1);
        bytes32 n23 = _hashPair(l2, l3);
        ogRoot = _hashPair(n01, n23);

        proofOg1 = new bytes32[](2);
        proofOg1[0] = l1;
        proofOg1[1] = n23;

        bytes32 w0 = keccak256(abi.encodePacked(wl1));
        bytes32 w1 = keccak256(abi.encodePacked(wl2));
        bytes32 w2 = keccak256(abi.encodePacked(wl3));
        bytes32 w3 = keccak256(abi.encodePacked(wl4));
        bytes32 w4 = keccak256(abi.encodePacked(wl5));
        bytes32 w5 = keccak256(abi.encodePacked(address(0x26)));
        bytes32 w6 = keccak256(abi.encodePacked(address(0x27)));
        bytes32 w7 = keccak256(abi.encodePacked(address(0x28)));
        bytes32 w01 = _hashPair(w0, w1);
        bytes32 w23 = _hashPair(w2, w3);
        bytes32 w45 = _hashPair(w4, w5);
        bytes32 w67 = _hashPair(w6, w7);
        bytes32 w0123 = _hashPair(w01, w23);
        bytes32 w4567 = _hashPair(w45, w67);
        wlRoot = _hashPair(w0123, w4567);

        proofWl1 = new bytes32[](3);
        proofWl1[0] = w1;
        proofWl1[1] = w23;
        proofWl1[2] = w4567;
    }

    function getDutchAuctionPrice(uint256 elapsed) public pure returns (uint256) {
        uint256 duration = 1 hours;
        uint256 startPrice = 0.1 ether;
        uint256 endPrice = 0.01 ether;

        if (elapsed >= duration) {
            return endPrice;
        } else {
            uint256 drop = ((startPrice - endPrice) * elapsed) / duration;
            return startPrice - drop;
        }
    }

    function testFuzz_DutchAuctionPriceNeverBelowFloor(uint256 elapsed) external {
        elapsed = bound(elapsed, 0, type(uint128).max);
        uint256 price = getDutchAuctionPrice(elapsed);

        assertTrue(price >= 0.01 ether, "Price below floor");
        assertTrue(price <= 0.1 ether, "Price above start");
    }

    function testFuzz_MintNeverExceedsMaxSupply(uint8 qty1, uint8 qty2) external {
        qty1 = uint8(bound(qty1, 1, 2)); // ogMaxPerWallet
        qty2 = uint8(bound(qty2, 1, 3)); // wlMaxPerWallet

        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.OG);

        vm.prank(og1);
        launchpad.mintOg{value: 0.01 ether * qty1}(qty1, proofOg1);

        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.ALLOWLIST);

        vm.prank(wl1);
        launchpad.mintWl{value: 0.02 ether * qty2}(qty2, proofWl1);

        assertTrue(launchpad.totalSupply() <= 100);
    }

    function testFuzz_ReferralRewardIsCorrectFraction(uint256 qty) external {
        qty = bound(qty, 1, 3);

        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.ALLOWLIST);

        vm.prank(wl1);
        launchpad.mintWithReferral{value: 0.02 ether * qty}(qty, proofWl1, referrer);

        uint256 expectedReward = (0.02 ether * qty * 5) / 100;
        assertEq(launchpad.referralRewards(referrer), expectedReward);
    }
}
