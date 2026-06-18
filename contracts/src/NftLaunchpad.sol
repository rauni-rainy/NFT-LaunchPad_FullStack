// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "erc721a/ERC721A.sol";
import "@openzeppelin/access/Ownable.sol";
import "@chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "./interfaces/INftLaunchpad.sol";
import "./libraries/MerkleHelper.sol";
import "./svg/SvgGenerator.sol";

contract NftLaunchpad is ERC721A, Ownable, VRFConsumerBaseV2, INftLaunchpad {
    constructor() ERC721A("LaunchpadNFT", "LPNFT") Ownable(msg.sender) VRFConsumerBaseV2(address(0)) {}
    
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // TODO: Implement VRF logic
    }
}
