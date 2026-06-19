// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../src/NftLaunchpad.sol";
import "../src/interfaces/INftLaunchpad.sol";

contract DeployNftLaunchpad is Script {
    function run() external {
        // Load variables from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vrfCoordinator = vm.envAddress("VRF_COORDINATOR");
        uint256 subscriptionId = vm.envUint("VRF_SUB_ID");
        bytes32 keyHash = vm.envBytes32("VRF_KEY_HASH");
        address royaltyReceiver = vm.envAddress("ROYALTY_RECEIVER");
        
        // Setup initial configuration (this can be tweaked via setConfig later)
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

        // Broadcast transaction to network using private key
        vm.startBroadcast(deployerPrivateKey);

        NftLaunchpad launchpad = new NftLaunchpad(
            "NFT Launchpad",
            "NL",
            config,
            vrfCoordinator,
            subscriptionId,
            keyHash,
            royaltyReceiver,
            500 // 5% royalty fee
        );

        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log("NftLaunchpad successfully deployed!");
        console.log("Address: ", address(launchpad));
        console.log("==================================================");
    }
}
