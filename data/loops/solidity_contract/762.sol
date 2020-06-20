pragma solidity 0.4.24;


 
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
         
         
         
        return a / b;
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
    address public creater;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable(address _owner) public {
        creater = msg.sender;
        if (_owner != 0) {
            owner = _owner;

        }
        else {
            owner = creater;
        }

    }
     

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isCreator() {
        require(msg.sender == creater);
        _;
    }

   

}


contract TravelHelperToken {
    function transfer (address, uint) public pure { }
    function burnTokensForSale() public returns (bool);
    function saleTransfer(address _to, uint256 _value) public returns (bool) {}
    function finalize() public pure { }
}

contract Crowdsale is Ownable {
  using SafeMath for uint256;

   
  TravelHelperToken public token;
  
  uint public ethPrice;

   
  address public wallet;

   
  uint256 public weiRaised;
  bool public crowdsaleStarted = false;
  uint256 public preIcoCap = uint256(1000000000).mul(1 ether);
  uint256 public icoCap = uint256(1500000000).mul(1 ether);
  uint256 public preIcoTokensSold = 0;
  uint256 public discountedIcoTokensSold = 0;
  uint256 public icoTokensSold = 0;
  
  
  uint256 public mainTokensPerDollar = 400 * 1 ether;
  
  uint256 public totalRaisedInCents;
  uint256 public presaleTokensPerDollar = 533.3333 * 1 ether;
  uint256 public discountedTokensPerDollar = 444.4444 * 1 ether;
  uint256 public hardCapInCents = 525000000;
  uint256 public preIcoStartBlock;
  uint256 public discountedIcoStartBlock;
  uint256 public mainIcoStartBlock;
  uint256 public mainIcoEndBlock;
  uint public preSaleDuration =  (7 days)/(15);
  uint public discountedSaleDuration = (15 days)/(15); 
  uint public mainSaleDuration = (15 days)/(15); 
  
  
  modifier CrowdsaleStarted(){
      require(crowdsaleStarted);
      _;
  }
 
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(address _newOwner, address _wallet, TravelHelperToken _token,uint256 _ethPriceInCents) Ownable(_newOwner) public {
    require(_wallet != address(0));
    require(_token != address(0));
    require(_ethPriceInCents > 0);
    wallet = _wallet;
    owner = _newOwner;
    token = _token;
    ethPrice = _ethPriceInCents;  
  }

  function startCrowdsale() onlyOwner public returns (bool) {
      require(!crowdsaleStarted);
      crowdsaleStarted = true;
      preIcoStartBlock = block.number;
      discountedIcoStartBlock = block.number + preSaleDuration;
      mainIcoStartBlock = block.number + preSaleDuration + discountedSaleDuration;
      mainIcoEndBlock = block.number + preSaleDuration + discountedSaleDuration + mainSaleDuration;
      
  }
  
   
   
   

   
  function () external payable {
    require(msg.sender != owner);
     buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) CrowdsaleStarted public payable {
    uint256 weiAmount = msg.value;
    require(weiAmount > 0);
    require(ethPrice > 0);
    uint256 usdCents = weiAmount.mul(ethPrice).div(1 ether); 

     
    uint256 tokens = _getTokenAmount(usdCents);

    _validateTokensLimits(tokens);

     
    weiRaised = weiRaised.add(weiAmount);
    totalRaisedInCents = totalRaisedInCents.add(usdCents);
    _processPurchase(_beneficiary,tokens);
     emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    _forwardFunds();
  }
  
 
    
 function setEthPriceInDollar(uint _ethPriceInCents) onlyOwner public returns(bool) {
      ethPrice = _ethPriceInCents;
      return true;
  }

   
   
   


   
  function _validateTokensLimits(uint256 _tokens) internal {
    if (block.number > preIcoStartBlock && block.number < discountedIcoStartBlock) {
      preIcoTokensSold = preIcoTokensSold.add(_tokens);
      require(preIcoTokensSold <= preIcoCap && totalRaisedInCents <= hardCapInCents);
    } else if(block.number >= discountedIcoStartBlock && block.number < mainIcoStartBlock ) {
       require(discountedIcoTokensSold <= icoCap && totalRaisedInCents <= hardCapInCents);
    } else if(block.number >= mainIcoStartBlock && block.number < mainIcoEndBlock ) {
      icoTokensSold = icoTokensSold.add(_tokens);
      require(icoTokensSold <= icoCap && totalRaisedInCents < hardCapInCents);
    } else {
      revert();
    }
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(token.saleTransfer(_beneficiary, _tokenAmount));
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }
  

   
  function _getTokenAmount(uint256 _usdCents) CrowdsaleStarted public view returns (uint256) {
    uint256 tokens;
    
    if (block.number > preIcoStartBlock && block.number < discountedIcoStartBlock ) tokens = _usdCents.div(100).mul(presaleTokensPerDollar);
    if (block.number >= discountedIcoStartBlock && block.number < mainIcoStartBlock )  tokens = _usdCents.div(100).mul(discountedTokensPerDollar);
    if (block.number >= mainIcoStartBlock && block.number < mainIcoEndBlock )  tokens = _usdCents.div(100).mul(mainTokensPerDollar);
    

    return tokens;
  }
  
    
    function getStage() public view returns (string) {
        if(!crowdsaleStarted){
            return 'Crowdsale not started yet';
        }
        if (block.number > preIcoStartBlock && block.number < discountedIcoStartBlock )
        {
            return 'Presale';
        }
        else if (block.number >= discountedIcoStartBlock  && block.number < mainIcoStartBlock ) {
            return 'Discounted sale';
        }
        else if (block.number >= mainIcoStartBlock && block.number < mainIcoEndBlock )
        {
            return 'Crowdsale';
        }
        else if(block.number > mainIcoEndBlock)
        {
            return 'Sale ended';
        }
      
     }
      
     
     function burnTokens() public onlyOwner {
        require(block.number > mainIcoEndBlock);
        require(token.burnTokensForSale());
      }
        
   
  function finalizeSale() public onlyOwner {
    require(block.number > mainIcoEndBlock);
    token.finalize();
  }
  
  
   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}