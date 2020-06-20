contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
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

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 
contract Airdrop {
    
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    
     
    ERC20 public token;

    address owner = 0x0;

     
     
     
     
    uint256 public rate;
    
    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

   
  event TokenDropped(
    address indexed sender,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(ERC20 _token) public
  {
    require(_token != address(0));

    owner = msg.sender;
    token = _token;
  }

   
   
   

   
  function () external payable {
    sendAirDrops(msg.sender);
  }

     
    function sendAirDrops(address _beneficiary) public payable
    {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);
        
         
        uint256 tokens = 50 * (10 ** 6);
        
        _processAirdrop(_beneficiary, tokens);
        
        emit TokenDropped(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );
    }
  
    function collect(uint256 _weiAmount) isOwner public {
        address thisAddress = this;
        owner.transfer(thisAddress.balance);
    }

   
   
   

   
  function _preValidatePurchase( address _beneficiary, uint256 _weiAmount) internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount >= 1 * (10 ** 15));
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processAirdrop(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

}