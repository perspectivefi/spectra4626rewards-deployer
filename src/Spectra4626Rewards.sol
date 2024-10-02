// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IERC4626, IERC20Metadata, IERC20} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IRewardsProxy} from "./interfaces/IRewardsProxy.sol";
import {ISpectra4626Rewards} from "./interfaces/ISpectra4626Rewards.sol";
import {IPausable} from "./interfaces/IPausable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/// @dev This contract extends OpenZeppelin's ERC4626 implementation with support for a rewards proxy.
///      This contract is intended to be instantiated with a non-ERC4626-compliant vault as underlying, in order to
///      make it compliant and additionnally facilitate the claiming of its external rewards if any.
contract Spectra4626Rewards is
    ERC4626Upgradeable,
    PausableUpgradeable,
    AccessManagedUpgradeable,
    ISpectra4626Rewards,
    IPausable
{
    /// @custom:storage-location erc7201:spectra.storage.Spectra4626Rewards
    struct Spectra4626RewardsStorage {
        address _rewardsProxy;
        uint8 _decimalsOffset;
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

    function initialize(
        address asset_,
        uint8 decimalsOffset_,
        address initialAuthority_
    ) external initializer {
        __ERC4626_init(IERC20(asset_));
        __ERC20_init(_vaultName(), _vaultSymbol());
        __Spectra4626Rewards_init_unchained(decimalsOffset_);
        __AccessManaged_init(initialAuthority_);
    }

    function __Spectra4626Rewards_init_unchained(uint8 decimalsOffset_) internal onlyInitializing {
        Spectra4626RewardsStorage storage $ = _getSpectra4626RewardsStorage();
        $._decimalsOffset = decimalsOffset_;
    }

    /// @dev See {IPausable-pause}.
    function pause() external override restricted {
        _pause();
    }

    /// @dev See {IPausable-unpause}.
    function unpause() external override restricted {
        _unpause();
    }

    /// @dev See {IPausable-paused}.
    function paused() public view override(IPausable, PausableUpgradeable) returns (bool) {
        return super.paused();
    }

    /// @dev See {ISpectra4626Rewards-rewardsProxy}.
    function rewardsProxy() public view returns (address) {
        Spectra4626RewardsStorage storage $ = _getSpectra4626RewardsStorage();
        return $._rewardsProxy;
    }

    /// @dev See {IERC4626-maxDeposit}.
    function maxDeposit(
        address
    ) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return paused() ? 0 : super.maxDeposit(address(0));
    }

    /// @dev See {IERC4626-maxMint}.
    function maxMint(address) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return paused() ? 0 : super.maxMint(address(0));
    }

    /// @dev See {IERC4626-maxWithdraw}.
    function maxWithdraw(
        address owner
    ) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return paused() ? 0 : super.maxWithdraw(owner);
    }

    /// @dev See {IERC4626-maxRedeem}.
    function maxRedeem(
        address owner
    ) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return paused() ? 0 : super.maxRedeem(owner);
    }

    /// @dev See {IERC4626-previewDeposit}.
    function previewDeposit(
        uint256 assets
    ) public view override(IERC4626, ERC4626Upgradeable) whenNotPaused returns (uint256) {
        return super.previewDeposit(assets);
    }

    /// @dev See {IERC4626-previewMint}.
    function previewMint(
        uint256 shares
    ) public view override(IERC4626, ERC4626Upgradeable) whenNotPaused returns (uint256) {
        return super.previewMint(shares);
    }

    /// @dev See {IERC4626-previewWithdraw}.
    function previewWithdraw(
        uint256 assets
    ) public view override(IERC4626, ERC4626Upgradeable) whenNotPaused returns (uint256) {
        return super.previewWithdraw(assets);
    }

    /// @dev See {IERC4626-previewRedeem}.
    function previewRedeem(
        uint256 shares
    ) public view override(IERC4626, ERC4626Upgradeable) whenNotPaused returns (uint256) {
        return super.previewRedeem(shares);
    }

    /// @dev See {ISpectra4626Rewards-previewWrap}.
    function previewWrap(uint256 assets) public view returns (uint256) {
        return previewDeposit(assets);
    }

    /// @dev See {ISpectra4626Rewards-previewUnwrap}.
    function previewUnwrap(uint256 shares) public view returns (uint256) {
        return previewRedeem(shares);
    }

    /// @dev See {ISpectra4626Rewards-wrap}.
    function wrap(uint256 assets, address receiver) public returns (uint256) {
        return deposit(assets, receiver);
    }

    /// @dev See {ISpectra4626Rewards-wrap}.
    function wrap(uint256 assets, address receiver, uint256 minShares) public returns (uint256) {
        uint256 sharesToMint = wrap(assets, receiver);
        if (sharesToMint < minShares) {
            revert ERC5143SlippageProtectionFailed();
        }
        return sharesToMint;
    }

    /// @dev See {ISpectra4626Rewards-unwrap}.
    function unwrap(uint256 shares, address receiver, address owner) public returns (uint256) {
        return redeem(shares, receiver, owner);
    }

    /// @dev See {ISpectra4626Rewards-unwrap}.
    function unwrap(
        uint256 shares,
        address receiver,
        address owner,
        uint256 minAssets
    ) public returns (uint256) {
        uint256 assetsToTransfer = unwrap(shares, receiver, owner);
        if (assetsToTransfer < minAssets) {
            revert ERC5143SlippageProtectionFailed();
        }
        return assetsToTransfer;
    }

    /// @dev See {ISpectra4626Rewards-claimRewards}.
    function claimRewards(bytes memory data) external restricted {
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
    function setRewardsProxy(address newRewardsProxy) public restricted {
        _setRewardsProxy(newRewardsProxy);
    }

    /// @dev Updates the rewards proxy. Internal function with no access restriction.
    function _setRewardsProxy(address newRewardsProxy) internal {
        Spectra4626RewardsStorage storage $ = _getSpectra4626RewardsStorage();
        address oldRewardsProxy = $._rewardsProxy;
        $._rewardsProxy = newRewardsProxy;
        emit RewardsProxyUpdated(oldRewardsProxy, newRewardsProxy);
    }

    /// @dev Internal getter to build contract name
    function _vaultName() internal view returns (string memory vaultName) {
        vaultName = string.concat("Spectra ERC4626 Rewards: ", IERC20Metadata(asset()).name());
    }

    /// @dev Internal getter to build contract symbol
    function _vaultSymbol() internal view returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("sr-", IERC20Metadata(asset()).symbol());
    }

    function _decimalsOffset() internal view override returns (uint8) {
        Spectra4626RewardsStorage storage $ = _getSpectra4626RewardsStorage();
        return $._decimalsOffset;
    }

    /// @dev See {ERC20Upgradeable-_update}.
    /// @dev Transfers, mints, and burns are disabled when paused.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override whenNotPaused {
        super._update(from, to, value);
    }
}
