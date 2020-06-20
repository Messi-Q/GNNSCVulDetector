pragma solidity ^0.4.18;
 
 
 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}




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



contract NVTReceiver {
    function NVTFallback(address _from, uint _value, uint _code);
}

contract BasicToken {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
   
  function transfer(address _to, uint _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
     
    if(!isContract(_to)){
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;}
    else{
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    NVTReceiver receiver = NVTReceiver(_to);
    receiver.NVTFallback(msg.sender, _value, 0);
    Transfer(msg.sender, _to, _value);
        return true;
    }
    
  }
  function transfer(address _to, uint _value, uint _code) public returns (bool) {
      require(isContract(_to));
      require(_value <= balances[msg.sender]);
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
      balances[_to] = balanceOf(_to).add(_value);
      NVTReceiver receiver = NVTReceiver(_to);
      receiver.NVTFallback(msg.sender, _value, _code);
      Transfer(msg.sender, _to, _value);
    
      return true;
    
    }
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }


function isContract(address _addr) private returns (bool is_contract) {
    uint length;
    assembly {
         
        length := extcodesize(_addr)
    }
    return (length>0);
  }


   
   
  function transferToContract(address _to, uint _value, uint _code) public returns (bool success) {
    require(isContract(_to));
    require(_value <= balances[msg.sender]);
  
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    NVTReceiver receiver = NVTReceiver(_to);
    receiver.NVTFallback(msg.sender, _value, _code);
    Transfer(msg.sender, _to, _value);
    
    return true;
  }
}






contract NVT is BasicToken, Ownable {

  string public constant name = "NiceVotingToken";
  string public constant symbol = "NVT";
  uint8 public constant decimals = 2;

  uint256 public constant TOTAL_SUPPLY = 100 * 10 ** 10;  
  uint256 public RELEASE_TIME ;
  uint256 public TOKEN_FOR_SALE = 40 * 10 ** 10;
  uint256 public TOKEN_FOR_TEAM = 10 * 10 ** 10;
  uint256 public TOKEN_FOR_COMUNITY = 20 * 10 ** 10;
  uint256 public TOKEN_FOR_INVESTER = 25 * 10 ** 10;


  uint256 public price = 10 ** 12;  
  bool public halted = false;

   
  function NVT() public {
    totalSupply_ = 5 * 10 ** 10;  
    balances[msg.sender] = 5 * 10 ** 10;
    Transfer(0x0, msg.sender, 5 * 10 ** 10);
    RELEASE_TIME = now;
  }

   
   
  function setPrice(uint _newprice) onlyOwner{
    require(_newprice > price);
    price=_newprice; 
  }

   
  function () public payable{
    require(halted == false);
    uint amout = msg.value.div(price);
    require(amout <= TOKEN_FOR_SALE);
    TOKEN_FOR_SALE = TOKEN_FOR_SALE.sub(amout);
    balances[msg.sender] = balanceOf(msg.sender).add(amout);
    totalSupply_=totalSupply_.add(amout);
    Transfer(0x0, msg.sender, amout);
  }

  function getTokenForTeam (address _to, uint _amout) onlyOwner returns(bool){
    TOKEN_FOR_TEAM = TOKEN_FOR_TEAM.sub(_amout);
    totalSupply_=totalSupply_.add(_amout);
    balances[_to] = balanceOf(_to).add(_amout);
    Transfer(0x0, _to, _amout);
    return true;
  }


  function getTokenForInvester (address _to, uint _amout) onlyOwner returns(bool){
    TOKEN_FOR_INVESTER = TOKEN_FOR_INVESTER.sub(_amout);
    totalSupply_=totalSupply_.add(_amout);
    balances[_to] = balanceOf(_to).add(_amout);
    Transfer(0x0, _to, _amout);
    return true;
  }


  function getTokenForCommunity (address _to, uint _amout) onlyOwner{
    require(_amout <= TOKEN_FOR_COMUNITY);
    TOKEN_FOR_COMUNITY = TOKEN_FOR_COMUNITY.sub(_amout);
    totalSupply_=totalSupply_.add(_amout);
    balances[_to] = balanceOf(_to).add(_amout);
    Transfer(0x0, _to, _amout);
  }
  

  function getFunding (address _to, uint _amout) onlyOwner{
    _to.transfer(_amout);
  }


  function getAllFunding() onlyOwner{
    owner.transfer(this.balance);
  }


   
  function halt() onlyOwner{
    halted = true;
  }
  function unhalt() onlyOwner{
    halted = false;
  }



}