##Digital banking smart contract App


### Introduction
Digital banking smart contract application is on chain platform where an investor can stake or deposit our token (RGT)
and get a reward or loan of 0.1 RGT token every 24 hours.
And investor can claim their reward at given time frame(say two days) in our Native token(NAT)

### implementation
The backend implementation is done using solidity programming language with help of truffle framework
basically there two public method implemented in the application which are 

* deposit/staking method which take amount of type unisigned integer as argument, this will be called
upon an investor depositing/staking into our app with RGT token. And please note that investor are only allowed to deposit a multiple of 10 RGT token at a time. eg 10, 20, 30 etc
* claimReward/withdrawal method: this transfer all the rewards that the investor has earned over a period of time to his wallet.
* The digital banking farm was first developed and deployed on Ganache(local blockchain) network  for testing purposes and later deploy to Avalanche test network for production

### Future enhancement - not implemented
* Self destruct pattern
    This is good especially for the purpose of this smart contract, since is like ICO that will run for given time frame, we can implement self destruct pattern to destroy the contract 
    at the set time, in that case it cannot no longer receive funds nor send funds.

* Unstaking - withdrawal pattern
    This will be nice if there an implementation that give user unstake whatever they have been staking, this will demostrate transparancey and incurcate trust into the user that they have right to withdrawal their staking however they may not be rewarded.
* Allow the owner of the smart contract to distribute the rewards
    this further enhance the security of the application if the owner is only allow to destribute the rewards accordingly as oppose the owner claiming their rewards, in that case we can implement require(only owner) in that function
* Displying time left for the reward to be claimed:
  in this case, we can write a function that will return the time left for the reward to be claimed in second: this can be done by converting the total number of block left to seconds. since we know for every one block added == 15secs


### Trade off
* For calculating given timeframe, i decided not to use block timestamp, it is known that this timestamp can be manipulated by the miners as the proof of work/stake
instead i used block number. for instance, i will get the block number at the time of deploying the smart contract. since it is known fact that ethereum block time is 15sec - meaning new block is added every 15sec
and i want the contract to run for 7days before asset owner can start claiming their rewards
therefore total seconds in 7days = 60 * 60 * 24 * 7 = 604,800sec
* 604,800/15 = 40,320 blocks
* i want the claiming of the reward to last for 2days
* 2day = 40,320/7 = 5,760 *2 = 11,520 blocks
* this means that the claiming of the rewards will be done btw 40,321 blocks to (40,321 + 11,520) block numbers
* ####Please note block timestamp can also be used for simplicity sake


### Dependencies
* Solidity programming
* Truffle framework
* Ganache : local blochain
* Avalanche test network
* Mocha/Chai
* React - frontend development

### Access the app 
* https://freightschain.com/
* please connect your metamask to avanlanche C-Chain



### Report
* The architectural diagram report can be found in this part: /report/DigitalBankingArchetecturalDesign.pdf
* the test script can be found on /test/DigitalBankingFarmTest.test.js