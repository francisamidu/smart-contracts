// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/security/ReentracyGuard.sol";

contract EtherWallet {
    struct Account {
        address account;
        string username;
        uint256 balance;
        uint256 timestamp;
    }
    mapping(account=>Account) public accounts;
    address payable owner;

    modifier onlyOwner(address sender){
        require(sender == msg.sender,"Not your account!");
        _;
    }

    event AccountCreated(address account,string username);
    event AccountCredited(address account,uint amount);
    event BalanceWithdrawn(address account, uint amount)

    constructor() {
        owner = payable(msg.sender);
    }

    function register(
        address _account,
        string memory _username
    ) public {
            require(_account != address(0),"Attempting to provide a 0 address");
            require(bytes(_username) != 0, "Accountname is require");
            require(accounts[_account].account == 0, "Account already exists");

            accounts[_account]= Account({
                account: _account,
                username: _username,
                balance: 0,
                timestamp: block.timestamp
            });
            emit AccountCreated(_account, _username);
    }

    function deposit(address _account) public payable {
        uint amount = msg.value;
        require(amount > 1 wei,"Please provide at least 1 wei");
        accounts[_account].balance += amount; 
        emit AccountCredited(_account, amount);
    }

    function getBalance(address _account) external view returns (uint) {
        return accounts[_account].balance;
    }

    function withdrawBalance(address _account, uint amount) public onlyOwner(_account){
        Account storage account = accounts[_account];
        uint balance = account.balance;
        require(account.account != address(0),"Account not available");
        require(balance => amount, "Not enough funds to withdraw");
        (bool os, ) = payable(_account).call{value: balance}('');
        require(os); 
        emit BalanceWithdrawn(_account,balance);
    }
}
