// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

/**
 * @dev Local mock for Chainlink VRF Coordinator V2.5.
 */
contract MockVRFCoordinator is VRFCoordinatorV2_5Mock {
    constructor(uint96 _baseFee, uint96 _gasPrice, int256 _weiPerUnitLink) 
        VRFCoordinatorV2_5Mock(_baseFee, _gasPrice, _weiPerUnitLink) {}
}
