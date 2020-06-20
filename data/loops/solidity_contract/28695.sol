pragma solidity ^0.4.18;

 
  


pragma solidity ^0.4.18;


 

 


 


 


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
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
 
 


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}
 

 

contract MintableToken is StandardToken, Ownable {
    uint public totalSupply = 0;
    address minter;

    modifier onlyMinter(){
        require(minter == msg.sender);
        _;
    }

    function setMinter(address _minter) onlyOwner {
        minter = _minter;
    }

    function mint(address _to, uint _amount) onlyMinter {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0x0), _to, _amount);
    }
}
 
 



 




 
contract ERC23 is ERC20Basic {
    function transfer(address to, uint value, bytes data);

    event TransferData(address indexed from, address indexed to, uint value, bytes data);
}
 
 

 

contract ERC23PayableReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) payable;
}

 

 
contract ERC23PayableToken is BasicToken, ERC23{
     
    function transfer(address to, uint value, bytes data){
        transferAndPay(to, value, data);
    }

     
     
    function transfer(address to, uint value) returns (bool){
        bytes memory empty;
        transfer(to, value, empty);
        return true;
    }

    function transferAndPay(address to, uint value, bytes data) payable {

        uint codeLength;

        assembly {
             
            codeLength := extcodesize(to)
        }

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        if(codeLength>0) {
            ERC23PayableReceiver receiver = ERC23PayableReceiver(to);
            receiver.tokenFallback.value(msg.value)(msg.sender, value, data);
        }else if(msg.value > 0){
            to.transfer(msg.value);
        }

        Transfer(msg.sender, to, value);
        if(data.length > 0)
            TransferData(msg.sender, to, value, data);
    }
}
 


contract NYXToken is MintableToken, ERC23PayableToken {
    string public constant name = "NYX Token";
    string public constant symbol = "NYX";

    bool public transferEnabled = true;

     
    uint private constant CAP = 15*(10**6);

    function mint(address _to, uint _amount){
        require(totalSupply.add(_amount) <= CAP);
        super.mint(_to, _amount);
    }

    function NYXToken(address team) {
         
        transferOwnership(team);
         
        minter = msg.sender; 
         
        mint(team, 3000000);
    }

     
    function transferAndPay(address to, uint value, bytes data) payable{
        require(transferEnabled);
        super.transferAndPay(to, value, data);
    }

    function enableTransfer(bool enabled) onlyOwner{
        transferEnabled = enabled;
    }

}

contract TokenSale is Ownable {
    using SafeMath for uint;

     
     
    uint private constant millions = 1e6;

    uint private constant CAP = 15*millions;
    uint private constant SALE_CAP = 12*millions;
    uint private constant SOFT_CAP = 1400000;
    
     
     
    uint private constant TEAM_CAP = 3000000;

    uint public price = 0.001 ether;
    
     
    address[] contributors;
    mapping(address => uint) contributions;

     
     

    event AltBuy(address holder, uint tokens, string txHash);
    event Buy(address holder, uint tokens);
    event RunSale();
    event PauseSale();
    event FinishSale();
    event PriceSet(uint weiPerNYX);

     
     
    bool public presale = true;
    NYXToken public token;
    address authority;  
    address robot;  
    bool public isOpen = true;

     
     

    function TokenSale(){
        token = new NYXToken(msg.sender);

        authority = msg.sender;
        robot = msg.sender;
        transferOwnership(msg.sender);
    }

     
     
    function togglePresale(bool activate) onlyAuthority {
        presale = activate;
    }


    function getCurrentPrice() constant returns(uint) {
        if(presale) {
            return price - (price*20/100);
        }
        return price;
    }
     
    function getTokensAmount(uint etherVal) constant returns (uint) {
        uint tokens = 0;
        tokens += etherVal/getCurrentPrice();
        return tokens;
    }

    function buy(address to) onlyOpen payable{
        uint amount = msg.value;
        uint tokens = getTokensAmountUnderCap(amount);
        
         

		token.mint(to, tokens);
		
		uint alreadyContributed = contributions[to];
		if(alreadyContributed == 0)  
		    contributors.push(to);
		    
		contributions[to] = contributions[to].add(msg.value);

        Buy(to, tokens);
    }

    function () payable{
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

     
     

     
    function buyAlt(address to, uint etherAmount, string _txHash) onlyRobot {
        uint tokens = getTokensAmountUnderCap(etherAmount);
        token.mint(to, tokens);
        AltBuy(to, tokens, _txHash);
    }

    function setAuthority(address _authority) onlyOwner {
        authority = _authority;
    }

    function setRobot(address _robot) onlyAuthority {
        robot = _robot;
    }

    function setPrice(uint etherPerNYX) onlyAuthority {
        price = etherPerNYX;
        PriceSet(price);
    }

     
     
    function open(bool opn) onlyAuthority {
        isOpen = opn;
        opn ? RunSale() : PauseSale();
    }
    
    function finalizePresale() onlyAuthority {
         
        require(token.totalSupply() > SOFT_CAP + TEAM_CAP);
         
        owner.transfer(this.balance);
    }

    function finalize() onlyAuthority {
         
        if(token.totalSupply() < SOFT_CAP + TEAM_CAP) {  
            uint x = 0;
            while(x < contributors.length) {
                uint amountToReturn = contributions[contributors[x]];
                contributors[x].transfer(amountToReturn);
                x++;
            }
        }
        
        uint diff = CAP.sub(token.totalSupply());
        if(diff > 0)  
            token.mint(owner, diff);
        selfdestruct(owner);
        FinishSale();
    }

     
     

     
    function getTokensAmountUnderCap(uint etherAmount) private constant returns (uint){
        uint tokens = getTokensAmount(etherAmount);
        require(tokens > 0);
        require(tokens.add(token.totalSupply()) <= SALE_CAP);
        return tokens;
    }

}