## EmissionDataProvider

This contract aims to give a simple way to track emissions of a given ERC20 token over a rewards program on top of Morpho Blue.

Rewards emissions are organized under the following structure:
- Rewards Program ID: this is an unique identifier for a given rewards program managed by a DAO for example. 
- Token: The token address that is being rewarded in the program. You can have multiple tokens per program.
- market: The market id that is being rewarded in the program. You can have multiple markets per program.
- RewardsEmission: The rewards struct containing the emission rate of rewards, the start date and the end date. 


## Specs

- The owner should be able to update the rewards emission rate for a given program, token and market.
- The start date can be only in the future. 
- The end date is optional and can be updated later.


Problem: how to handle the case where the owner wants to update the start date of a rewards emission that has already started?
Problem: how to handle the case where we want to push the next rate in the future, without overriding the current one?

Solution: use a round based system. Each time the owner updates the rewards emission, a new round is created.
The owner can update the start date of future round, the end date of the current one, and push new rounds in the future.