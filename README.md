## EmissionDataProvider

This contract aims to give a simple way to track emissions of a given ERC20 token over a rewards program on top of Morpho Blue.

Rewards emissions are organized under the following structure:
- `Token`: The token address that is being rewarded in the program. You can have multiple tokens per program.
- `Market`: The market id that is being rewarded in the program. You can have multiple markets per program.
- `RewardsEmission`: The rewards struct containing the emission rate of rewards for each side of a Morpho market (supply, borrow, collateral). 


## Specs

- The owner should be able to update the rewards emission rate for a given token and market.
- The rate is valid at the block timestamp of the rate update. 
- To stop a rewards distribution, the owner should set the rate to 0.
- we are not checking if the market exists on blue. It is up to the owner to well configure the distributions.
