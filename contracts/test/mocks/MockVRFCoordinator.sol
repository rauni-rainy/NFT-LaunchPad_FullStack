// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

/**
 * @dev Local mock for Chainlink VRF Coordinator.
 * Inherits the official Chainlink VRFCoordinatorV2Mock which already provides
 * the exact implementation to test `requestRandomWords` and simulate callbacks
 * via `fulfillRandomWords(uint256 _requestId, address _consumer)`.
 */
contract MockVRFCoordinator is VRFCoordinatorV2Mock {
    // baseFee: The premium charged per request
    // gasPriceLink: The gas price used to calculate total LINK cost
    constructor(uint96 _baseFee, uint96 _gasPriceLink) VRFCoordinatorV2Mock(_baseFee, _gasPriceLink) {}
}
