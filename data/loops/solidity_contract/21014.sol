pragma solidity ^0.4.11;



 

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



 

contract token { function transfer(address receiver, uint amount){  } }

contract Crowdsale {

  using SafeMath for uint256;



   

   

  address public wallet;

   

  address addressOfTokenUsedAsReward;



  token tokenReward;







   

  uint256 public startTime;

  uint256 public endTime;

   

  uint256 public weiRaised;



   

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);





  function Crowdsale() {

    wallet = 0x205E2ACd291E235425b5c10feC8F62FE7Ec26063;

     

    addressOfTokenUsedAsReward = 0x82B99C8a12B6Ee50191B9B2a03B9c7AEF663D527;





    tokenReward = token(addressOfTokenUsedAsReward);

  }



  bool started = false;



  function startSale(uint256 delay){

    if (msg.sender != wallet || started) throw;

    startTime = now + delay * 1 minutes;

    endTime = startTime + 20 * 24 * 60 * 1 minutes;

    started = true;

  }



   

  function () payable {

    buyTokens(msg.sender);

  }



   

  function buyTokens(address beneficiary) payable {

    require(beneficiary != 0x0);

    require(validPurchase());



    uint256 weiAmount = msg.value;



     

    uint256 tokens = (weiAmount/10**10) * 490;



    if(now < startTime + 1*7*24*60* 1 minutes){

      tokens += (tokens * 20) / 100;

    }else if(now < startTime + 2*7*24*60* 1 minutes){

      tokens += (tokens * 10) / 100;

    }else{

      tokens += (tokens * 5) / 100;

    }



     

    weiRaised = weiRaised.add(weiAmount);



    tokenReward.transfer(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();

  }



   

   

  function forwardFunds() internal {

     

    if (!wallet.send(msg.value)) {

      throw;

    }

  }



   

  function validPurchase() internal constant returns (bool) {

    bool withinPeriod = now >= startTime && now <= endTime;

    bool nonZeroPurchase = msg.value != 0;

    return withinPeriod && nonZeroPurchase;

  }



   

  function hasEnded() public constant returns (bool) {

    return now > endTime;

  }



  function withdrawTokens(uint256 _amount) {

    if(msg.sender!=wallet) throw;

    tokenReward.transfer(wallet,_amount);

  }

}