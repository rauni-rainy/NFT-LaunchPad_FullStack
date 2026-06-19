// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/NftLaunchpad.sol";
import "./mocks/MockVRFCoordinator.sol";
import "../src/interfaces/INftLaunchpad.sol";

contract NftLaunchpadTest is Test {
    NftLaunchpad public launchpad;
    MockVRFCoordinator public vrfCoordinator;

    // Accounts
    address public owner = address(0x1);
    address public royaltyReceiver = address(0x2);
    address public referrer = address(0x3);

    // OG Accounts
    address public og1 = address(0x11);
    address public og2 = address(0x12);
    address public og3 = address(0x13);
    address public ogDummy = address(0x14);

    // WL Accounts
    address public wl1 = address(0x21);
    address public wl2 = address(0x22);
    address public wl3 = address(0x23);
    address public wl4 = address(0x24);
    address public wl5 = address(0x25);

    // Merkle Roots
    bytes32 public ogRoot;
    bytes32 public wlRoot;

    // Proofs
    bytes32[] public proofOg1;
    bytes32[] public proofWl1;

    // Interface Errors
    error MaxSupplyExceeded();
    error WrongPhase();
    error InvalidProof();
    error MaxPerWalletExceeded();
    error InsufficientPayment();
    error TransferFailed();
    error ProvenanceAlreadySet();
    error RevealAlreadyRequested();
    error NotEnoughLink();

    function setUp() public {
        vm.label(owner, "Owner");
        vm.label(royaltyReceiver, "RoyaltyReceiver");
        vm.label(referrer, "Referrer");
        vm.label(og1, "OG_1");
        vm.label(wl1, "WL_1");

        // 1. Deploy Mock VRF
        vrfCoordinator = new MockVRFCoordinator(0.1 ether, 1e9);

        // 2. Setup Merkle Trees
        _setupMerkleTrees();

        // 3. Deploy NftLaunchpad
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
            "NFT Launchpad",
            "NL",
            config,
            address(vrfCoordinator),
            1, // subId
            bytes32(0), // keyHash
            royaltyReceiver,
            500 // 5%
        );

        // Set roots
        vm.startPrank(owner);
        launchpad.setOgMerkleRoot(ogRoot);
        launchpad.setWlMerkleRoot(wlRoot);
        vm.stopPrank();

        // Fund accounts
        vm.deal(og1, 10 ether);
        vm.deal(wl1, 10 ether);
        vm.deal(address(0x99), 10 ether); // Public user
    }

    // --- Helpers ---

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }

    function _setupMerkleTrees() internal {
        // OG Tree (4 leaves)
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

        // WL Tree (8 leaves)
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

    // --- Tests ---

    function test_RevertWhen_MintInClosedPhase() public {
        vm.prank(og1);
        vm.expectRevert(WrongPhase.selector);
        launchpad.mintOg{value: 0.01 ether}(1, proofOg1);
    }

    function test_RevertWhen_InvalidOgProof() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.OG);

        bytes32[] memory wrongProof = new bytes32[](2);
        wrongProof[0] = bytes32(0);
        wrongProof[1] = bytes32(0);

        vm.prank(og1);
        vm.expectRevert(InvalidProof.selector);
        launchpad.mintOg{value: 0.01 ether}(1, wrongProof);
    }

    function test_OgMintSuccess() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.OG);

        vm.prank(og1);
        launchpad.mintOg{value: 0.02 ether}(2, proofOg1);

        assertEq(launchpad.balanceOf(og1), 2);
        assertEq(launchpad.ogMinted(og1), 2);
    }

    function test_RevertWhen_OgExceedsMaxPerWallet() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.OG);

        vm.prank(og1);
        vm.expectRevert(MaxPerWalletExceeded.selector);
        launchpad.mintOg{value: 0.03 ether}(3, proofOg1); // Max is 2
    }

    function test_WlMintSuccess() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.ALLOWLIST);

        vm.prank(wl1);
        launchpad.mintWl{value: 0.06 ether}(3, proofWl1); // 3 * 0.02

        assertEq(launchpad.balanceOf(wl1), 3);
        assertEq(launchpad.wlMinted(wl1), 3);
    }

    function test_ReferralRewardAccrual() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.ALLOWLIST);

        // Referrer should get 5% of 0.02 * 2 = 0.04 ether -> 0.002 ether
        vm.prank(wl1);
        launchpad.mintWithReferral{value: 0.04 ether}(2, proofWl1, referrer);

        assertEq(launchpad.referralRewards(referrer), 0.002 ether);
        assertEq(launchpad.totalReferralRewards(), 0.002 ether);
    }

    function test_ClaimReferralRewards() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.ALLOWLIST);

        vm.prank(wl1);
        launchpad.mintWithReferral{value: 0.04 ether}(2, proofWl1, referrer);

        uint256 initBalance = referrer.balance;

        vm.prank(referrer);
        launchpad.claimReferralRewards();

        assertEq(referrer.balance, initBalance + 0.002 ether);
        assertEq(launchpad.referralRewards(referrer), 0);
        assertEq(launchpad.totalReferralRewards(), 0);
    }

    function test_RevertWhen_ClaimWithNoRewards() public {
        vm.prank(referrer);
        vm.expectRevert(); // require(amount > 0)
        launchpad.claimReferralRewards();
    }

    function test_DutchAuctionPriceAtStart() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.PUBLIC);

        address publicUser = address(0x99);
        vm.prank(publicUser);
        launchpad.mintPublic{value: 0.1 ether}(1);

        assertEq(launchpad.balanceOf(publicUser), 1);
    }

    function test_DutchAuctionPriceAtHalf() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.PUBLIC);

        skip(30 minutes); // Half of 1 hour

        // Drop = (0.1 - 0.01) * 0.5 = 0.045
        // Expected price = 0.1 - 0.045 = 0.055 ether
        uint256 expectedPrice = 0.055 ether;

        address publicUser = address(0x99);
        vm.prank(publicUser);
        launchpad.mintPublic{value: expectedPrice}(1);

        assertEq(launchpad.balanceOf(publicUser), 1);
    }

    function test_DutchAuctionPriceAtEnd() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.PUBLIC);

        skip(1 hours); // Reached duration
        
        address publicUser = address(0x99);
        vm.prank(publicUser);
        launchpad.mintPublic{value: 0.01 ether}(1); // Final price

        assertEq(launchpad.balanceOf(publicUser), 1);
    }

    function test_ProvenanceHashCanOnlyBeSetOnce() public {
        bytes32 hash1 = keccak256("hash1");
        bytes32 hash2 = keccak256("hash2");

        vm.startPrank(owner);
        launchpad.setProvenanceHash(hash1);
        
        vm.expectRevert(ProvenanceAlreadySet.selector);
        launchpad.setProvenanceHash(hash2);
        vm.stopPrank();
    }

    function test_SvgTokenUriBeforeReveal() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.OG);

        vm.prank(og1);
        launchpad.mintOg{value: 0.01 ether}(1, proofOg1);

        string memory uri = launchpad.tokenURI(1);
        
        // Assert starts with data:
        bytes memory uriBytes = bytes(uri);
        assertTrue(uriBytes.length > 5, "URI too short");
        assertEq(uriBytes[0], "d");
        assertEq(uriBytes[1], "a");
        assertEq(uriBytes[2], "t");
        assertEq(uriBytes[3], "a");
        assertEq(uriBytes[4], ":");
    }

    function test_WithdrawCorrectAmount() public {
        vm.prank(owner);
        launchpad.setPhase(INftLaunchpad.MintPhase.ALLOWLIST);

        // 2 tokens = 0.04 ether. Referrer gets 0.002.
        vm.prank(wl1);
        launchpad.mintWithReferral{value: 0.04 ether}(2, proofWl1, referrer);

        // Contract balance is 0.04 ether.
        // Withdrawable is 0.04 - 0.002 = 0.038 ether
        uint256 initOwnerBal = owner.balance;

        vm.prank(owner);
        launchpad.withdraw();

        assertEq(owner.balance, initOwnerBal + 0.038 ether);
        assertEq(address(launchpad).balance, 0.002 ether); // Leaving referrer funds
    }

    function test_AirdropBatchMint() public {
        address[] memory recipients = new address[](5);
        uint256[] memory quantities = new uint256[](5);
        
        for(uint i = 0; i < 5; i++) {
            recipients[i] = address(uint160(0x50 + i));
            quantities[i] = 1;
        }

        vm.prank(owner);
        launchpad.setAirdrop(recipients, quantities);

        for(uint i = 0; i < 5; i++) {
            assertEq(launchpad.balanceOf(recipients[i]), 1);
        }
    }
}
