pragma solidity ^0.4.24;

 
contract PayItBack {

    uint constant HOLD_TIME = 31 days;

    address public creator;
    uint public contributionTime = 0;
    uint public totalContributions = 0;
    bool public isDisabled = false;

	event Contribution(uint _amount, address _from);
	event OwnershipConfirmed();
	event PaidOut(uint _amount);
	event Warning(string _message);
	event Disabled();

    modifier ownerOnly() {
        require(msg.sender == creator, 
                "Sorry, you're not the owner of this contract");

        _;
    }

    modifier nilBalance() {
        require(address(this).balance <= 0, 
                "Balance is not 0");

        _;
    }
    
    modifier afterHoldExpiry() {
        require(contributionTime > 0, 
                "No contributions have been received");
        require(now > (contributionTime + HOLD_TIME), 
                "Payments are on hold");

        _;
    }
    
    modifier enabled() {
        require(!isDisabled, 
                "This contract has been disabled");

        _;
    }

    modifier wontOverflow() {
        require(totalContributions + msg.value > totalContributions);

        _;
    }

    constructor() public {
        creator = msg.sender;
    }

     
    function () public payable {
        contribute();
    }

    function contribute() public payable enabled wontOverflow {
         
         
        if (contributionTime == 0 && msg.value > 0) {
            contributionTime = now;
        }

        totalContributions += msg.value;

        emit Contribution(msg.value, msg.sender);
    }

     
    function payUp() public ownerOnly afterHoldExpiry {
        uint payment = address(this).balance;
        totalContributions -= payment;
        if (totalContributions != 0) {
             
            emit Warning("Balance is unexpectedly non-zero after payment");
        }
        contributionTime = 0;  
        emit PaidOut(payment);
        creator.transfer(payment);
    }

    function verifyOwnership() public ownerOnly returns(bool) {
        emit OwnershipConfirmed();

        return true;
    }

     
     
    function disable() public ownerOnly nilBalance enabled {
        isDisabled = true;
        
        emit Disabled();
    }
    
    function expiryTime() public view returns(uint) {
        return contributionTime + HOLD_TIME;
    }
    
    function daysMinutesTilExpiryTime() public view returns(uint, uint) {
        uint secsLeft = (contributionTime + HOLD_TIME - now);
        uint daysLeft = secsLeft / 1 days;
        uint minsLeft = (secsLeft % 1 days) / 1 minutes;
        return (daysLeft, minsLeft);
    }
}