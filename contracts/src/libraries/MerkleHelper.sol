// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/utils/cryptography/MerkleProof.sol";

library MerkleHelper {
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}
