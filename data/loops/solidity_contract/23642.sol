pragma solidity ^0.4.19;


 
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



contract WelCoinICO is Ownable {

  using SafeMath for uint256;

   
  uint256 public mainSaleStartTime;
  uint256 public mainSaleEndTime;

   
   

   
  uint256 public mainSaleMinimumWei;

   
  address public wallet;

   
  address public token;

   
  uint256 public rate;

   
  uint256 public percent;

   
   

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function WelCoinICO(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime, address _wallet, address _token) public {

     
    require(_mainSaleStartTime < _mainSaleEndTime);
    require(_wallet != 0x0);

    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    wallet = _wallet;
    token = _token;
    rate = 2500;
    percent = 0;
    mainSaleMinimumWei = 100000000000000000;  
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {

    require(beneficiary != 0x0);
    require(msg.value != 0x0);
    require(msg.value >= mainSaleMinimumWei);
    require(now >= mainSaleStartTime && now <= mainSaleEndTime);

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    uint256 bonusedTokens = applyBonus(tokens, percent);

    require(token.call(bytes4(keccak256("transfer(address,uint256)")), beneficiary, bonusedTokens));

     
    TokenPurchase(msg.sender, beneficiary, weiAmount, bonusedTokens);

    forwardFunds();
  }

   
  function setMainSaleParameters(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime, uint256 _mainSaleMinimumWei) public onlyOwner {
    require(_mainSaleStartTime < _mainSaleEndTime);
    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    mainSaleMinimumWei = _mainSaleMinimumWei;
  }

   
  function setWallet(address _wallet) public onlyOwner {
    require(_wallet != 0x0);
    wallet = _wallet;
  }

     
  function setRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    rate = _rate;
  }

   
  function transferTokens(address _wallet, uint256 _amount) public onlyOwner {
    require(_wallet != 0x0);
    require(_amount != 0);
    require(token.call(bytes4(keccak256("transfer(address,uint256)")), _wallet, _amount));
  }


   
  function mainSaleHasEnded() external constant returns (bool) {
    return now > mainSaleEndTime;
  }

   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }


  function applyBonus(uint256 tokens, uint256 percentToApply) internal pure returns (uint256 bonusedTokens) {
    uint256 tokensToAdd = tokens.mul(percentToApply).div(100);
    return tokens.add(tokensToAdd);
  }

}