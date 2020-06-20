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
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
contract XGETokensale is Pausable, Destructible {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    address public wallet;    

     
    uint256 public weiRaised;

     
    uint256 public USDXGE = 1995;

     
    uint256 public USDETH = 400 * 10**21;

     
    uint256 public MIN_AMOUNT = 100 * 10**18;

     
    mapping(address => uint8) public whitelist;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event WhitelistAdd(address indexed beneficiary);
    
     
    event WhitelistRemove(address indexed beneficiary);

     
    event USDETHRateUpdate(uint256 oldRate, uint256 newRate);
    
     
    event USDXGERateUpdate(uint256 oldRate, uint256 newRate);
  
     
    function XGETokensale(address _wallet, ERC20 _token) public
    {
        require(_wallet != address(0));
        require(_token != address(0));

        owner = msg.sender;
        wallet = _wallet;
        token = _token;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function updateUSDETH(uint256 rate) public onlyOwner {
        require(rate > 0);
        USDETHRateUpdate(USDETH, rate * 10**18);
        USDETH = rate * 10**18;
    }

     
    function updateUSDXGE(uint256 rate) public onlyOwner {
        require(rate > 0);
        USDETHRateUpdate(USDXGE, rate);
        USDXGE = rate;
    }

     
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != address(0));
        require(whitelist[_beneficiary] != 0);
        require(msg.value != 0);

        uint256 weiAmount = msg.value;
        uint256 rate = USDETH.div(USDXGE);

        uint256 tokens = weiAmount.mul(rate).div(10**18);

         
        if (tokens < MIN_AMOUNT) {
            revert();
        }

        weiRaised = weiRaised.add(weiAmount);
        token.transferFrom(owner, _beneficiary, tokens);
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        wallet.transfer(weiAmount);
    }

     
    function addToWhitelist(address buyer) public onlyOwner {
        require(buyer != address(0));
        whitelist[buyer] = 1;
        WhitelistAdd(buyer);
    }

     
    function removeFromWhitelist(address buyer) public onlyOwner {
        require(buyer != address(0));
        delete whitelist[buyer];
        WhitelistRemove(buyer);
    }
}