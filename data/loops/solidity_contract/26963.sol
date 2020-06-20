pragma solidity ^0.4.11;

 
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

 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract StandardToken {
  using SafeMath for uint256;
  mapping (address => mapping (address => uint256)) allowed;
  mapping(address => uint256) balances;
  mapping(address => bool) preICO_address;
  uint256 public totalSupply;
  uint256 public endDate;
   
  function transfer(address _to, uint256 _value) public returns (bool) {

    if( preICO_address[msg.sender] ) require( now > endDate + 120 days );  
    else require( now > endDate );  

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  event Transfer(address indexed from, address indexed to, uint256 value);

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    if( preICO_address[_from] ) require( now > endDate + 120 days );  
    else require( now > endDate );  

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    if( preICO_address[msg.sender] ) require( now > endDate + 120 days );  
    else require( now > endDate );  

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  event Approval(address indexed owner, address indexed spender, uint256 value);

   
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract TBCoin is StandardToken, Ownable {
    using SafeMath for uint256;

     
    string  public constant name = "TimeBox Coin";
    string  public constant symbol = "TB";
    uint8   public constant decimals = 18;

     
    uint256 public startDate;
     

     
    uint256 public saleCap;

     
    address public wallet;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, uint256 value,
                        uint256 amount);
    event PreICOTokenPushed(address indexed buyer, uint256 amount);

     
    modifier uninitialized() {
        require(wallet == 0x0);
        _;
    }

    function TBCoin() public{
    }
 
    function initialize(address _wallet, uint256 _start, uint256 _end,
                        uint256 _saleCap, uint256 _totalSupply)
                        public onlyOwner uninitialized {
        require(_start >= getCurrentTimestamp());
        require(_start < _end);
        require(_wallet != 0x0);
        require(_totalSupply > _saleCap);

        startDate = _start;
        endDate = _end;
        saleCap = _saleCap;
        wallet = _wallet;
        totalSupply = _totalSupply;

        balances[wallet] = _totalSupply.sub(saleCap);
        balances[0xb1] = saleCap;
    }

    function supply() internal view returns (uint256) {
        return balances[0xb1];
    }

    function getCurrentTimestamp() internal view returns (uint256) {
        return now;
    }

    function getRateAt(uint256 at) public constant returns (uint256) {
        if (at < startDate) {
            return 0;
        } else if (at < (startDate + 3 days)) {
            return 1500;
        } else if (at < (startDate + 7 days)) {
            return 1440;
        } else if (at < (startDate + 14 days)) {
            return 1380;
        } else if (at < (startDate + 21 days)) {
            return 1320;
        } else if (at < (startDate + 28 days)) {
            return 1260;
        } else if (at <= endDate) {
            return 1200;
        } else {
            return 0;
        }
    }

     
    function () public payable {
        buyTokens(msg.sender, msg.value);
    }

     
    function push(address buyer, uint256 amount) public onlyOwner {  
        require(balances[wallet] >= amount);
        require(now < startDate);
        require(buyer != wallet);

        preICO_address[ buyer ] = true;

         
        balances[wallet] = balances[wallet].sub(amount);
        balances[buyer] = balances[buyer].add(amount);
        PreICOTokenPushed(buyer, amount);
    }

    function buyTokens(address sender, uint256 value) internal {
        require(saleActive());
        require(value >= 0.2 ether);

        uint256 weiAmount = value;
        uint256 updatedWeiRaised = weiRaised.add(weiAmount);

         
        uint256 actualRate = getRateAt(getCurrentTimestamp());
        uint256 amount = weiAmount.mul(actualRate);

         
        require(supply() >= amount);

         
        balances[0xb1] = balances[0xb1].sub(amount);
        balances[sender] = balances[sender].add(amount);
        TokenPurchase(sender, weiAmount, amount);

         
        weiRaised = updatedWeiRaised;

         
        wallet.transfer(msg.value);
    }

    function finalize() public onlyOwner {
        require(!saleActive());

         
        balances[wallet] = balances[wallet].add(balances[0xb1]);
        balances[0xb1] = 0;
    }

    function saleActive() public constant returns (bool) {
        return (getCurrentTimestamp() >= startDate &&
                getCurrentTimestamp() < endDate && supply() > 0);
    }
    
}