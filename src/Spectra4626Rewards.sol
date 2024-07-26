// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IRewardsProxy} from "./interfaces/IRewardsProxy.sol";
import {ISpectra4626Rewards} from "./interfaces/ISpectra4626Rewards.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

/// @dev This contract extends OpenZeppelin's ERC4626 implementation with support for a rewards proxy.
///      This contract is intended to be instanciated with a non-ERC4626-compliant vault as underlying, in order to
///      make it compliant and additionnally facilitate the claiming of its external rewards if any.
contract Spectra4626Rewards is ERC4626Upgradeable, AccessManagedUpgradeable, ISpectra4626Rewards {
    /// @custom:storage-location erc7201:spectra.storage.Spectra4626Rewards
    struct Spectra4626RewardsStorage {
        address _rewardsProxy;
    }

    // keccak256(abi.encode(uint256(keccak256("spectra.storage.Spectra4626Rewards")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant Spectra4626RewardsStorageLocation =
        0x3d490fae310223ebdb2dcc0d0d74eea3b605f2d4a4efe7d5ace34369f0159d00;

    function _getSpectra4626RewardsStorage()
        private
        pure
        returns (Spectra4626RewardsStorage storage $)
    {
        assembly {
            $.slot := Spectra4626RewardsStorageLocation
        }
    }

    constructor() {
        _disableInitializers();
    }

    /// @dev calls parent initializers.
    function initialize(address asset_, address initialAuthority_) external initializer {
        __ERC4626_init(IERC20(asset_));
        __ERC20_init(_vaultName(), _vaultSymbol());
        __AccessManaged_init(initialAuthority_);
    }

    /// @dev See {ISpectra4626Rewards-rewardsProxy}.
    function rewardsProxy() public view returns (address) {
        Spectra4626RewardsStorage storage $ = _getSpectra4626RewardsStorage();
        return $._rewardsProxy;
    }

    /// @dev See {ISpectra4626Rewards-claimRewards}. */
    function claimRewards(bytes memory data) external virtual restricted {
        address _rewardsProxy = rewardsProxy();
        if (_rewardsProxy == address(0) || _rewardsProxy.code.length == 0) {
            revert NoRewardsProxy();
        }
        bytes memory data2 = abi.encodeCall(IRewardsProxy(address(0)).claimRewards, (data));
        (bool success, ) = _rewardsProxy.delegatecall(data2);
        if (!success) {
            revert ClaimRewardsFailed();
        }
    }

    /// @dev See {ISpectra4626Rewards-setRewardsProxy}.
    function setRewardsProxy(address newRewardsProxy) public virtual restricted {
        _setRewardsProxy(newRewardsProxy);
    }

    /// @dev Updates the rewards proxy. Internal function with no access restriction.
    function _setRewardsProxy(address newRewardsProxy) internal virtual {
        Spectra4626RewardsStorage storage $ = _getSpectra4626RewardsStorage();
        address oldRewardsProxy = $._rewardsProxy;
        $._rewardsProxy = newRewardsProxy;
        emit RewardsProxyUpdated(oldRewardsProxy, newRewardsProxy);
    }

    /// @dev Internal getter to build contract name
    function _vaultName() internal view virtual returns (string memory vaultName) {
        vaultName = string.concat("Spectra ERC4626 Rewards: ", IERC20Metadata(asset()).name());
    }

    /// @dev Internal getter to build contract symbol
    function _vaultSymbol() internal view virtual returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("sr-", IERC20Metadata(asset()).symbol());
    }
}
