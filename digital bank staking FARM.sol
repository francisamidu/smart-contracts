// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;

//since we will be using our RGT and Native token in this our banking farm smart contract
//therefore, we need to import them here

import "./RgtToken.sol";
import "./NativeToken.sol";


// This is like tokenFarm that gives reward for each token staked(deposited) by investor
// the idea is, an investor will stake a multiple of 10 RGT token.
// And for each staken, 0.1 RGT token is reward every 24 hours.
contract DigitalBankingFarm {

    //the name of the contract. it is best practice to give smart contract a name
    string public name = "Dapp Digital Banking Farm";
    //create variable of type RGT token
    RgtToken public rgtToken;
    //create variable of type Native token
    NativeToken public nativeToken;
    //create the variable that will hold the mapping of address to account
    mapping(address => Account) public stakersAccount;
    //Since it is certain that the reward for each is staking is 0.1, therefore it will be okay if declared constant
    uint constant rewardAmount = 100000000000000000; // 0.1 RGT TOKEN  0.1 for 1d === then for 7d == 7X
    uint constant numberOfDays = 7;
    //Lets manage the state of staking/depositing in our contract, in that case we will know if the user has staked.
    mapping(address => bool) public hasStaked;
    //Lets keep track of all the addresses that ever staked in our contract.
    address[] public stakerAddresses;
    //lets add current staking status;
    mapping(address => bool) public isStaking;
    //keep track all track assets we ever created in this account
    Asset[] public assets;
    //keep track of owner that has collecting their rewards
    mapping(address => uint) public ownerRewards;
    //this will hold reward start time
    uint public rewardClaimingStartBlock;
    //this will hold reward end time
    uint public rewardClaimingEndBlock;
    //keep track of the smart contract state
    State public state;
    //owner of the smart contract
    address public owner;


    //EVENT
    event StakingEvent(address owner, uint amount, string message);
    event ClaimRewardEvent(address owner, uint reward, string message);

    //create our constructor that run once whenever the smart contract is deployed to the network
    //the constructor takes  the argument of the address that deployed the RGT and Native token to the network
    constructor(RgtToken _rgtToken, NativeToken _nativeToken) public {
        rgtToken = _rgtToken;
        nativeToken = _nativeToken;
        //update the state
        state = State.RUNNING;
        //set the owner
        owner = msg.sender;
        //send the start of the reward time
        //we want our reward claiming to  run for  a week
        //for every 15sec there is one block
        //how many ethereum block will be generated in a week
        //how many seconds in a week = 60 * 60 * 24 * 7 = 604,800sec
        //604,800/15 = 40,320 blocks
        rewardClaimingStartBlock = block.number + 40320;
        //send end of the reward time
        //run the claiming for two days;
        //2day = 40,320/7 = 5,760 *2 = 11,520 blocks
        rewardClaimingEndBlock = rewardClaimingStartBlock + 11520;
    }

    enum State {RUNNING, CLOSED}

    //The object that hold the account of each stakers
    struct Account {
        //holding total balance of the amount the account has staked or deposited so far
        uint balance;
        //hold the balance of the reward so far base on the amount he has staked
        uint reward;
        //great to have this, in order to check its existence
        bool exists;
    }


    //The asset object that will be created upon successfully deposited of multiple of 10 RGT token
    struct Asset {
        //an asset should have unique identity, in this case, a unique identifiers can assigned to this
        bytes32 identity;
        //of course an asset should have owner, in this case, we will use address of the owner
        address owner;
        //and asset will have a name, we will just called RGTAsset
        string name;
        //how much does this asset worth
        uint value;
    }


    //1. Stake token: this is part where investor we deposit RGT token to our digital banking contract
    //takes amount of RGT token as an argument and it has to be multiple of 10
    function depositToken(uint _amount) public isRunning{

        //before anything, lets check if the amount supplied is a multiple of 10 RGT token
        require(_amount % 10 == 0, "Amount supplied must be a multiple of 10 eg 10, 20, 30");

        // to stake RGT token to our contract, first we will transfer whatever the amount the sender is sending
        // to this contract
        // ofcourse in a real world scenerios, token sent to the app can be used for lending, fund raising, project building etc
        // as reward for each multiple of 10 token RGT stoken, an asset will be generated.
        // asset is something of value such as diamond, gold, but in this case asset === 0.1 RGT token
        rgtToken.transferFrom(msg.sender, address(this), _amount);

        //now the token has been successfully transfer to the contract, lets create an asset for this transactions
        Asset memory asset = Asset({
            //for instance we will hash the timestamp and block number to make identity of this asset unique
            identity: keccak256(abi.encodePacked(block.timestamp, block.number)),
            name: "RGT TOKEN ASSET",
            owner: msg.sender,  //the sender is the owner of this asset
            value: rewardAmount
        });


        //check if this sender has an account with us
        if(stakersAccount[msg.sender].exists) {
            //update the account of this sender
            Account memory account = stakersAccount[msg.sender];
            //Great! this sender has account with us, lets update its balance
            //update the existing balance
            account.balance += _amount;

        }else {
            //it means this is our first time account owner, lets add him up the list of our account owners
            //open account for him
            Account memory newAccount = Account({
            balance: _amount,
            reward: 0,
            exists: true
            });
            //finally add him up to the list of existing stakers
            stakersAccount[msg.sender] = newAccount;
            //so since this is new account --- first timer stakers, lets also add him to the array of stakers
            stakerAddresses.push(msg.sender);
        }
        //update the asset array;
        assets.push(asset);
        //update current staking status
        isStaking[msg.sender] = true;
        //update staking status
        hasStaked[msg.sender] = true;

        //if every things went well as it should, then emit staking event
        emit StakingEvent(msg.sender, _amount, "Operation was successful");

    }




    //3. Claim your reward: the method that will be responsible for investor to claim the reward that he received
    // so far base on the asset he/she has with us.
    function claimReward() public isRunning {

        //check if the claiming reward time has reached
        require(block.number > rewardClaimingStartBlock && block.number <= rewardClaimingEndBlock, "Sorry the banking farm is still running, and you will get your reward when is closed.");

        //check if this person has already claiming his rewards
        require(ownerRewards[msg.sender] <= 0, "It appears that you have already claiming your rewards");

        //fetch the account detail of the sender
        Account memory account  = stakersAccount[msg.sender];

        //get the total reward
        uint reward = getTotalReward();

        //for record purposes, update his account
        account.reward = reward;

        //check if the reward is greater than zero
        require(reward > 0, "Reward must be greater than zero before it can be claimed, pls stake RGT token and check back again");

        //transfer native token to this sender
        nativeToken.transfer(msg.sender, reward);

        //the account is not more staking
        isStaking[msg.sender] = false;

        //tracked this person, for he has collected his reward
        ownerRewards[msg.sender] = reward;

        //emit claimReward event
        emit ClaimRewardEvent(msg.sender, reward, "Operation was successful");

    }

    function closeContact() public onlyOwner {
        state = State.CLOSED;
        //just to be sure
        rewardClaimingEndBlock = 0;
    }

    //you must be the owner before you can be called
    modifier onlyOwner() {
        require(msg.sender == owner, "Oops! it appears you are not the owner of this contract");
        _;
    }

    modifier isRunning() {
        //check if the our yield banking is still running
        require(state == State.RUNNING, "It appears that our banking yield rewards has closed. please check next time");
        _;
    }


     function getTotalReward() private view returns(uint) {
        //lets get the total rewards to this person : msg.sender

         //hold the number of multiple of 10. becuase is possible that the owner has deposited 20 or 50 or 100 any point in time
         uint count = 0;

         //iterate all the assests
         for(uint i = 0; i < assets.length; i++) {
             //we are only interested in this sender
             if(assets[i].owner == msg.sender) {
                 //one asset === 10 RGT token
                 count += assets[i].value/10;
             }
         }
         //return totalAsset(base on multiple of 10 RGT token) * 0.1(the reward amount) * number of given days(7)
         return count * rewardAmount * numberOfDays;
     }







}