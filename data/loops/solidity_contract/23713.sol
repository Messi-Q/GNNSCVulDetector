pragma solidity ^0.4.15;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
  function Ownable() public { owner = msg.sender; }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {owner = newOwner;}
}

contract ERC20Interface {

  function totalSupply() public constant returns (uint256);

  function balanceOf(address _owner) public constant returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);

  function allowance(address _owner, address _spender) public constant returns (uint256);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

 }

contract SmartOToken is Ownable, ERC20Interface {

  using SafeMath for uint256;

   
  string public constant name = "STO";
  string public constant symbol = "STO";
  uint public constant decimals = 18;
  uint256 public constant initialSupply = 12000000000 * 1 ether;
  uint256 public totalSupply;

   
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

   
  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);

   
  function SmartOToken() public {
      balances[msg.sender] = initialSupply;               
      totalSupply = initialSupply;                         
  }


   

  function totalSupply() public constant returns (uint256) { return totalSupply; }

  function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }

   
  function _transfer(address _from, address _to, uint _amount) internal {
      require (_to != 0x0);                                
      require (balances[_from] >= _amount);                 
      balances[_from] = balances[_from].sub(_amount);
      balances[_to] = balances[_to].add(_amount);
      Transfer(_from, _to, _amount);

  }

  function transfer(address _to, uint256 _amount) public returns (bool) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require (_value <= allowed[_from][msg.sender]);      
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _amount) public returns (bool) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return allowed[_owner][_spender];
  }

}


contract Crowdsale is Ownable {

  using SafeMath for uint256;

   
  SmartOToken public token;

   
  bool public saleIsActive;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


   

  function Crowdsale(uint256 _initialRate, address _targetWallet) public {

     
    require(_initialRate > 0);
    require(_targetWallet != 0x0);

     
    token = new SmartOToken();
    rate = _initialRate;
    wallet = _targetWallet;
    saleIsActive = true;

  }

  function close() public onlyOwner {
    selfdestruct(owner);
  }

   
  function transferToAddress(address _targetWallet, uint256 _tokenAmount) public onlyOwner {
    token.transfer(_targetWallet, _tokenAmount * 1 ether);
  }


   
  function enableSale() public onlyOwner {
    saleIsActive = true;
  }

  function disableSale() public onlyOwner {
    saleIsActive = false;
  }

  function setRate(uint256 _newRate) public onlyOwner {
    rate = _newRate;
  }


   

  function () public payable {

    require(msg.sender != 0x0);
    require(saleIsActive);
    require(msg.value >= 0.1 * 1 ether);

    uint256 weiAmount = msg.value;

     
    weiRaised = weiRaised.add(weiAmount);

     
    uint256 tokenAmount = weiAmount.mul(rate);

     
    wallet.transfer(weiAmount);

     
    token.transfer(msg.sender, tokenAmount);
    TokenPurchase(msg.sender, wallet, weiAmount, tokenAmount);

  }



}