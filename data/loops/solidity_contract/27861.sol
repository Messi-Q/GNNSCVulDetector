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

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

 
interface Token {
  function transferFrom(address _from, address _to) public returns (bool);
  
  function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract CLUB1 is Ownable {

  using SafeMath for uint256;
  Token token;

  address public CurrentTokenOwner = address(this);
  address tokenAddress = 0x0356e14C2f8De339131C668c1747dEF594467a9A;   
  uint256 public CurrentPrice = 0;

  mapping (address => bool) prevowners;
  
  event BoughtToken(address indexed to, uint256 LastPrice);

  
  function CLUB1() public payable {
       
      token = Token(tokenAddress); 
            
  }
  
  function checkprevowner(address _owner) public constant returns (bool isOwned) {

    return prevowners[_owner];

  }
  
  
  function () public payable {
   
    buyToken();
   
  }

   
  function buyToken() public payable {
    
    uint256 lastholdershare = CurrentPrice * 90 / 100;
    uint256 ownershare = msg.value * 10 / 100; 

    require(msg.value > CurrentPrice);    

    BoughtToken(msg.sender, msg.value);

    token.transferFrom(CurrentTokenOwner, msg.sender);      
  
    CurrentPrice = msg.value;
      
    if (lastholdershare > 0) CurrentTokenOwner.transfer(lastholdershare);
    owner.transfer(ownershare);                            
    
    CurrentTokenOwner = msg.sender;                        
    prevowners[msg.sender] = true;
  }

   function resetToken() public payable {
    
    require(msg.sender == tokenAddress);
    uint256 lastholdershare = CurrentPrice * 90 / 100;
        
    BoughtToken(msg.sender, 0);

    CurrentPrice = 0;
    
    CurrentTokenOwner.transfer(lastholdershare);
    CurrentTokenOwner = address(this);
    
  }

    
  function destroy() public onlyOwner {
   selfdestruct(owner);
  }

}