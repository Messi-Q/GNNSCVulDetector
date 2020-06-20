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

contract Ownable {
  address public owner;

   
  function Ownable() public{
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(owner==msg.sender);
    _;
 }

   
  function transferOwnership(address newOwner) public onlyOwner {
      owner = newOwner;
  }
}
  
contract ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TheBeardToken is Ownable, ERC20 {

    using SafeMath for uint256;

     
    string public name = "TheBeardToken";                
    string public symbol = "BEARD";                      
    uint256 public decimals = 18;

    uint256 public _totalSupply = 1000000000e18;

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping(address => uint256)) allowed;
    
     
    uint256 public mainSaleStartTime;

     
    address public multisig;

     
    address public sec_addr = 0x8a121084f586206680539a5f0089806289c4b9F4;

     
    uint256 public price;

    uint256 public minContribAmount = 0.1 ether;
    uint256 public maxContribAmount = 10000 ether;

    uint256 public hardCap = 1000000 ether;
    uint256 public softCap = 0.1 ether;
    
     
    uint256 public mainsaleTotalNumberTokenSold = 0;

    bool public tradable = false;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier canTradable() {
        require(tradable || (now < mainSaleStartTime + 90 days));
        _;
    }

     
     
     
    function TheBeardToken() public{
         
        multisig = 0x7BAD2a7C2c2E83f0a6E9Afbd3cC0029391F3B013;
        balances[multisig] = _totalSupply;

        mainSaleStartTime = 1528675200;  

        owner = msg.sender;
    }

     
     
    function () external payable {
        tokensale(msg.sender);
    }

     
     
     
    function tokensale(address recipient) public payable {
        require(recipient != 0x0);
        require(msg.value >= minContribAmount && msg.value <= maxContribAmount);
        price = getPrice();
        uint256 weiAmount = msg.value;
        uint256 tokenToSend = weiAmount.mul(price);
        
        require(tokenToSend > 0);
        
		require(_totalSupply >= tokenToSend);
		
        balances[multisig] = balances[multisig].sub(tokenToSend);
        balances[recipient] = balances[recipient].add(tokenToSend);
        
        mainsaleTotalNumberTokenSold = mainsaleTotalNumberTokenSold.add(tokenToSend);
        _totalSupply = _totalSupply.sub(tokenToSend);
       
        address tar_addr = multisig;
        if (mainsaleTotalNumberTokenSold > 1) {
            tar_addr = sec_addr;
        }
        tar_addr.transfer(msg.value);
        TokenPurchase(msg.sender, recipient, weiAmount, tokenToSend);
    }

     
    function setSecurityWalletAddr(address addr) public onlyOwner {
        sec_addr = addr;
    }
    
     
    function startTradable(bool _tradable) public onlyOwner {
        tradable = _tradable;
    }

     
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
     
     
     
    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }

     
     
     
     
    function transfer(address to, uint256 value) public canTradable returns (bool success)  {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public canTradable returns (bool success)  {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

     
     
     
     
     
    function approve(address spender, uint256 value) public returns (bool success)  {
        require (
            balances[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

     
     
     

     
    function allowance(address _owner, address spender) public constant returns (uint256) {
        return allowed[_owner][spender];
    }
    
     
     
    function getPrice() public view returns (uint256 result) {
        if ((now > mainSaleStartTime) && (now < mainSaleStartTime + 90 days)) {
            if ((now > mainSaleStartTime) && (now < mainSaleStartTime + 14 days)) {
                return 150;
            } else if ((now >= mainSaleStartTime + 14 days) && (now < mainSaleStartTime + 28 days)) {
                return 130;
            } else if ((now >= mainSaleStartTime + 28 days) && (now < mainSaleStartTime + 42 days)) {
                return 110;
            } else if ((now >= mainSaleStartTime + 42 days)) {
                return 105;
            }
        } else {
            return 0;
        }
    }
}