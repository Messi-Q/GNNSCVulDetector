pragma solidity ^0.4.9;


 
contract ERC20 {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract LegendsCrowdfund {

    address public creator;
    address public exitAddress;

    uint public start;
    uint public limitVIP;

    LegendsToken public legendsToken;

    mapping (address => uint) public recipientETH;
    mapping (address => uint) public recipientVIP;

    uint public totalETH;
    uint public totalVIP;

    event VIPPurchase(address indexed sender, address indexed recipient, uint ETH, uint VIP);

    modifier saleActive() {
        if (address(legendsToken) == 0) {
            throw;
        }
        if (block.timestamp < start) {
            throw;
        }
        _;
    }

    modifier hasValue() {
        if (msg.value == 0) {
            throw;
        }
        _;
    }

    modifier recipientIsValid(address recipient) {
        if (recipient == 0 || recipient == address(this)) {
            throw;
        }
        _;
    }

    modifier isCreator() {
        if (msg.sender != creator) {
            throw;
        }
        _;
    }

    modifier tokenContractNotSet() {
        if (address(legendsToken) != 0) {
            throw;
        }
        _;
    }

     
    function LegendsCrowdfund(address _exitAddress, uint _start, uint _limitVIP) {
        creator = msg.sender;
        exitAddress = _exitAddress;
        start = _start;
        limitVIP = _limitVIP;
    }

     
    function setTokenContract(LegendsToken _legendsToken) external isCreator tokenContractNotSet {
        legendsToken = _legendsToken;
    }

     
    function purchaseMembership(address sender, address recipient) external payable saleActive hasValue recipientIsValid(recipient) {

        if (msg.sender != address(legendsToken)) {
            throw;
        }
         
        if (!exitAddress.send(msg.value)) {
            throw;
        }

         
        recipientETH[recipient] += msg.value;
        totalETH += msg.value;

         
        uint VIP = msg.value * 10;   

         
        if (block.timestamp - start < 2 weeks) {
            VIP = (VIP * 10) / 9;    
        }

         
        recipientVIP[recipient] += VIP;
        totalVIP += VIP;

         
        if (totalVIP > limitVIP) {
            throw;
        }

         
        legendsToken.addTokens(recipient, VIP);

         
        VIPPurchase(sender, recipient, msg.value, VIP);
    }

}


 
contract LegendsToken is ERC20 {
    string public name = 'VIP';              
    uint8 public decimals = 18;              
    string public symbol = 'VIP';            
    string public version = 'VIP_0.1';

    mapping (address => uint) ownerVIP;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalVIP;
    uint public start;

    address public legendsCrowdfund;

    bool public testing;

    modifier fromCrowdfund() {
        if (msg.sender != legendsCrowdfund) {
            throw;
        }
        _;
    }

    modifier isActive() {
        if (block.timestamp < start) {
            throw;
        }
        _;
    }

    modifier isNotActive() {
        if (!testing && block.timestamp >= start) {
            throw;
        }
        _;
    }

    modifier recipientIsValid(address recipient) {
        if (recipient == 0 || recipient == address(this)) {
            throw;
        }
        _;
    }

    modifier allowanceIsZero(address spender, uint value) {
         
         
         
         
        if ((value != 0) && (allowed[msg.sender][spender] != 0)) {
            throw;
        }
        _;
    }

     
    function LegendsToken(address _legendsCrowdfund, address _preallocation, uint _start, bool _testing) {
        legendsCrowdfund = _legendsCrowdfund;
        start = _start;
        testing = _testing;
        totalVIP = ownerVIP[_preallocation] = 25000 ether;
    }

     
    function addTokens(address recipient, uint VIP) external isNotActive fromCrowdfund {
        ownerVIP[recipient] += VIP;
        totalVIP += VIP;
        Transfer(0x0, recipient, VIP);
    }

     
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = totalVIP;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        balance = ownerVIP[_owner];
    }

     
    function transfer(address _to, uint256 _value) isActive recipientIsValid(_to) returns (bool success) {
        if (ownerVIP[msg.sender] >= _value) {
            ownerVIP[msg.sender] -= _value;
            ownerVIP[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) isActive recipientIsValid(_to) returns (bool success) {
        if (allowed[_from][msg.sender] >= _value && ownerVIP[_from] >= _value) {
            ownerVIP[_to] += _value;
            ownerVIP[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function approve(address _spender, uint256 _value) isActive allowanceIsZero(_spender, _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
    }

     
    function () payable {
        LegendsCrowdfund(legendsCrowdfund).purchaseMembership.value(msg.value)(msg.sender, msg.sender);
    }

     
    function purchaseMembership(address recipient) payable {
        LegendsCrowdfund(legendsCrowdfund).purchaseMembership.value(msg.value)(msg.sender, recipient);
    }

}