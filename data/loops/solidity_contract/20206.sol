pragma solidity ^0.4.19;

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract INeoToken{
    function buyToken(address to, uint tokens) public returns (bool success);
}

 
contract NeoCrowdsale {
  using SafeMath for uint256; 
  uint256 public openingTime;
  uint256 public closingTime;
  address public wallet;       
  uint256 public rate;         
  uint256 public weiRaised;    
  INeoToken public token;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }
  
  function NeoCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;

     
    token = INeoToken(0x468a553b152f65a482e1669672b0dbcd20f9fb50);
    wallet = 0x0c4BdfE0aEbF69dE4975a957A2d4FE72633BBC1a;
    rate = 15000;  
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);
    
     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _forwardFunds(); 
  }
  
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) public onlyWhileOpen{
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }
  
  function _getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
    return _weiAmount.mul(rate);
  }
  
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.buyToken(_beneficiary, _tokenAmount);
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }
  
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

}