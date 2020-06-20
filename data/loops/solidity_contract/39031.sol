pragma solidity ^0.4.11;

 

 
contract ERC20 {
  function transfer(address _to, uint _value) returns (bool success);
}

contract BancorBuyer {
   
  mapping (address => uint) public balances;
   
  bool public bought_tokens;
   
  uint public time_bought;
  
   
  address sale = 0xBbc79794599b19274850492394004087cBf89710;
   
  address token = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
   
  address developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;
  
   
   
  function withdraw(){
     
    uint amount = balances[msg.sender];
     
    balances[msg.sender] = 0;
     
    msg.sender.transfer(amount);
  }
  
   
  function buy(){
     
     
     
    sale.transfer(this.balance);
     
    bought_tokens = true;
     
    time_bought = now;
  }
  
  function () payable {
     
    if (!bought_tokens) {
       
      balances[msg.sender] += msg.value;
    }
     
    else {
       
      uint amount = balances[msg.sender] * 100;
       
      balances[msg.sender] = 0;
       
      uint fee = 0;
       
      if (now > time_bought + 1 hours) {
        fee = amount / 100;
      }
       
      ERC20(token).transfer(msg.sender, amount - fee);
      ERC20(token).transfer(developer, fee);
       
      msg.sender.transfer(msg.value);
    }
  }
}