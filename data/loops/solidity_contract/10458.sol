pragma solidity ^0.4.23;


 
library SafeMath {
  function mul(uint256 a, uint256 b) public pure returns (uint256) {
     if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert( c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) public pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) public pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) public pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) external pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) external pure returns (uint256) {
    return a < b ? a : b;
  }

}

contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner public{
        newOwner = _newOwner;
    }

    function acceptOnwership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner,newOwner);
        owner=newOwner;
        newOwner=address(0);
    }

}

contract ContractReceiver { function tokenFallback(address _from,uint _value,bytes _data)  external;}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC223 is Owned{
     
    using SafeMath for uint256;

     

    string  public name="Littafi Token";
    string  public symbol="LITT";
    uint8   public decimals = 18; 
    uint256 public totalSupply=1000000000;  
    address[] public littHolders;
    uint256 public buyRate=10000;
    bool    public saleIsOn=true;

      
    struct Admin{
        bool isAdmin;
        address beAdmin;
    }

     
    modifier onlyAdmin{
        require(msg.sender == owner || admins[msg.sender].isAdmin);
        _;
    }

     
    mapping(address => Admin) admins;
    
     
    mapping (address => uint256) public balanceOf;
    
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (address => bool) public frozenAccount;
    
     
    event FrozenFunds(address target, bool frozen);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);

     
    event Burn(address indexed from, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event LogContractDestroyed(address indexed contractAddress, bytes30 _extraData);

     
    event LogTokenSale(address indexed _client, uint256 _amountTransacted);

     
    event LogNewPrices(address indexed _admin, uint256 _buyRate);

     
    event LogMintedTokens(address indexed _this, uint256 _amount);

     
    constructor() public {
        totalSupply = totalSupply*10**uint256(decimals);   
        balanceOf[this]=totalSupply;
        Owned(msg.sender);
    }
    
    function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
     require(!frozenAccount[msg.sender] && !frozenAccount[_to]);

    if(isContract(_to)) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);

        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
     }
   }
    
    function transfer(address _to, uint256 _value, bytes _data)public  returns (bool success) {
     require(!frozenAccount[msg.sender] && !frozenAccount[_to]);
     
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }
  
     
     
    function transfer(address _to, uint256 _value)public returns (bool success) {
     require(!frozenAccount[msg.sender] && !frozenAccount[_to]);
      
     bytes memory empty;
     if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
     }
     else {
        return transferToAddress(_to, _value, empty);
     }
   }

     
    function isContract(address _addr) public view returns (bool) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
      }
      return (length>0);
    }

     
    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
     require(balanceOf[msg.sender] > _value); 
     
     balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
     balanceOf[_to] = balanceOf[_to].add(_value);
     emit Transfer(msg.sender, _to, _value, _data);
     emit Transfer(msg.sender, _to, _value);
     return true;
    }
  
     
    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
     require(balanceOf[msg.sender] > _value); 
       
     balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
     balanceOf[_to] = balanceOf[_to].add(_value);
     ContractReceiver receiver = ContractReceiver(_to);
     receiver.tokenFallback(msg.sender, _value, _data);
     emit Transfer(msg.sender, _to, _value);
     emit Transfer(msg.sender, _to, _value, _data);
     return true;
    }

    function transferToOwner(uint256 _amount) public onlyOwner(){
        require(balanceOf[this] > convert(_amount));
        uint256 amount=convert(_amount);
        balanceOf[this]=balanceOf[this].sub(amount);
        balanceOf[owner]=balanceOf[owner].add(amount);
        emit Transfer(this,owner,amount);
    }
     
    function burn(uint256 _value) public onlyOwner {
        require(balanceOf[this] >= convert(_value)); 
        uint256 value=convert(_value);
         
        balanceOf[this]=balanceOf[this].sub(value);     
        totalSupply=totalSupply.sub(value);      
        emit Burn(this, value);
    }

    function freezeAccount(address target, bool freeze) public onlyAdmin {
        require(target != owner);
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function mintToken(uint256 mintedAmount) public onlyOwner {
        uint256 mint=convert(mintedAmount);
        balanceOf[this] =balanceOf[this].add(mint);
        totalSupply =totalSupply.add(mint);

        emit LogMintedTokens(this, mint);
    }

    function setPrices(uint256 newBuyRate) public onlyAdmin{
        buyRate = newBuyRate;
        emit LogNewPrices(msg.sender,buyRate);
    }

    function buy() payable public {
        require(msg.value > 0);
        require(msg.sender != owner && saleIsOn == true);
        uint256 amount=msg.value.mul(buyRate);
        uint256 percentile=amount.add(getEthRate(msg.value).mul(amount).div(100));
        balanceOf[msg.sender]=balanceOf[msg.sender].add(percentile);   
        balanceOf[this]=balanceOf[this].sub(percentile);
        littHolders.push(msg.sender);
        owner.transfer(msg.value);
        emit LogTokenSale(msg.sender,percentile);
    }

    function () public payable {
        buy();
    }

    function destroyContract() public onlyOwner {
       selfdestruct(owner);
       transferOwnership(0x0);
       emit LogContractDestroyed(this, "Contract has been destroyed");
   }
   
    function getEthRate(uint256 _value) private pure returns(uint256){
       require(_value > 0 );
       if(_value < 3 ether)
         return 10;
       if(_value >= 3 ether && _value < 5 ether )
         return 20;
       if(_value >= 5 ether && _value < 24 ether )
         return 30;
       if(_value >= 24 ether )
         return 40;
   }
   
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] =allowance[_from][msg.sender].sub(_value);
        transfer(_to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
   
    function setName(string _name) public onlyOwner() returns (bool success) {
        name=_name;
        return true;
    }
    
    function setSaleStatus(bool _bool) public onlyOwner() returns (bool success){
        saleIsOn=_bool;
        return true;
    }


}