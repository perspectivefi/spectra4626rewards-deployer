// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// @dev Interface of Spectra4626Rewards.
interface ISpectra4626Rewards is IERC4626 {
    /// @dev Emitted when rewards proxy is updated.
    event RewardsProxyUpdated(address oldRewardsProxy, address newRewardsProxy);

    error ERC5143SlippageProtectionFailed();
    error NoRewardsProxy();
    error ClaimRewardsFailed();

    /// @dev Returns the associated rewards proxy.
    function rewardsProxy() external view returns (address);

    /// @dev Allows to preview the amount of minted shares for a given amount of deposited assets.
    /// This function is a convenience alias for the ERC4626 `previewDeposit` function.
    /// @param assets The amount of assets to deposit.
    /// @return The amount of minted shares.
    function previewWrap(uint256 assets) external view returns (uint256);

    /// @dev Allows to preview the amount of withdrawn assets for a given amount of redeemed shares.
    /// This function is a convenience alias for the ERC4626 `previewRedeem` function.
    /// @param shares The amount of shares to redeem.
    /// @return The amount of withdrawn assets.
    function previewUnwrap(uint256 shares) external view returns (uint256);

    /// @dev Mints shares to receiver by depositing exact amount of assets.
    /// This function is a convenience alias for the ERC4626 `deposit` function.
    /// @param assets The amount of assets to deposit.
    /// @param receiver The address to receive the shares.
    /// @return The amount of minted shares.
    function wrap(uint256 assets, address receiver) external returns (uint256);

    /// @dev Mints shares to receiver by depositing exact amount of assets, with support for slippage protection.
    /// @param assets The amount of assets to deposit.
    /// @param receiver The address to receive the shares.
    /// @param minShares The minimum allowed shares from this deposit.
    /// @return The amount of minted shares.
    function wrap(uint256 assets, address receiver, uint256 minShares) external returns (uint256);

    /// @dev Burns exactly shares from owner and sends corresponding amount of assets to receiver.
    /// This function is a convenience alias for the ERC4626 `redeem` function.
    /// @param shares The amount of shares to redeem.
    /// @param receiver The address to receive the assets.
    /// @param owner The address of the owner of the shares.
    /// @return The amount of withdrawn assets.
    function unwrap(uint256 shares, address receiver, address owner) external returns (uint256);

    /// @dev Burns exactly shares from owner and sends corresponding amount of assets to receiver, with support for
    /// slippage protection.
    /// @param shares The amount of shares to redeem.
    /// @param receiver The address to receive the assets.
    /// @param owner The address of the owner of the shares.
    /// @param minAssets The minimum assets that should be returned.
    /// @return The amount of withdrawn assets.
    function unwrap(
        uint256 shares,
        address receiver,
        address owner,
        uint256 minAssets
    ) external returns (uint256);

    /// @dev Setter for the rewards proxy.
    /// @param newRewardsProxy The address of the new rewards proxy.
    function setRewardsProxy(address newRewardsProxy) external;

    /// @dev Claims rewards for the underlying asset.
    /// @param data The optional data used for claiming rewards.
    function claimRewards(bytes calldata data) external;
}
