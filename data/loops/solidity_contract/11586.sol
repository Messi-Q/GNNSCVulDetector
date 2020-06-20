pragma solidity ^0.4.18;

 
 
 
 
 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
   
  function  transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    
    
   emit OwnershipTransferred(owner, newOwner); 
    
    owner = newOwner;
  }

}
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
  emit  Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}
 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
   emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
   emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
   emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
   emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
   emit Mint(_to, _amount);
   emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
   emit MintFinished();
    return true;
  }
}

 
contract CompositeCoin is MintableToken {

	string public constant name = "CompositeCoin";
	string public constant symbol = "CMN";
	uint public constant decimals = 18;

}

 
contract CompositeCoinCrowdsale is Ownable {

  using SafeMath for uint256;

   
  CompositeCoin public token;

  uint256 public startTime = 0;
  uint256 public endTime;
  bool public isFinished = false;

   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  uint public tokensMinted = 0;

  uint public minimumSupply = 1;  

  uint public constant HARD_CAP_TOKENS = 1000000 * 10**18;

  event TokenPurchase(address indexed purchaser, uint256 value, uint256 ether_value, uint256 amount, uint256 tokens_amount, uint256 _tokensMinted, uint256 tokensSoldAmount);
  event PresaleFinished();


  function CompositeCoinCrowdsale(uint256 _rate) public {
    require(_rate > 0);
	require (_rate < 10000);

    token = createTokenContract();
    startTime = now;
    rate = _rate;
    owner = address(0xc5EaE151b4c8c88e2Fc76a33595657732D65004a);
  }


  function finishPresale() public onlyOwner {
	  isFinished = true;
	  endTime = now;
	  token.finishMinting();
	 emit PresaleFinished();
  }

  function setRate(uint _rate) public onlyOwner {
	  require (_rate > 0);
	  require (_rate <=10000);
	  rate = _rate;
  }

  function createTokenContract() internal returns (CompositeCoin) {
    return new CompositeCoin();
  }


   
  function () external payable {
    buyTokens();
  }

   
  function buyTokens() public payable {
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(10000).div(rate);

    mintToken(msg.sender, tokens, weiAmount);

    forwardFunds();
  }


  function forwardFunds() internal {
    owner.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = startTime > 0 && !isFinished;
    bool validAmount = msg.value >= (minimumSupply * 10**18 * rate).div(10000);
    return withinPeriod && validAmount;
  }

  function adminMint(address _to, uint256 _amount) onlyOwner public returns(bool) {
      require(!isFinished);
      uint256 weiAmount = _amount.div(10000).mul(rate);
      return mintToken(_to, _amount, weiAmount);
  }

  function mintToken(address _to, uint256 _amount, uint256 _value) private returns(bool) {
      require(tokensMinted.add(_amount) <= HARD_CAP_TOKENS);
      weiRaised = weiRaised.add(_value);
      token.mint(_to, _amount);
      tokensMinted = tokensMinted.add(_amount);
    emit  TokenPurchase(_to, _value, _value.div(10**18), _amount, _amount.div(10**18), tokensMinted, tokensMinted.div(10**18));
      return true;
  }

}