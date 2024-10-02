// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {TransparentUpgradeableProxy, ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Spectra4626Rewards} from "../src/Spectra4626Rewards.sol";
import {ISpectra4626Rewards} from "../src/interfaces/ISpectra4626Rewards.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

// script to deploy Spectra4626Rewards Implementation, Proxy and RewardProxy
contract DeploySpectra4626Rewards is Script {
    string basePath;
    string path;

    string jsonConstants;
    string jsonOutput;

    string deploymentNetwork = vm.envString("DEPLOYMENT_NETWORK");
    address underlyingToken = vm.envAddress("UNDERLYING_TOKEN_ADDR");
    uint256 decimalsOffset = vm.envUint("DECIMALS_OFFSET");
    address spectraDAO;
    address accessManager;

    address srImplementation;
    address srProxy;
    address srProxyAdmin;

    constructor() {
        string memory root = vm.projectRoot();
        basePath = string.concat(root, "/script/constants/");

        // load constants
        path = string.concat(basePath, deploymentNetwork);
        path = string.concat(path, ".json");
        jsonConstants = vm.readFile(path);
    }

    function run() public {
        _deploySetupBefore();
        _deploy();
        _deploySetupAfter();
    }

    function _deploy() public {
        vm.startBroadcast();

        srProxy = address(
            new TransparentUpgradeableProxy(
                srImplementation,
                spectraDAO,
                abi.encodeWithSelector(
                    Spectra4626Rewards(address(0)).initialize.selector,
                    underlyingToken,
                    uint8(decimalsOffset),
                    accessManager
                )
            )
        );
        bytes32 adminSlot = vm.load(address(srProxy), ERC1967Utils.ADMIN_SLOT);
        srProxyAdmin = address(uint160(uint256(adminSlot)));

        vm.stopBroadcast();
    }

    function _deploySetupBefore() public {
        spectraDAO = abi.decode(vm.parseJson(jsonConstants, ".DAO"), (address));
        accessManager = abi.decode(vm.parseJson(jsonConstants, ".accessManager"), (address));
        srImplementation = abi.decode(vm.parseJson(jsonConstants, ".sr-implementation"), (address));
    }

    function _deploySetupAfter() public {
        console.log("DEPLOYED_PROXY=%s", srProxy);
        console.log("DEPLOYED_PROXY_ADMIN=%s", srProxyAdmin);
        console.log("PROXY_ADMIN_OWNER=%s", ProxyAdmin(srProxyAdmin).owner());
        console.log("IMPLEMENTATION=%s", srImplementation);
        console.log("UNDERLYING_TOKEN=%s", ISpectra4626Rewards(srProxy).asset());
        console.log(
            "DECIMALS_OFFSET=%s",
            ISpectra4626Rewards(srProxy).decimals() -
                IERC20Metadata(ISpectra4626Rewards(srProxy).asset()).decimals()
        );
        console.log("ACCESS_MANAGER=%s", IAccessManaged(srProxy).authority());

        // Format output data
        string memory obj2 = "deployed-contract";
        vm.serializeAddress(obj2, "implementation", srImplementation);
        vm.serializeAddress(obj2, "proxy", srProxy);
        vm.serializeAddress(obj2, "proxy-admin", srProxyAdmin);
        vm.serializeAddress(obj2, "proxy-admin-owner", spectraDAO);
        vm.serializeAddress(obj2, "accessManager", accessManager);
        vm.serializeAddress(obj2, "underlying-token", underlyingToken);
        string memory contractData = vm.serializeUint(obj2, "decimals-offset", decimalsOffset);

        // Write data to file
        path = string.concat(basePath, "output/Deployment-");
        path = string.concat(path, deploymentNetwork);
        path = string.concat(path, "-");
        path = string.concat(path, IERC20Metadata(srProxy).symbol());
        path = string.concat(path, ".json");
        string memory key = "key-deployment-output-file";
        vm.writeJson(vm.serializeString(key, IERC20Metadata(srProxy).symbol(), contractData), path);
    }
}
