pragma solidity ^0.4.18;

 
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


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 
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

    mapping(address => uint256) public balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
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
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

 
contract CABoxToken is BurnableToken, Ownable {

    string public constant name = "CABox";
    string public constant symbol = "CAB";
    uint8 public constant decimals = 18;
    
    uint256 public constant INITIAL_SUPPLY = 500 * 1000000 * (10 ** uint256(decimals));

     
    function CABoxToken() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}


 
contract CABoxCrowdsale is Ownable{
  using SafeMath for uint256;

   
  CABoxToken public token;

   
  uint256 public startTime;
  uint256 public endTime;
    
   
  address public wallet;
    
   
  address public devWallet;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event TokenContractUpdated(bool state);

  event WalletAddressUpdated(bool state);

  function CABoxCrowdsale() public {
    token = createTokenContract();
    startTime = 1535155200;
    endTime = 1540771200;
    wallet = 0x9BeAbD0aeB08d18612d41210aFEafD08fb84E9E8;
    devWallet = 0x13dF1d8F51324a237552E87cebC3f501baE2e972;
  }

   
   
  function createTokenContract() internal returns (CABoxToken) {
    return new CABoxToken();
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 bonusRate = getBonusRate();
    uint256 tokens = weiAmount.mul(bonusRate);

    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }
  
  function getBonusRate() internal view returns (uint256) {
        uint64[5] memory tokenRates = [uint64(24000),uint64(20000),uint64(16000),uint64(12000),uint64(8000)];
    
         
        uint64[5] memory timeStartsBoundaries = [uint64(1535155200),uint64(1538352000),uint64(1538956800),uint64(1539561600),uint64(1540166400)];
        uint64[5] memory timeEndsBoundaries = [uint64(1538352000),uint64(1538956800),uint64(1539561600),uint64(1540166400),uint64(1540771200)];
        uint[5] memory timeRates = [uint(500),uint(250),uint(200),uint(150),uint(100)];
    
        uint256 bonusRate = tokenRates[0];
    
        for (uint i = 0; i < 5; i++) {
            bool timeInBound = (timeStartsBoundaries[i] <= now) && (now < timeEndsBoundaries[i]);
            if (timeInBound) {
                bonusRate = tokenRates[i] + tokenRates[i] * timeRates[i] / 1000;
            }
        }
        
        return bonusRate;
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value * 750 / 1000);
    devWallet.transfer(msg.value * 250 / 1000);
  }

   
  function validPurchase() internal view returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    bool withinPeriod = now >= startTime && now <= endTime;
    
    return nonZeroPurchase && withinPeriod;
  }
  
   
  function hasEnded() public view returns (bool) {
      bool timeEnded = now > endTime;

      return timeEnded;
  }
  
   
   function updateCABoxToken(address _tokenAddress) onlyOwner{
      require(_tokenAddress != address(0));
      token.transferOwnership(_tokenAddress);

      TokenContractUpdated(true);
  }
  
   
  function transferTokens(address _to, uint256 _amount) onlyOwner {
      require(_to != address(0));
      
      token.transfer(_to, _amount);
  }
}