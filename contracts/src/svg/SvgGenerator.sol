// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/utils/Base64.sol";
import "@openzeppelin/utils/Strings.sol";

library SvgGenerator {
    using Strings for uint256;

    // We use `internal` instead of `external` to allow this library to be inlined into the consuming contract.
    // This prevents linking complexities during deployment and prevents deployment breaks in production.
    function generate(uint256 tokenId, address contractAddress) internal pure returns (string memory) {
        bytes32 seed = keccak256(abi.encodePacked(contractAddress, tokenId));
        
        uint256 hue1 = uint256(uint8(seed[0])) * 360 / 255;
        uint256 hue2 = (hue1 + 120) % 360;
        uint256 hue3 = (hue1 + 240) % 360;
        
        uint256 numPetals = 6 + (uint256(uint8(seed[4])) % 7);
        uint256 rotation = uint256(uint8(seed[5])) * 360 / 255;

        string memory petals = "";
        for (uint256 i = 0; i < numPetals; i++) {
            uint256 petalRot = (i * 360) / numPetals;
            petals = string.concat(
                petals,
                '<path transform="rotate(', petalRot.toString(), ')" d="M 0 0 C 20 -30, 40 -30, 20 -60 C 0 -90, -20 -30, 0 0 Z" fill="url(#grad)" opacity="0.8"/>'
            );
        }

        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300">',
            '<rect width="300" height="300" fill="black"/>',
            '<defs>',
            '<radialGradient id="grad">',
            '<stop offset="0%" stop-color="hsl(', hue1.toString(), ',80%,70%)"/>',
            '<stop offset="100%" stop-color="hsl(', hue2.toString(), ',60%,40%)"/>',
            '</radialGradient>',
            '</defs>',
            '<g transform="translate(150,150) rotate(', rotation.toString(), ')">',
            petals,
            '<circle cx="0" cy="0" r="15" fill="hsl(', hue3.toString(), ',70%,60%)" opacity="0.9"/>',
            '</g>',
            '</svg>'
        );

        return string.concat(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        );
    }
}
