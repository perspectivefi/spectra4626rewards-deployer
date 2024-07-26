// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// @dev Interface of Spectra4626Rewards.
interface ISpectra4626Rewards is IERC4626 {
    /// @dev Emitted when rewards proxy is updated.
    event RewardsProxyUpdated(address oldRewardsProxy, address newRewardsProxy);

    error NoRewardsProxy();
    error ClaimRewardsFailed();

    /// @dev Returns the associated rewards proxy.
    function rewardsProxy() external view returns (address);

    /// @dev Setter for the rewards proxy.
    /// @param newRewardsProxy The address of the new rewards proxy.
    function setRewardsProxy(address newRewardsProxy) external;

    /// @dev Claims rewards for the vault.
    /// @param data The optional data used for claiming rewards.
    function claimRewards(bytes calldata data) external;
}
