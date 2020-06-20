pragma solidity 0.4.21;

 
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract Authorizable is Ownable {
    
    mapping(address => bool) public authorized;
    event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

     
    function Authorizable() public {
        authorize(msg.sender);
    }

     
    modifier onlyAuthorized() {
        require(authorized[msg.sender]);
        _;
    }

     
    function authorize(address _address) public onlyOwner {
        require(!authorized[_address]);
        emit AuthorizationSet(_address, true);
        authorized[_address] = true;
    }
     
    function deauthorize(address _address) public onlyOwner {
        require(authorized[_address]);
        emit AuthorizationSet(_address, false);
        authorized[_address] = false;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract PrivateSaleExchangeRate {
    uint256 public rate;
    uint256 public timestamp;
    event UpdateUsdEthRate(uint _rate);
    function updateUsdEthRate(uint _rate) public;
    function getTokenAmount(uint256 _weiAmount) public view returns (uint256);
}

 
contract Whitelist {
    mapping(address => bool) whitelisted;
    event AddToWhitelist(address _beneficiary);
    event RemoveFromWhitelist(address _beneficiary);
    function isWhitelisted(address _address) public view returns (bool);
    function addToWhitelist(address _beneficiary) public;
    function removeFromWhitelist(address _beneficiary) public;
}

 
 
 
 
 
 
 

contract Crowdsale {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    address public wallet;

     
    PrivateSaleExchangeRate public rate;

     
    uint256 public weiRaised;
    
     
    uint256 public tokenRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    function Crowdsale(PrivateSaleExchangeRate _rate, address _wallet, ERC20 _token) public {
        require(_rate.rate() > 0);
        require(_token != address(0));
        require(_wallet != address(0));

        rate = _rate;
        token = _token;
        wallet = _wallet;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        
          
        uint256 tokenAmount = _getTokenAmount(weiAmount);
        
        _preValidatePurchase(_beneficiary, weiAmount, tokenAmount);

         
        weiRaised = weiRaised.add(weiAmount);
        tokenRaised = tokenRaised.add(tokenAmount);

        _processPurchase(_beneficiary, tokenAmount);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokenAmount);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount > 0);
        require(_tokenAmount > 0);
    }

     
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }
    
     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return rate.getTokenAmount(_weiAmount);
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

 
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;

     
    modifier onlyWhileOpen {
        require(now >= openingTime && now <= closingTime);
        _;
    }

     
    function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
        
        require(_closingTime >= now);
         
        require(_closingTime >= _openingTime);
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

     
    function hasClosed() public view returns (bool) {
        return now > closingTime;
    }

     
    function hasOpening() public view returns (bool) {
        return (now >= openingTime && now <= closingTime);
    }
  
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal onlyWhileOpen {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
    }

}

 
contract AllowanceCrowdsale is Crowdsale {
    using SafeMath for uint256;
    address public tokenWallet;

     
    function AllowanceCrowdsale(address _tokenWallet) public {
        require(_tokenWallet != address(0));
        tokenWallet = _tokenWallet;
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
    }
}

 
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public minWei;
    uint256 public capToken;

     
    function CappedCrowdsale(uint256 _capToken, uint256 _minWei) public {
        require(_minWei > 0);
        require(_capToken > 0);
        minWei = _minWei;
        capToken = _capToken;
    }

     
    function capReached() public view returns (bool) {
        if(tokenRaised >= capToken) return true;
        uint256 minTokens = rate.getTokenAmount(minWei);
        if(capToken - tokenRaised <= minTokens) return true;
        return false;
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
        require(_weiAmount >= minWei);
        require(tokenRaised.add(_tokenAmount) <= capToken);
    }
}

 
contract WhitelistedCrowdsale is Crowdsale {
    using SafeMath for uint256;

     
    Whitelist public whitelist;

     
    function WhitelistedCrowdsale(Whitelist _whitelist) public {
        whitelist = _whitelist;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist.isWhitelisted(_address);
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
        require(whitelist.isWhitelisted(_beneficiary));
    }
}

 
contract ClaimCrowdsale is Crowdsale, Authorizable {
    using SafeMath for uint256;
    
    uint256 divider;
    event ClaimToken(address indexed claimant, address indexed beneficiary, uint256 claimAmount);
     
     
     
    address[] public addressIndices;

     
    mapping(address => uint256) mapAddressToToken;
    
     
    mapping(address => uint256) mapAddressToIndex;
    
      
    uint256 public waitingForClaimTokens;

     
    function ClaimCrowdsale(uint256 _divider) public {
        require(_divider > 0);
        divider = _divider;
        addressIndices.push(address(0));
    }
    
     
    function claim(address _beneficiary) public onlyAuthorized {
       
        require(_beneficiary != address(0));
        require(mapAddressToToken[_beneficiary] > 0);
        
         
        uint indexToBeDeleted = mapAddressToIndex[_beneficiary];
        require(indexToBeDeleted != 0);
        
        uint arrayLength = addressIndices.length;
         
        if (indexToBeDeleted < arrayLength-1) {
             
            addressIndices[indexToBeDeleted] = addressIndices[arrayLength-1];
            mapAddressToIndex[addressIndices[indexToBeDeleted]] = indexToBeDeleted;
        }
          
        addressIndices.length--;
        mapAddressToIndex[_beneficiary] = 0;
        
         
        uint256 _claimAmount = mapAddressToToken[_beneficiary];
        mapAddressToToken[_beneficiary] = 0;
        waitingForClaimTokens = waitingForClaimTokens.sub(_claimAmount);
        emit ClaimToken(msg.sender, _beneficiary, _claimAmount);
        
        _deliverTokens(_beneficiary, _claimAmount);
    }
    
    function checkClaimTokenByIndex(uint index) public view returns (uint256){
        require(index >= 0);
        require(index < addressIndices.length);
        return checkClaimTokenByAddress(addressIndices[index]);
    }
    
    function checkClaimTokenByAddress(address _beneficiary) public view returns (uint256){
        require(_beneficiary != address(0));
        return mapAddressToToken[_beneficiary];
    }
    function countClaimBackers()  public view returns (uint256) {
        return addressIndices.length-1;
    }
    
    function _addToClaimList(address _beneficiary, uint256 _claimAmount) internal {
        require(_beneficiary != address(0));
        require(_claimAmount > 0);
        
        if(mapAddressToToken[_beneficiary] == 0){
            addressIndices.push(_beneficiary);
            mapAddressToIndex[_beneficiary] = addressIndices.length-1;
        }
        waitingForClaimTokens = waitingForClaimTokens.add(_claimAmount);
        mapAddressToToken[_beneficiary] = mapAddressToToken[_beneficiary].add(_claimAmount);
    }

   
     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        
         
         
         
        uint256 tokenSampleAmount = _tokenAmount.div(divider);

        _addToClaimList(_beneficiary, _tokenAmount.sub(tokenSampleAmount));
        _deliverTokens(_beneficiary, tokenSampleAmount);
    }
}

 
 
 
 
 
 
 

 
contract ZminePrivateSale is ClaimCrowdsale
                                , AllowanceCrowdsale
                                , CappedCrowdsale
                                , TimedCrowdsale
                                , WhitelistedCrowdsale {
    using SafeMath for uint256;
    
     
    function ZminePrivateSale(PrivateSaleExchangeRate _rate
                                , Whitelist _whitelist
                                , uint256 _capToken
                                , uint256 _minWei
                                , uint256 _openingTime
                                , uint256 _closingTime
                                , address _wallet
                                , address _tokenWallet
                                , ERC20 _token
    ) public 
        Crowdsale(_rate, _wallet, _token) 
        ClaimCrowdsale(1000000)
        AllowanceCrowdsale(_tokenWallet) 
        CappedCrowdsale(_capToken, _minWei)
        TimedCrowdsale(_openingTime, _closingTime) 
        WhitelistedCrowdsale(_whitelist)
    {
        
        
        
    }

    function calculateTokenAmount(uint256 _weiAmount)  public view returns (uint256) {
        return rate.getTokenAmount(_weiAmount);
    }
    
      
    function remainingTokenForSale() public view returns (uint256) {
        uint256 allowanceTokenLeft = (token.allowance(tokenWallet, this)).sub(waitingForClaimTokens);
        uint256 balanceTokenLeft = (token.balanceOf(tokenWallet)).sub(waitingForClaimTokens);
        if(allowanceTokenLeft < balanceTokenLeft) return allowanceTokenLeft;
        return balanceTokenLeft;
    }
    
      
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
        require(remainingTokenForSale().sub(_tokenAmount) >= 0);
    }
}

 
 
 