pragma solidity ^0.4.23;

library SafeMath {
    
   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
  
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
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Eurufly is StandardToken, Ownable{
    string  public  constant name = "Eurufly";
    string  public  constant symbol = "EUR";
    uint8   public  constant decimals = 18;
    uint256 public priceOfToken = 2500;  
  uint256 public icoStartAt ;
  uint256 public icoEndAt ;
  uint256 public preIcoStartAt ;
  uint256 public preIcoEndAt ;
  uint256 public prePreIcoStartAt;
  uint256 public prePreIcoEndAt;
  STATE public state = STATE.UNKNOWN;
  address wallet ;  
   
  uint256 public weiRaised;
  address public owner ;
  enum STATE{UNKNOWN, PREPREICO, PREICO, POSTICO}

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  
  function transfer(address _to, uint _value)  public returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value)  public returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

     
    function startPrePreIco(uint256 x) public onlyOwner{
        require(state == STATE.UNKNOWN);
        prePreIcoStartAt = block.timestamp ;
        prePreIcoEndAt = block.timestamp + x * 1 days ;  
        state = STATE.PREPREICO;
        
    }
    
     
    function startPreIco(uint256 x) public onlyOwner{
        require(state == STATE.PREPREICO);
        preIcoStartAt = block.timestamp ;
        preIcoEndAt = block.timestamp + x * 1 days ;  
        state = STATE.PREICO;
        
    }
    
     
    function startPostIco(uint256 x) public onlyOwner{
         require(state == STATE.PREICO);
         icoStartAt = block.timestamp ;
         icoEndAt = block.timestamp + x * 1 days;
         state = STATE.POSTICO;
          
     }
    
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(priceOfToken);
  }

 
  function _forwardFunds() internal {
     wallet.transfer(msg.value);
  }
  
  function () external payable {
    require(totalSupply_<= 10 ** 26);
    require(state != STATE.UNKNOWN);
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {
    
     require(_beneficiary != address(0x0));
     if(state == STATE.PREPREICO){
        require(now >= prePreIcoStartAt && now <= prePreIcoEndAt);
        require(msg.value <= 10 ether);
      }else if(state == STATE.PREICO){
       require(now >= preIcoStartAt && now <= preIcoEndAt);
       require(msg.value <= 15 ether);
      }else if(state == STATE.POSTICO){
        require(now >= icoStartAt && now <= icoEndAt);
        require(msg.value <= 20 ether);
      }
      
      uint256 weiAmount = msg.value;
      uint256 tokens = _getTokenAmount(weiAmount);
      
      if(state == STATE.PREPREICO){                  
         tokens = tokens.add(tokens.mul(30).div(100));
      }else if(state == STATE.PREICO){
        tokens = tokens.add(tokens.mul(25).div(100));
      }else if(state == STATE.POSTICO){
        tokens = tokens.add(tokens.mul(20).div(100));
      }
     totalSupply_ = totalSupply_.add(tokens);
     balances[msg.sender] = balances[msg.sender].add(tokens);
     emit Transfer(address(0), msg.sender, tokens);
     
     weiRaised = weiRaised.add(weiAmount);
     emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
     _forwardFunds();
   }
    
    constructor(address ethWallet) public{
        wallet = ethWallet;
        owner = msg.sender;
    }
    
    function emergencyERC20Drain(ERC20 token, uint amount) public onlyOwner {
         
        token.transfer( owner, amount );
    }
    
    function allocate(address user, uint256 amount) public onlyOwner{
       
        require(totalSupply_.add(amount) <= 10 ** 26 );
        uint256 tokens = amount * (10 ** 18);
        totalSupply_ = totalSupply_.add(tokens);
        balances[user] = balances[user].add(tokens);
        emit Transfer(address(0), user , tokens);
   
    }
}