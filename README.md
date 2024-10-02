## Spectra4626Rewards Deployer

This repository contains the implementation and deployment scripts for Spectra4626Rewards.

## Architecture Overview

#### Spectra4626Rewards

> *[Spectra4626Rewards](./src/utils/Spectra4626Rewards.sol)*

The `Spectra4626Rewards` is a contract that inherits from OpenZeppelin's `ERC4626Upgradeable` and additionnally provides logic to facilitate the claiming of external rewards via an associated `RewardsProxy` instance.
`Spectra4626Rewards` utilizes OpenZeppelin's Access Control framework, allowing centralized role management which can be delegated to DAO accounts.

##### When to use :
The `Spectra4626Rewards` is typically used when an IBT is not ERC4626-compliant and a wrapper for it is hardly realisable. `Spectra4626Rewards` can be deployed with the IBT set as the underlying token, the default wrapper/underlying ratio set to 1, and a customizable decimals offset which represents the desired difference in decimals between the underlying and the wrapper.

#### RewardsProxy

> *[IRewardsProxy](./src/utils/interfaces/IRewardsProxy.sol)*

Certain wrapped vaults may be eligible for rewards that require explicit claiming. A rewards proxy can be set up on top of any `Spectra4626Rewards` instance. It defines the `claimRewards()` function, which encapsulates the logic for claiming rewards. This function can be accessed through a `delegatecall` by the associated wrapper, allowing the DAO to manage and redistribute these rewards to users efficiently. The permission to attach a `RewardsProxy` instance to an existing `Spectra4626Rewards` is given to the Spectra DAO only.

#### Notes on upgradeability and permissions
`Spectra4626Rewards` is upgradeable and deployed behind OpenZeppelin's `TransparentUpgradeableProxy`. A `Spectra4626Rewards` implementation is already deployed on all supported chains.
During deployment of a new instance, 2 contracts are actually deployed :
- The `TransparentUpgradeableProxy` contract
- The `ProxyAdmin` admin contract, which can trigger proxy upgrades.

For maintainability and the option to attach a `RewardsProxy` instance to the `Spectra4626Rewards` at a later stage, the Spectra DAO is set as the `ProxyAdmin` Owner, and the Spectra `AccessManager` as the initial Authority during deployment. The addresses of Spectra DAO and `AccessManager` for the supported chains are stored in their respective files under `script/constants/`.

## Installation

1. Install yarn dependencies (prettier etc..)

```shell
yarn 
```

2. Install libraries and dependencies

```shell
git submodule update --init --recursive
```

For more information, please refer to the [Foundry documentation](https://book.getfoundry.sh/).

3. A `.env` file must be created in the project root, and should look like the following :
```
DEPLOYMENT_NETWORK="MAINNET"
UNDERLYING_TOKEN_ADDR=
DECIMALS_OFFSET=

MAINNET_RPC_URL=
ARBITRUM_RPC_URL=
OPTIMISM_RPC_URL=
BASE_RPC_URL=
```
Values for `DEPLOYMENT_NETWORK`, `UNDERLYING_TOKEN_ADDR` and `DECIMALS_OFFSET` must be provided. `DECIMALS_OFFSET` is generally set to 0, so that the underlying token and the wrapper have the same decimals.
Supported values for `DEPLOYMENT_NETWORK` are `MAINNET`, `ARBITRUM`, `OPTIMISM` and `BASE`.
Additionnaly, RPC_URL for chosen network of deployment must be set.

## Usage

### Simulation
In order to simulate deployment transactions, run the deployment script with the following command:
```
forge script script/DeploySpectra4626Rewards.s.sol --rpc-url <network-alias> -i 1 -vv
```
Note that `<network-alias>` must be set to one of the values declared in `foundry.toml`, namely `mainnet`, `arbitrum`, `optimism` or `base`, and must correspond to the deployment network.
The `-i 1` flag will trigger an interactive prompt to enter your private key.

### Deployment
In order to broadcast deployment transactions, run the deployment script the following additional flags :
```
forge script script/DeploySpectra4626Rewards.s.sol --rpc-url <network-alias> -i 1 --broadcast --slow -vv
```

#### Optional : contract verification
In order to have deployed contracts verified, add the following options to the command :
```
forge script script/DeploySpectra4626Rewards.s.sol --rpc-url <network-alias> -i 1 --broadcast --slow --verify --etherscan-api-key <your-api-key> -vv
```
Note that `<your-api-key>` must be a valid etherscan api key for your deployment network.

### Output json File
At the end of script execution, an output `.json` file containing the addresses of deployed proxy and proxyAdmin contracts, as well as other relevant addresses, is created under `script/constants/output`.
