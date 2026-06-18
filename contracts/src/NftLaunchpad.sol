// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "erc721a/ERC721A.sol";
import "@openzeppelin/token/common/ERC2981.sol";
import "@openzeppelin/access/Ownable2Step.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";
import "@chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "./interfaces/INftLaunchpad.sol";
import "./svg/SvgGenerator.sol";

contract NftLaunchpad is ERC721A, ERC2981, Ownable2Step, ReentrancyGuard, VRFConsumerBaseV2, INftLaunchpad {

    /* =========================================================================
     *                              STORAGE LAYOUT
     * =========================================================================
     *
     * - LaunchConfig public config
     * - MintPhase public currentPhase
     * - bytes32 public ogMerkleRoot
     * - bytes32 public wlMerkleRoot
     * - bytes32 public provenanceHash
     * - bool public provenanceSet
     * - bool public revealed
     * - uint256 public randomOffset
     * - uint256 public vrfRequestId
     * - uint256 public auctionStartTime
     * - string public baseURI
     * - string public placeholderURI (unused after we add on-chain SVG)
     * - mapping(address => uint8) public ogMinted
     * - mapping(address => uint8) public wlMinted
     * - mapping(address => uint8) public publicMinted
     * - mapping(address => uint256) public referralRewards
     * - VRF config vars: vrfCoordinator, subscriptionId, keyHash, callbackGasLimit, requestConfirmations
     *
     * ========================================================================= */

    LaunchConfig public config;
    MintPhase public currentPhase;

    bytes32 public ogMerkleRoot;
    bytes32 public wlMerkleRoot;
    bytes32 public provenanceHash;
    
    bool public provenanceSet;
    bool public revealed;

    uint256 public randomOffset;
    uint256 public vrfRequestId;
    uint256 public auctionStartTime;

    string public baseURI;
    string public placeholderURI;

    mapping(address => uint8) public ogMinted;
    mapping(address => uint8) public wlMinted;
    mapping(address => uint8) public publicMinted;
    mapping(address => uint256) public referralRewards;

    // VRF Config
    VRFCoordinatorV2Interface public vrfCoordinator;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;

    constructor(
        string memory name,
        string memory symbol,
        LaunchConfig memory _config,
        address vrfCoordinatorAddress,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _royaltyReceiver,
        uint96 _royaltyFeeBps
    ) ERC721A(name, symbol) Ownable(msg.sender) VRFConsumerBaseV2(vrfCoordinatorAddress) {
        config = _config;
        currentPhase = MintPhase.CLOSED;
        
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        
        // Initial defaults (can be updated via setter later)
        callbackGasLimit = 100000;
        requestConfirmations = 3;

        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeBps);
    }
    
    function setPhase(MintPhase phase) external onlyOwner {
        MintPhase oldPhase = currentPhase;
        currentPhase = phase;
        
        if (phase == MintPhase.PUBLIC) {
            auctionStartTime = block.timestamp;
        }
        
        emit PhaseChanged(oldPhase, phase);
    }

    // --- Admin Merkle Setup ---

    function setOgMerkleRoot(bytes32 root) external onlyOwner {
        ogMerkleRoot = root;
        emit RootUpdated("OG", root);
    }

    function setWlMerkleRoot(bytes32 root) external onlyOwner {
        wlMerkleRoot = root;
        emit RootUpdated("ALLOWLIST", root);
    }

    // --- View & Verify ---

    function _verifyOg(address account, bytes32[] calldata proof) internal view returns (bool) {
        return MerkleProof.verify(proof, ogMerkleRoot, keccak256(abi.encodePacked(account)));
    }

    function _verifyWl(address account, bytes32[] calldata proof) internal view returns (bool) {
        return MerkleProof.verify(proof, wlMerkleRoot, keccak256(abi.encodePacked(account)));
    }

    function whitelistStatus(address account, bytes32[] calldata ogProof, bytes32[] calldata wlProof) external view returns (bool isOg, bool isWl) {
        isOg = _verifyOg(account, ogProof);
        isWl = _verifyWl(account, wlProof);
    }

    function _currentPrice() internal view returns (uint256) {
        if (currentPhase == MintPhase.OG) {
            return config.ogPrice;
        }
        
        if (currentPhase == MintPhase.ALLOWLIST) {
            return config.wlPrice;
        }
        
        if (currentPhase == MintPhase.PUBLIC) {
            uint256 elapsed = block.timestamp - auctionStartTime;
            if (elapsed >= config.auctionDuration) {
                return config.auctionEndPrice;
            } else {
                uint256 drop = ((config.auctionStartPrice - config.auctionEndPrice) * elapsed) / config.auctionDuration;
                return config.auctionStartPrice - drop;
            }
        }
        
        revert WrongPhase();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // TODO: Implement VRF logic
    }
}
