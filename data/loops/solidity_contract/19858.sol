 


pragma solidity ^0.4.21;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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







 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


 

contract MintableToken is StandardToken, Ownable {
    uint public totalSupply = 0;
    address private minter;
    bool public mintingEnabled = true;

    modifier onlyMinter() {
        require(minter == msg.sender);
        _;
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    function mint(address _to, uint _amount) public onlyMinter {
        require(mintingEnabled);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0x0), _to, _amount);
    }

    function stopMinting() public onlyMinter {
        mintingEnabled = false;
    }
}




contract EtherusPreSale is Ownable {
    using SafeMath for uint;

     
     

    uint private constant fractions = 1e18;
    uint private constant millions = 1e6*fractions;

    uint private constant CAP = 15*millions;
    uint private constant SALE_CAP = 5*millions;
    uint private constant ETR_USD_PRICE = 400;  

    uint public ethPrice = 40000;  

     
     

    event AltBuy(address holder, uint tokens, string txHash);
    event Buy(address holder, uint tokens);
    event RunSale();
    event PauseSale();
    event FinishSale();
    event PriceSet(uint USDPerETH);

     
     

    MintableToken public token;
    address authority;  
    address robot;  
    bool public isOpen = false;

     
     

    function EtherusPreSale(address _token, address _multisig, address _authority, address _robot) public {
        token = MintableToken(_token);
        authority = _authority;
        robot = _robot;
        transferOwnership(_multisig);
    }

     
     

     
    function getBonus(uint ethSum) public view returns (uint){

        uint usdSum = ethSum.mul(ethPrice).div(fractions);
        if(usdSum >= 1e6*100)
            return 100;
        if(usdSum >= 5e5*100)
            return 80;
        if(usdSum >= 2.5e5*100)
            return 70;
        if(usdSum >= 2e5*100)
            return 60;
        if(usdSum >= 1.5e5*100)
            return 50;
        if(usdSum >= 1.25e5*100)
            return 40;
        if(usdSum >= 1e5*100)
            return 30;
        if(usdSum >= 7.5e4*100)
            return 20;
        if(usdSum >= 5e4*100)
            return 10;

        return 0;
    }

     
    function getTokensAmount(uint etherVal) public view returns (uint) {
        uint bonus = getBonus(etherVal);
        uint tokens = etherVal.mul(ethPrice).mul(100 + bonus).div(ETR_USD_PRICE*100);
        return tokens;
    }

    function buy(address to) public payable onlyOpen {
        uint amount = msg.value;
        uint tokens = getTokensAmountUnderCap(amount);

        owner.transfer(amount);
        token.mint(to, tokens);

        Buy(to, tokens);
    }

    function () public payable{
        buy(msg.sender);
    }

     
     

    modifier onlyAuthority() {
        require(msg.sender == authority || msg.sender == owner);
        _;
    }

    modifier onlyRobot() {
        require(msg.sender == robot);
        _;
    }

    modifier onlyOpen() {
        require(isOpen);
        _;
    }

     
     

     
    function buyAlt(address to, uint etherAmount, string _txHash) public onlyRobot {
        uint tokens = getTokensAmountUnderCap(etherAmount);
        token.mint(to, tokens);
        AltBuy(to, tokens, _txHash);
    }

    function setAuthority(address _authority) public onlyOwner {
        authority = _authority;
    }

    function setRobot(address _robot) public onlyAuthority {
        robot = _robot;
    }

    function setPrice(uint usdPerEther) public onlyAuthority {
         
        require(1*100 <= usdPerEther && usdPerEther <= 100000*100);
        ethPrice = usdPerEther;
        PriceSet(ethPrice);
    }

     
     
    function open(bool _open) public onlyAuthority {
        isOpen = _open;
        if (_open) {
            RunSale();
        } else {
            PauseSale();
        }
    }

    function finalize() public onlyAuthority {
        uint diff = CAP.sub(token.totalSupply());
        if(diff > 0)  
            token.mint(owner, diff);
        token.stopMinting();
        selfdestruct(owner);
        FinishSale();
    }

     
     

     
    function getTokensAmountUnderCap(uint etherAmount) private view returns (uint){
        uint tokens = getTokensAmount(etherAmount);
        require(tokens > 0);
        require(tokens.add(token.totalSupply()) <= SALE_CAP);
        return tokens;
    }

}