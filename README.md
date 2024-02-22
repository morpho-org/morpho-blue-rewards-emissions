## MarketRewardsProgramRegistry contract

### Overview

The legacy `EmissionDataProvider` contract provides a streamlined method for tracking emissions of a specific ERC20 token within a rewards program operated on Morpho Blue. It allows users to set emission rates for various rewards tokens in different markets. The `MarketRewardsProgramRegistry` contract is the updated version of the `EmissionDataProvider` contract to handle time-bounded rewards programs.

### Key Features

- **Rate Setting**: Any user can set a rate for a particular rewards token and market. Rates must be linked to a Universal Rewards Distributor (URD) for the distribution of rewards.
- **Trust Factor**: As rate setting is open to all, it's crucial for users to assess the credibility of the rate setter who is responsible for sending the rewards to the URD upon distribution.
- **Rewards Structure**: Rates are indicative of potential rewards. The actual distribution is handled by the `UniversalRewardsDistributor` contract during each update cycle, contingent on the trustworthiness of the rewards curator.
- **Program Structure**: The contract is designed to handle multiple rewards programs, each with its own start and end times. Once a program is registered, it is immutable and cannot be updated. Projects can set at most 30 programs per `id` with `id = keccak256(abi.encode(sender, urd, rewardToken, market))`.

### Rewards Program Structure

- **Sender**: Address defining the rate. Can be any user.
- **URD (Universal Rewards Distributor)**: Address for distributing rewards. Can be any URD.
- **RewardToken**: The ERC20 token address used for rewards.
- **MarketId**: Identifier of the market in which rewards are being offered.
- **MarketRewardsProgram**: A structure containing the programs rates for each aspect of a Morpho market (supply, borrow, collateral) as well as the period for which the rates are active.

### Rates

Rates are defined per year and only apply to a certain period.

### Specifications

- **Discontinuing a Rate**: Rates cease when the program's `end` is reached.
- **Validity and Trust**: Rates are effective immediately after a program registration. However, the contract is not trustless. It is a trust-minimized system, relying on the rewards distributor's commitment to distribute the rewards at each update.
- **Transparency and Scalability**: This contract enhances transparency and scalability in the rewards distribution process, supported by distribution and reader scripts provided by the Morpho Association.

### Deployment

- **EmissionDataProvider address**: Ethereum Mainnet: [0xf27fa85b6748c8a64d4b0d3d6083eb26f18bde8e](https://etherscan.io/address/0xf27fa85b6748c8a64d4b0d3d6083eb26f18bde8e)

### Additional Resources

- [Rewards Distribution Script](#) _(Link to be added)_

### License

MarketRewardsProgramRegistry and EmissionDataProvider are licensed under MIT, see [LICENSE](./LICENSE).

### Note

The information provided in this document is subject to change. Users should exercise due diligence and understand the inherent risks involved.
