pragma solidity ^0.4.17;

 

 
contract Ownable {
  address public owner;
  address public bot;
   
  function Ownable() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }    
   
  modifier onlyBot() {
    require(msg.sender == bot);
    _;
  }
   
  function changeOwner(address addr) public onlyOwner {
      owner = addr;
  }
   
  function changeBot(address addr) public onlyOwner {
      bot = addr;
  }
   
  function kill() public onlyOwner {
		require(this.balance == 0);
		selfdestruct(owner);
	}
}

  
contract Memberships is Ownable {
   
  enum Membership { Day, Month, Lifetime }
   
  mapping (uint => uint) internal prices;
   
  function getMembershipPrice(Membership membership) public view returns(uint) {
    return prices[uint(membership)];
  }
   
  function setMembershipPrice(Membership membership, uint amount) public onlyOwner {    
		require(amount > 0);
    prices[uint(membership)] = amount;
  }
}

  
contract SignalsSociety is Ownable, Memberships {

   
  event Deposited(address account, uint amount, uint balance, uint timestamp);
   
  event MembershipPaid(address account, Membership membership, uint timestamp);

   
  mapping (address => uint) public balances;

   
  function deposit(address account, uint amount) public {
     
    balances[account] += amount;
     
    Deposited(account, amount, balances[account], now);
  }
   
   
  function acceptMembership(address account, Membership membership, uint discount, address reseller, uint comission) public onlyBot {
     
    uint price = getMembershipPrice(membership) - discount;
     
    require(balances[account] >= price);
     
    balances[account] -= price;
     
    if (reseller != 0x0) {
       
      reseller.transfer(comission);
       
      owner.transfer(price - comission);
    } else {
       
      owner.transfer(price);
    }    
     
    MembershipPaid(account, membership, now);
  }
   
   
  function () public payable {
    deposit(msg.sender, msg.value);
  }
}