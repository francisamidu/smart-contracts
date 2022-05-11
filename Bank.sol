// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

contract Bank {

    event AccountCreated(address accountNumber, string username);
    event AccountUpdated(address accountNumber);
    event AccountDeleted(address accountNumber);
    event BalanceUpdated(address accountNumber, uint amount);

    error AccountAlreadyExists(address account);
    error AccountDoesntExist(address account);
    error InsufficientBalance(address accountNumber, uint256 amount);
    error InsufficientDeposit(address account, uint amount);

    modifier onlyExisting(address accountNumber){
      Account memory account = accounts[accountNumber];
      require(account.accountNumber > address(0),"Sorry this account doesn't exist");
      _;
    }

    modifier onlyAdmin(){
      require(msg.sender == _bankAdmin,"Only bank admin can perform this action");
      _;
    }

    modifier onlyAuthorized(address accountNumber){
      require(accountNumber == accounts[accountNumber].accountNumber || msg.sender == _bankAdmin ,"Action can only be performed by bank admin and account owner");
      _;
    }

    address _bankAdmin;

    enum AccountType{ Savings,Current }

    struct Account {
        address payable accountNumber;
        uint balance;
        string username;
        string _address;
        AccountType accountType;
    }

    mapping (address=>Account) internal accounts;
    uint minSavingsAmount = 200000000000000000;
    uint minCurrentAmount = 500000000000000000;
    uint noOfAccounts;
    uint256 _bankBalance;

    constructor(address _admin){
        _bankAdmin = _admin;
    }

    function createAccount(
        address payable accountNumber,
        string memory username,
        string memory _address,
        AccountType accountType
    ) public payable {
        if(accounts[accountNumber].accountNumber != accountNumber){
            uint amount = msg.value;
            Account memory account = Account({
              accountNumber: accountNumber,
              accountType: accountType,
              _address: _address,
              balance: amount,
              username: username
              });
            accounts[accountNumber] = account;
            _bankBalance += amount;
            noOfAccounts++;
            emit BalanceUpdated(accountNumber, amount);
        }else{
            revert AccountAlreadyExists(accountNumber);
        }
        emit AccountCreated(accountNumber,username);
    }

    function deposit(address payable accountNumber) public payable {
        uint amount = msg.value;
         if(accounts[accountNumber].accountNumber == address(0)){
            revert AccountDoesntExist(accountNumber);
        }
        accounts[accountNumber].balance = amount;
        _bankBalance += amount;
        emit BalanceUpdated(accountNumber, amount);
    }

    function getAccountBalance(address accountNumber) public view onlyExisting(accountNumber) returns(uint balance){
      Account memory account = accounts[accountNumber];
      return account.balance;
    }

    function owner() public view returns(address _owner){
      return _bankAdmin;
    }

    function bankBalance() public view onlyAdmin returns(uint balance){
      return _bankBalance;
    }

    function withdraw(address payable accountNumber, uint amount) public payable onlyExisting(accountNumber){
        Account memory account = accounts[accountNumber];
        require(account.accountNumber == msg.sender,"Only account owner can withdraw");

        if(account.balance > amount){
            revert InsufficientBalance(accountNumber, amount);
        }

        uint withdrawBalance = account.balance - amount;
        require(account.accountType == AccountType.Savings && withdrawBalance < minSavingsAmount,"Balance can't be less than 0.2 ether");
        require(account.accountType == AccountType.Current && withdrawBalance < minCurrentAmount,"Balance can't be less than 0.5 ether");
        account.accountNumber.transfer(amount);
        account.balance -= amount;
        _bankBalance -= amount;
        emit BalanceUpdated(accountNumber, amount);
    }

    function updateAccount(
      string memory username,
      string memory _address,
      AccountType accountType,
      address accountNumber
    ) public onlyExisting(accountNumber) {
      Account memory account = accounts[accountNumber];
      account.accountType = accountType;
      account._address = _address;
      account.username = username;
      emit AccountUpdated(accountNumber);
    }

    function deleteAccount(address accountNumber) public onlyAuthorized(accountNumber) {
      Account memory account = accounts[accountNumber];
      account.accountNumber.transfer(account.balance);
      delete accounts[accountNumber];
      _bankBalance -= account.balance;
      emit AccountDeleted(accountNumber);
    }

}
