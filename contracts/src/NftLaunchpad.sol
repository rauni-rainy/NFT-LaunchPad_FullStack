// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "erc721a/ERC721A.sol";
import "@openzeppelin/token/common/ERC2981.sol";
import "@openzeppelin/access/Ownable2Step.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";
import "@chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/utils/Base64.sol";
import "@openzeppelin/utils/Strings.sol";
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
    uint256 public totalReferralRewards;
    bool public paused;

    // VRF Config
    VRFCoordinatorV2Interface private vrfCoordinator;
    uint64 private subscriptionId;
    bytes32 private keyHash;
    uint32 private callbackGasLimit;
    uint16 private requestConfirmations;
    bool public revealRequested;

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

    function requestReveal(bool force) external onlyOwner {
        if (revealRequested) revert RevealAlreadyRequested();
        require(force || totalSupply() == config.maxSupply, "Not fully minted");
        
        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
        vrfRequestId = requestId;
        revealRequested = true;
        emit RevealRequested(requestId);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setCallbackGasLimit(uint32 limit) external onlyOwner {
        callbackGasLimit = limit;
    }

    function setProvenanceHash(bytes32 hash) external onlyOwner {
        if (provenanceSet) revert ProvenanceAlreadySet();
        if (currentPhase != MintPhase.CLOSED) revert WrongPhase();
        provenanceHash = hash;
        provenanceSet = true;
        emit ProvenanceSet(hash);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 available = address(this).balance - totalReferralRewards;
        (bool ok, ) = payable(owner()).call{value: available}("");
        if (!ok) revert TransferFailed();
        emit Withdrawn(owner(), available);
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function setConfig(LaunchConfig calldata newConfig) external onlyOwner {
        if (currentPhase != MintPhase.CLOSED) revert WrongPhase();
        config = newConfig;
    }

    function setAirdrop(address[] calldata recipients, uint256[] calldata quantities) external onlyOwner {
        uint256 totalQty = 0;
        uint256 len = recipients.length;
        require(len == quantities.length, "Mismatched arrays");
        
        for (uint256 i = 0; i < len; i++) {
            totalQty += quantities[i];
        }
        if (totalSupply() + totalQty > config.maxSupply) revert MaxSupplyExceeded();
        
        for (uint256 i = 0; i < len; i++) {
            _safeMint(recipients[i], quantities[i]);
        }
    }

    function setRoyaltyInfo(address receiver, uint96 feeBps) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBps);
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

    // --- Minting ---

    function mintOg(uint256 qty, bytes32[] calldata proof) external payable nonReentrant {
        require(!paused, "Paused");
        if (currentPhase != MintPhase.OG) revert WrongPhase();
        if (!_verifyOg(msg.sender, proof)) revert InvalidProof();
        if (ogMinted[msg.sender] + qty > config.ogMaxPerWallet) revert MaxPerWalletExceeded();
        if (totalSupply() + qty > config.maxSupply) revert MaxSupplyExceeded();
        
        uint256 required = config.ogPrice * qty;
        if (msg.value < required) revert InsufficientPayment();

        ogMinted[msg.sender] += uint8(qty);
        _safeMint(msg.sender, qty);

        if (msg.value > required) {
            (bool ok, ) = payable(msg.sender).call{value: msg.value - required}("");
            if (!ok) revert TransferFailed();
        }

        emit Minted(msg.sender, _nextTokenId() - qty, qty, MintPhase.OG);
    }

    function mintWl(uint256 qty, bytes32[] calldata proof) external payable nonReentrant {
        require(!paused, "Paused");
        if (currentPhase != MintPhase.ALLOWLIST) revert WrongPhase();
        if (!_verifyWl(msg.sender, proof)) revert InvalidProof();
        if (wlMinted[msg.sender] + qty > config.wlMaxPerWallet) revert MaxPerWalletExceeded();
        if (totalSupply() + qty > config.maxSupply) revert MaxSupplyExceeded();
        
        uint256 required = config.wlPrice * qty;
        if (msg.value < required) revert InsufficientPayment();

        wlMinted[msg.sender] += uint8(qty);
        _safeMint(msg.sender, qty);

        if (msg.value > required) {
            (bool ok, ) = payable(msg.sender).call{value: msg.value - required}("");
            if (!ok) revert TransferFailed();
        }

        emit Minted(msg.sender, _nextTokenId() - qty, qty, MintPhase.ALLOWLIST);
    }

    function mintPublic(uint256 qty) external payable nonReentrant {
        require(!paused, "Paused");
        if (currentPhase != MintPhase.PUBLIC) revert WrongPhase();
        if (publicMinted[msg.sender] + qty > config.publicMaxPerWallet) revert MaxPerWalletExceeded();
        if (totalSupply() + qty > config.maxSupply) revert MaxSupplyExceeded();
        
        uint256 required = _currentPrice() * qty;
        if (msg.value < required) revert InsufficientPayment();

        publicMinted[msg.sender] += uint8(qty);
        _safeMint(msg.sender, qty);

        if (msg.value > required) {
            (bool ok, ) = payable(msg.sender).call{value: msg.value - required}("");
            if (!ok) revert TransferFailed();
        }

        emit Minted(msg.sender, _nextTokenId() - qty, qty, MintPhase.PUBLIC);
    }

    function mintWithReferral(uint256 qty, bytes32[] calldata proof, address referrer) external payable nonReentrant {
        require(!paused, "Paused");
        if (currentPhase != MintPhase.ALLOWLIST) revert WrongPhase();
        if (!_verifyWl(msg.sender, proof)) revert InvalidProof();
        if (wlMinted[msg.sender] + qty > config.wlMaxPerWallet) revert MaxPerWalletExceeded();
        if (totalSupply() + qty > config.maxSupply) revert MaxSupplyExceeded();
        
        uint256 required = config.wlPrice * qty;
        if (msg.value < required) revert InsufficientPayment();

        wlMinted[msg.sender] += uint8(qty);
        
        if (referrer != address(0) && referrer != msg.sender) {
            uint256 reward = (config.wlPrice * qty * 5) / 100;
            referralRewards[referrer] += reward;
            totalReferralRewards += reward;
            emit ReferralRewarded(referrer, msg.sender, reward);
        }

        _safeMint(msg.sender, qty);

        if (msg.value > required) {
            (bool ok, ) = payable(msg.sender).call{value: msg.value - required}("");
            if (!ok) revert TransferFailed();
        }

        emit Minted(msg.sender, _nextTokenId() - qty, qty, MintPhase.ALLOWLIST);
    }

    function claimReferralRewards() external nonReentrant {
        uint256 amount = referralRewards[msg.sender];
        require(amount > 0);
        referralRewards[msg.sender] = 0;
        totalReferralRewards -= amount;
        
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        if (!ok) revert TransferFailed();
        
        emit Withdrawn(msg.sender, amount);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!revealed) {
            string memory svgDataUri = SvgGenerator.generate(tokenId, address(this));
            
            string memory json = string.concat(
                '{"name":"Token #',
                Strings.toString(tokenId),
                ' [Unrevealed]","image":"',
                svgDataUri,
                '"}'
            );
            
            return string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            );
        }

        string memory _baseURIStr = baseURI;
        if (bytes(_baseURIStr).length == 0) {
            return "";
        }

        uint256 shiftedId = (tokenId - _startTokenId() + randomOffset) % config.maxSupply;
        return string.concat(_baseURIStr, Strings.toString(shiftedId), ".json");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        randomOffset = randomWords[0] % config.maxSupply;
        revealed = true;
        emit RevealFulfilled(randomOffset);
    }

    receive() external payable {}
}
