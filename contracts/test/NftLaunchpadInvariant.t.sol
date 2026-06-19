// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/NftLaunchpad.sol";
import "./mocks/MockVRFCoordinator.sol";
import "../src/interfaces/INftLaunchpad.sol";

contract Handler is Test {
    NftLaunchpad public launchpad;
    
    bytes32 public originalHash;
    bool public provenanceWasSet;
    
    constructor(NftLaunchpad _launchpad) {
        launchpad = _launchpad;
        originalHash = keccak256("provenance");
    }

    function setPhase(uint8 phaseId) public {
        phaseId = uint8(bound(phaseId, 0, 4));
        vm.prank(launchpad.owner());
        launchpad.setPhase(INftLaunchpad.MintPhase(phaseId));
    }
    
    function mintPublic(uint256 qty, address user) public {
        vm.assume(user != address(0) && user != address(launchpad) && user != address(this));
        qty = bound(qty, 1, 5);
        
        if (launchpad.currentPhase() != INftLaunchpad.MintPhase.PUBLIC) return;
        if (launchpad.totalSupply() + qty > 100) return;
        if (launchpad.publicMinted(user) + qty > 5) return;
        
        vm.deal(user, 1 ether);
        vm.prank(user);
        launchpad.mintPublic{value: 0.1 ether * qty}(qty);
    }
    
    function setProvenance() public {
        if (provenanceWasSet) return;
        if (launchpad.currentPhase() != INftLaunchpad.MintPhase.CLOSED) return;
        
        vm.prank(launchpad.owner());
        launchpad.setProvenanceHash(originalHash);
        provenanceWasSet = true;
    }
    
    function withdraw() public {
        vm.prank(launchpad.owner());
        launchpad.withdraw();
    }
    
    function claimReferralRewards(address user) public {
        if (launchpad.referralRewards(user) == 0) return;
        vm.prank(user);
        launchpad.claimReferralRewards();
    }
}

contract NftLaunchpadInvariantTest is Test {
    NftLaunchpad public launchpad;
    MockVRFCoordinator public vrfCoordinator;
    Handler public handler;

    address public owner = address(0x1);
    address public royaltyReceiver = address(0x2);

    function setUp() public {
        vrfCoordinator = new MockVRFCoordinator(0.1 ether, 1e9, 4e15);

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
            "NFT Launchpad Inv", "NLI",
            config, address(vrfCoordinator), 1, bytes32(0), royaltyReceiver, 500
        );

        handler = new Handler(launchpad);

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = handler.setPhase.selector;
        selectors[1] = handler.mintPublic.selector;
        selectors[2] = handler.setProvenance.selector;
        selectors[3] = handler.withdraw.selector;
        selectors[4] = handler.claimReferralRewards.selector;

        targetSelector(FuzzSelector({
            addr: address(handler),
            selectors: selectors
        }));
        targetContract(address(handler));
    }

    function invariant_totalSupplyNeverExceedsMax() public {
        assertTrue(launchpad.totalSupply() <= 100);
    }

    function invariant_contractBalanceCoversReferralRewards() public {
        assertTrue(address(launchpad).balance >= launchpad.totalReferralRewards());
    }

    function invariant_provenanceHashImmutableOnceSet() public {
        if (handler.provenanceWasSet()) {
            assertEq(launchpad.provenanceHash(), handler.originalHash());
        }
    }
}
