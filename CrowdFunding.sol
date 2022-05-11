// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

contract CrowdFunding {
    mapping (address=>uint) public contributions;

    address public admin;
    uint public numberOfContributors;
    uint public minimumContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;

    struct Request {
        string description;
        address payable recipient;
        uint amount;
        bool completed;
        uint noOfVoters;
        mapping (address=>bool) voters;
    }

    event ContributionEvent(address _sender, uint amount);
    event RequestEvent(string _description, address _recipient, uint amount);
    event MakePaymentEvent(address recipient, uint amount);

    mapping(uint => Request) public requests;

    uint public numRequests;

         modifier onlyAdmin() {
            require(msg.sender == admin, "Only admin has access to this function");
            _;
    }

    constructor(uint _goal, uint _deadline,address _admin) {
            goal = _goal * (1 ether);
            deadline = block.timestamp + _deadline;
            admin = _admin;
            minimumContribution = 100 wei;
    }
        
    function contribute() public payable {
            require(block.timestamp < deadline,"Sorry deadline has passed");
            require(msg.value > minimumContribution, "Minimum contribution is 100 wei!! Please up your contribution");

            if(contributions[msg.sender] == 0){
                numberOfContributors++;
            }
            contributions[msg.sender] += msg.value;
            raisedAmount += msg.value;
            emit ContributionEvent(msg.sender,msg.value);        
    }
    receive() payable external {
            contribute();
        }

    function getBalance() public view returns(uint amount) {
            return address(this).balance;
    }

    function refund() public {
            require(block.timestamp > deadline && raisedAmount < goal,"Sorry no refunds at the moment");
            require(contributions[msg.sender] > 0, "Refunds are only available to contributions");

            address payable recipient = payable(msg.sender);
            uint amount = contributions[msg.sender];
            recipient.transfer(amount);

            contributions[msg.sender] = 0;
    }

    function createRequest(string memory _description, address payable _recipient, uint _amount) public onlyAdmin {
            Request storage newRequest = requests[numRequests];
            numRequests++;

            newRequest.description = _description;
            newRequest.recipient = _recipient;
            newRequest.amount = _amount;
            newRequest.completed = false;
            newRequest.noOfVoters = 0;

            emit RequestEvent(_description,_recipient,_amount);
    }

    function voteRequest(uint _request) public {
            require(contributions[msg.sender] > 0, "Votes are only available to contributions");
            Request storage newRequest = requests[_request];
            require(newRequest.voters[msg.sender] == false, "You have already voted");
            newRequest.voters[msg.sender] = true;
            newRequest.noOfVoters++;
    }

    function makePayment(uint _request) public onlyAdmin {
            require(raisedAmount < goal,"Can't make payment: The raised amount is less than the target!!");
            
            Request storage newRequest = requests[_request];

            require(newRequest.completed == false,"This request has already been processed");
            // require(newRequest.noOfVoters > numberOfContributors/ 2);


            newRequest.recipient.transfer(newRequest.amount);
            newRequest.completed = true;

            emit MakePaymentEvent(newRequest.recipient,newRequest.amount);
    }
}
