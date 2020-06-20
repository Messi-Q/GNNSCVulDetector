pragma solidity ^0.4.23;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

    interface ERC20 {
        function transfer(address _beneficiary, uint256 _tokenAmount) external returns (bool);
        function transferFromICO(address _to, uint256 _value) external returns(bool);
    }

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract MainSale is Ownable {

    using SafeMath for uint;

    ERC20 public token;
    
    address reserve = 0x611200beabeac749071b30db84d17ec205654463;
    address promouters = 0x2632d043ac8bbbad07c7dabd326ade3ca4f6b53e;
    address bounty = 0xff5a1984fade92bfb0e5fd7986186d432545b834;

    uint256 public constant decimals = 18;
    uint256 constant dec = 10**decimals;

    mapping(address=>bool) whitelist;

    uint256 public startCloseSale = now;  
    uint256 public endCloseSale = 1532987999;  

    uint256 public startStage1 = 1532988001;  
    uint256 public endStage1 = 1533074399;  

    uint256 public startStage2 = 1533074400;  
    uint256 public endStage2 = 1533679199;  

    uint256 public startStage3 = 1533679200;  
    uint256 public endStage3 = 1535752799;  

    uint256 public buyPrice = 920000000000000000;  
    
    uint256 public ethUSD;

    uint256 public weisRaised = 0;

    string public stageNow = "NoSale";
    
    event Authorized(address wlCandidate, uint timestamp);
    event Revoked(address wlCandidate, uint timestamp);

    constructor() public {}

    function setToken (ERC20 _token) public onlyOwner {
        token = _token;
    }
    
     
    function authorize(address wlCandidate) public onlyOwner  {
        require(wlCandidate != address(0x0));
        require(!isWhitelisted(wlCandidate));
        whitelist[wlCandidate] = true;
        emit Authorized(wlCandidate, now);
    }

    function revoke(address wlCandidate) public  onlyOwner {
        whitelist[wlCandidate] = false;
        emit Revoked(wlCandidate, now);
    }

    function isWhitelisted(address wlCandidate) public view returns(bool) {
        return whitelist[wlCandidate];
    }
    
     

    function setStartCloseSale(uint256 newStartSale) public onlyOwner {
        startCloseSale = newStartSale;
    }

    function setEndCloseSale(uint256 newEndSale) public onlyOwner{
        endCloseSale = newEndSale;
    }

    function setStartStage1(uint256 newsetStage2) public onlyOwner{
        startStage1 = newsetStage2;
    }

    function setEndStage1(uint256 newsetStage3) public onlyOwner{
        endStage1 = newsetStage3;
    }

    function setStartStage2(uint256 newsetStage4) public onlyOwner{
        startStage2 = newsetStage4;
    }

    function setEndStage2(uint256 newsetStage5) public onlyOwner{
        endStage2 = newsetStage5;
    }

    function setStartStage3(uint256 newsetStage5) public onlyOwner{
        startStage3 = newsetStage5;
    }

    function setEndStage3(uint256 newsetStage5) public onlyOwner{
        endStage3 = newsetStage5;
    }

    function setPrices(uint256 newPrice) public onlyOwner {
        buyPrice = newPrice;
    }
    
    function setETHUSD(uint256 _ethUSD) public onlyOwner { 
        ethUSD = _ethUSD;
    
    
    }
    
     
    function ()  public payable {
        
        require(msg.value >= (1*1e18/ethUSD*100));

        if (now >= startCloseSale || now <= endCloseSale) {
            require(isWhitelisted(msg.sender));
            closeSale(msg.sender, msg.value);
            stageNow = "Close Sale for Whitelist's members";
            
        } else if (now >= startStage1 || now <= endStage1) {
            sale1(msg.sender, msg.value);
            stageNow = "Stage 1";

        } else if (now >= startStage2 || now <= endStage2) {
            sale2(msg.sender, msg.value);
             stageNow = "Stage 2";

        } else if (now >= startStage3 || now <= endStage3) {
            sale3(msg.sender, msg.value);
             stageNow = "Stage 3";

        } else {
            stageNow = "No Sale";
            revert();
        } 
    }
    
     
    function closeSale(address _investor, uint256 _value) internal {

        uint256 tokens = _value.mul(1e18).div(buyPrice);  
        uint256 bonusTokens = tokens.mul(30).div(100);  
        tokens = tokens.add(bonusTokens); 
        token.transferFromICO(_investor, tokens);
        weisRaised = weisRaised.add(msg.value);

        uint256 tokensReserve = tokens.mul(15).div(68);  
        token.transferFromICO(reserve, tokensReserve);

        uint256 tokensBoynty = tokens.div(34);  
        token.transferFromICO(bounty, tokensBoynty);

        uint256 tokensPromo = tokens.mul(15).div(68);  
        token.transferFromICO(promouters, tokensPromo);
    }
    
     
    function sale1(address _investor, uint256 _value) internal {

        uint256 tokens = _value.mul(1e18).div(buyPrice);  

        uint256 bonusTokens = tokens.mul(10).div(100);  
        tokens = tokens.add(bonusTokens);  

        token.transferFromICO(_investor, tokens);

        uint256 tokensReserve = tokens.mul(5).div(22);  
        token.transferFromICO(reserve, tokensReserve);

        uint256 tokensBoynty = tokens.mul(2).div(33);  
        token.transferFromICO(bounty, tokensBoynty);

        uint256 tokensPromo = tokens.mul(5).div(22);  
        token.transferFromICO(promouters, tokensPromo);

        weisRaised = weisRaised.add(msg.value);
    }
    
     
    function sale2(address _investor, uint256 _value) internal {

        uint256 tokens = _value.mul(1e18).div(buyPrice);  

        uint256 bonusTokens = tokens.mul(5).div(100);  
        tokens = tokens.add(bonusTokens);

        token.transferFromICO(_investor, tokens);

        uint256 tokensReserve = tokens.mul(15).div(64);  
        token.transferFromICO(reserve, tokensReserve);

        uint256 tokensBoynty = tokens.mul(3).div(32);  
        token.transferFromICO(bounty, tokensBoynty);

        uint256 tokensPromo = tokens.mul(15).div(64);  
        token.transferFromICO(promouters, tokensPromo);

        weisRaised = weisRaised.add(msg.value);
    }

     
    function sale3(address _investor, uint256 _value) internal {

        uint256 tokens = _value.mul(1e18).div(buyPrice);  
        token.transferFromICO(_investor, tokens);

        uint256 tokensReserve = tokens.mul(15).div(62);  
        token.transferFromICO(reserve, tokensReserve);

        uint256 tokensBoynty = tokens.mul(4).div(31);  
        token.transferFromICO(bounty, tokensBoynty);

        uint256 tokensPromo = tokens.mul(15).div(62);  
        token.transferFromICO(promouters, tokensPromo);

        weisRaised = weisRaised.add(msg.value);
    }

     
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
        _to.transfer(amount);
    }
}