pragma solidity ^0.4.11;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
contract BetrToken is MintableToken {

    string public constant name = "BETer";
    string public constant symbol = "BTR";
    uint8 public constant decimals = 18;

    function getTotalSupply() public returns (uint256) {
        return totalSupply;
    }
}

 
contract BetrCrowdsale is Ownable {
  using SafeMath for uint256;

     
    BetrToken public token;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

    uint256 public constant TEAM_LIMIT = 225 * (10 ** 6) * (10 ** 18);
    uint256 public constant PRESALE_LIMIT = 275 * (10 ** 6) * (10 ** 18);
    uint public constant PRESALE_BONUS = 30;
    uint saleStage = 0;  
    bool public isFinalized = false;

     
    event BetrTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function BetrCrowdsale(uint256 _rate, address _wallet, address _tok_addr) {
        require(_rate > 0);
        require(_wallet != address(0));

        token = BetrToken(_tok_addr);
        rate = _rate;
        wallet = _wallet;
    }

     
    function () payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());
        require(!isFinalized);

        uint256 weiAmount = msg.value;

         
        uint256 tokens = computeTokens(weiAmount);

        require(isWithinTokenAllocLimit(tokens));

         
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);

        BetrTokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }


     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        return nonZeroPurchase;
    }
    
     
    function computeTokens(uint256 weiAmount) internal returns (uint256) {
         
        uint256 appliedBonus = 0;
	    if (saleStage == 0) {
             appliedBonus = PRESALE_BONUS;
        }

        return weiAmount.mul(100).mul(100 + appliedBonus).div(rate);
    }

     
    function isWithinTokenAllocLimit(uint256 _tokens) internal returns (bool) {
         
        return token.getTotalSupply().add(_tokens) <= PRESALE_LIMIT;
    }

    function setStage(uint stage) onlyOwner public {
        require(!isFinalized);
        saleStage = stage;
    }

     
    function finalize() onlyOwner public {
        require(!isFinalized);
    
        uint256 ownerShareTokens = TEAM_LIMIT;
        token.mint(wallet, ownerShareTokens);
        
        isFinalized = true;
    }
}