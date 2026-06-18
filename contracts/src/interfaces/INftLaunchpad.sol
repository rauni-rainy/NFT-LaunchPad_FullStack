// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface INftLaunchpad {
    // Enums
    enum MintPhase { CLOSED, OG, ALLOWLIST, PUBLIC, ENDED }

    // Structs
    struct LaunchConfig {
        uint256 maxSupply;
        uint256 ogPrice;
        uint256 wlPrice;
        uint256 publicPrice;
        uint256 auctionStartPrice;
        uint256 auctionEndPrice;
        uint256 auctionDuration;
        uint8 ogMaxPerWallet;
        uint8 wlMaxPerWallet;
        uint8 publicMaxPerWallet;
    }

    // Errors
    error MaxSupplyExceeded();
    error WrongPhase();
    error InvalidProof();
    error MaxPerWalletExceeded();
    error InsufficientPayment();
    error TransferFailed();
    error ProvenanceAlreadySet();
    error RevealAlreadyRequested();
    error NotEnoughLink();

    // Events
    event Minted(address indexed to, uint256 indexed tokenId, uint256 qty, MintPhase phase);
    event PhaseChanged(MintPhase oldPhase, MintPhase newPhase);
    event RevealRequested(uint256 requestId);
    event RevealFulfilled(uint256 randomOffset);
    event ProvenanceSet(bytes32 hash);
    event ReferralRewarded(address indexed referrer, address indexed minter, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event RootUpdated(string tier, bytes32 root);
}
