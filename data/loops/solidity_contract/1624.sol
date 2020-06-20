pragma solidity ^0.4.21;


 
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

 
    constructor() public {
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

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns  (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract ZXCToken is StandardToken, Ownable {
    using SafeMath for uint256;

     
    string  public constant name = "M726 Coin";
    string  public constant symbol = "M726";
    uint8   public constant decimals = 18;

     
    uint256 public startDate1;
    uint256 public endDate1;

     
    uint256 public startDate2;
    uint256 public endDate2;

      
    uint256 public saleCap;

     
    address public tokenWallet;

     
    address public fundWallet;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

     
    modifier uninitialized() {
        require(tokenWallet == 0x0);
        require(fundWallet == 0x0);
        _;
    }

    constructor() public {}
     
     
    function () public payable {
        buyTokens(msg.sender, msg.value);
    }

     
    function initialize(address _tokenWallet, address _fundWallet, uint256 _start1, uint256 _end1,
                        uint256 _saleCap, uint256 _totalSupply) public
                        onlyOwner uninitialized {
         
        require(_start1 < _end1);
        require(_tokenWallet != 0x0);
        require(_fundWallet != 0x0);
        require(_totalSupply >= _saleCap);

        startDate1 = _start1;
        endDate1 = _end1;
        saleCap = _saleCap;
        tokenWallet = _tokenWallet;
        fundWallet = _fundWallet;
        totalSupply = _totalSupply;

        balances[tokenWallet] = saleCap;
        balances[0xb1] = _totalSupply.sub(saleCap);
    }

     
    function setPeriod(uint period, uint256 _start, uint256 _end) public onlyOwner {
        require(_end > _start);
        if (period == 1) {
            startDate1 = _start;
            endDate1 = _end;
        }else if (period == 2) {
            require(_start > endDate1);
            startDate2 = _start;
            endDate2 = _end;      
        }
    }

     
    function sendForPreICO(address buyer, uint256 amount) public onlyOwner {
        require(saleCap >= amount);

        saleCap = saleCap - amount;
         
        balances[tokenWallet] = balances[tokenWallet].sub(amount);
        balances[buyer] = balances[buyer].add(amount);
    }

         
    function setSaleCap(uint256 _saleCap) public onlyOwner {
        require(balances[0xb1].add(balances[tokenWallet]).sub(_saleCap) > 0);
        uint256 amount=0;
         
        if (balances[tokenWallet] > _saleCap) {
            amount = balances[tokenWallet].sub(_saleCap);
            balances[0xb1] = balances[0xb1].add(amount);
        } else {
            amount = _saleCap.sub(balances[tokenWallet]);
            balances[0xb1] = balances[0xb1].sub(amount);
        }
        balances[tokenWallet] = _saleCap;
        saleCap = _saleCap;
    }

     
    function getBonusByTime(uint256 atTime) public constant returns (uint256) {
        if (atTime < startDate1) {
            return 0;
        } else if (endDate1 > atTime && atTime > startDate1) {
            return 5000;
        } else if (endDate2 > atTime && atTime > startDate2) {
            return 2500;
        } else {
            return 0;
        }
    }

    function getBounsByAmount(uint256 etherAmount, uint256 tokenAmount) public pure returns (uint256) {
         
        uint256 bonusRatio = etherAmount.div(500 ether);
        if (bonusRatio > 4) {
            bonusRatio = 4;
        }
        uint256 bonusCount = SafeMath.mul(bonusRatio, 10);
        uint256 bouns = SafeMath.mul(tokenAmount, bonusCount);
        uint256 realBouns = SafeMath.div(bouns, 100);
        return realBouns;
    }

     
    function finalize() public onlyOwner {
        require(!saleActive());

         
        balances[tokenWallet] = balances[tokenWallet].add(balances[0xb1]);
        balances[0xb1] = 0;
    }
    
     
    function saleActive() public constant returns (bool) {
        return (
            (getCurrentTimestamp() >= startDate1 &&
                getCurrentTimestamp() < endDate1 && saleCap > 0) ||
            (getCurrentTimestamp() >= startDate2 &&
                getCurrentTimestamp() < endDate2 && saleCap > 0)
                );
    }
   
     
    function getCurrentTimestamp() internal view returns (uint256) {
        return now;
    }

      
    function buyTokens(address sender, uint256 value) internal {
         
        require(saleActive());
        
         
        require(value >= 0.5 ether);

         
        uint256 bonus = getBonusByTime(getCurrentTimestamp());
        uint256 amount = value.mul(bonus);
         
        if (getCurrentTimestamp() >= startDate1 && getCurrentTimestamp() < endDate1) {
            uint256 p1Bouns = getBounsByAmount(value, amount);
            amount = amount + p1Bouns;
        }
         
        require(saleCap >= amount);

         
        balances[tokenWallet] = balances[tokenWallet].sub(amount);
        balances[sender] = balances[sender].add(amount);
        TokenPurchase(sender,value, amount);
        
        saleCap = saleCap - amount;

         
        weiRaised = weiRaised + value;

         
         
        fundWallet.transfer(msg.value);
    }   
}