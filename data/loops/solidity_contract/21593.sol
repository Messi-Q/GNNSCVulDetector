pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract IERC20 {

    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract QPSEToken is IERC20 {

    using SafeMath for uint256;

     
    string public name = "Qompass";
    string public symbol = "QPSE";
    uint public decimals = 18;

    uint private constant STAGE_PRE_ICO = 1;
    uint private constant STAGE_MAIN_ICO = 2;

    uint public ico_stage = 0;
    uint public _totalSupply = 33000000e18;

    uint public _icoSupply = 20000000e18;  
    uint public _presaleSupply = 8000000e18;
    uint public _mainsaleSupply = 12000000e18;
    uint public _futureSupply = 13000000e18;
                                    
 
    uint256 public pre_endTime = 1523854800;     
	
    uint256 public ico_startTime = 1523854800;   
 

    address eth_addr = 0xE3a08428160C8B7872EcaB35578D3304239a5748;
    address token_addr = 0xDB882cFbA6A483b7e0FdedCF2aa50fA311DD392e;

 
 

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping(address => uint256)) allowed;

     
    address public owner;

     
    uint public PRICE = 800;
    uint public pre_PRICE = 960;   
    uint public ico_PRICE = 840;   

     
    uint256 public fundRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
     
     
    function QPSEToken() public payable {
        owner = msg.sender;
	    fundRaised = 0;
        balances[token_addr] = _totalSupply; 
    }

     
     
    function () public payable {
        tokensale(msg.sender);
    }

     
     
     
    function tokensale(address recipient) public payable {
        require(recipient != 0x0);
 

        if (now < pre_endTime) {
            ico_stage = STAGE_PRE_ICO;
        } else {
            ico_stage = STAGE_MAIN_ICO;
        }

        if ( fundRaised >= _presaleSupply ) {
            ico_stage = STAGE_MAIN_ICO;
        }
	
        uint256 weiAmount = msg.value;
        uint tokens = weiAmount.mul(getPrice());

        require(_icoSupply >= tokens);

        balances[token_addr] = balances[token_addr].sub(tokens);
        balances[recipient] = balances[recipient].add(tokens);

        _icoSupply = _icoSupply.sub(tokens);
        fundRaised = fundRaised.add(tokens);

        TokenPurchase(msg.sender, recipient, weiAmount, tokens);
        if ( tokens == 0 ) {
            recipient.transfer(msg.value);
        } else {
            eth_addr.transfer(msg.value);    
        }
    }

     
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }

     
    function sendTokenToMultiAddr(address[] _toAddresses, uint256[] _amounts) public {
	 
        require(_toAddresses.length <= 255);
         
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transfer(_toAddresses[i], _amounts[i]);
        }
    }

     
     
     
     
    function transfer(address to, uint256 value) public returns (bool success) {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require (
            balances[msg.sender] >= _value && _value > 0
        );
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowed[_owner][spender];
    }

     
     
    function getPrice() public view returns (uint result) {
        if ( ico_stage == STAGE_PRE_ICO ) {
    	    return pre_PRICE;
    	} if ( ico_stage == STAGE_MAIN_ICO ) {
    	    return ico_PRICE;
    	}
    }
}