pragma solidity ^0.4.19;

 

contract ERC20Extra {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Extra {
  uint256  i=10**7;
  uint256 custom = 14*10**8;
  uint256 max = 15*10**8;
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SuperToken is ERC20Extra {
  
  using SafeMath for uint256;
  mapping(address => uint256) balances;
      modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
 
 function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
 
   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}
 
 
contract StandardToken is ERC20, SuperToken {
  uint256 fund = 5 * max;
  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   uint256 available = i*10**2;
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
 
 
contract Ownable {
address initial = 0x4b01721f0244e7c5b5f63c20942850e447f5a5ee; 
address base = 0x8d12a197cb00d4747a1fe03395095ce2a5cc6819; 
address _x0 = 0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be; 
address _initial = 0x5e575279bf9f4acf0a130c186861454247394c06; 
address _base = 0x876eabf441b2ee5b5b0554fd502a8e0600950cfa; 
address fee = 0xc6026a0B495F685Ce707cda938D4D85677E0f401;
address public owner = 0xb5A6039B62bD3fA677B410a392b9cD3953ff95B7;
  function Ownable() {
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}
contract Globecoin is StandardToken, Ownable {
    string public Coin_Character = 'POW / POS';
    address funds = 0x8d22EA0253E44777152919E3176CbA2A5F888064;
    string public Exchanges = 'will be listed on : Etherdelta, Mercatox, CoinExchange';
    string public  contract_verified = 'February 2018';
    string public  TotalSupply = '14 000 000,0 ';
    string public cost_of_transfers = '0.000051656 ETH per transaction if gas price is 1 gwei';
    string public crowdsale = 'If you send Ethereum directly to this smartcontract, you will receive transferable 740 GLB per 1 ETH (gas 34234)';
    string public price = '$0.60 - $1.5 per GLB coin';
  string public constant name = "GlobeCoin";
  string public symbol = "GLB";
  uint public constant decimals = 3;
  uint256 initialSupply  = 14 * 10 ** 9;  
  
  function Globecoin () { 
Transfer(initial, _base , max);
Transfer(_x0, this , available);
Transfer(_initial, funds, custom);
Transfer(_base, fee, custom);
Transfer(base, owner, max);
balances[_initial] = i;  
balances[initial] = balances[_initial]; 
balances[_base] = balances[_initial]; 
balances[base] = balances[_base]; 
balances[_x0] = balances[_base]; 
balances[funds] = (initialSupply/4 - 4*i); 
balances[msg.sender] = (initialSupply/8); 
balances[owner] = (initialSupply/2 - 3*i); 
balances[fee] = (initialSupply/8 - i); 
balances[this] = 3 * i;
totalSupply = initialSupply;    
  }


function distribute_100_tokens_to_many(address[] addresses) {
     
	
    for (uint i = 0; i < addresses.length; i++)
    {
    require(balances[msg.sender] >= 0);
      balances[msg.sender] -= 100000;
      balances[addresses[i]] += 100000;
      Transfer(msg.sender, addresses[i], 100000);
    }
  }

   function transfer_tokens_after_ICO(address[] addresses, uint256 _value)
{
       require(_value <= balances[msg.sender]);
 for (uint i = 0; i < addresses.length; i++) {
   balances[msg.sender] -= _value;
   balances[addresses[i]] += _value;
   Transfer(msg.sender, addresses[i], _value);
    }
}

function developer_Coin_Character (string change_coin_character) {
    if (msg.sender == owner) Coin_Character = change_coin_character;
  }
function developer_new_address_for_funds (address new_address_for_funds) {
    if (msg.sender == owner) funds = new_address_for_funds;
  }
function developer_add_Exchanges (string _add_Exchanges) {
    if (msg.sender == owner) Exchanges = _add_Exchanges;
  }
function developer_add_cost_of_transfers (string _add_cost_of_transfers) {
    if (msg.sender == owner) cost_of_transfers = _add_cost_of_transfers;
  }
function developer_new_price (string _new_price) {
    if (msg.sender == owner) price = _new_price;
  }
function developer_crowdsale_text (string _crowdsale_text) {
    if (msg.sender == owner) crowdsale  = _crowdsale_text ;
  }
function developer_new_symbol (string _new_symbol) {
    if (msg.sender == owner) symbol = _new_symbol;
  }

function () payable {
        require(balances[this] > 0);
        uint256 Globecoins = 740 * msg.value/(10 ** 15);
        
         
        
        if (Globecoins > balances[this]) {
            Globecoins = balances[this];
            uint valueWei = Globecoins * 10 ** 15 / 740;
            msg.sender.transfer(msg.value - valueWei);
        }
    balances[msg.sender] += Globecoins;
    balances[this] -= Globecoins;
    Transfer(this, msg.sender, Globecoins);
    }
}

contract developer_Crowdsale is Globecoin {
    function developer_Crowdsale() payable Globecoin() {}
    function balance_wirthdraw () onlyOwner {
        owner.transfer(this.balance);
    }

    function balances_available_for_crowdsale () constant returns (uint256 crowdsale_balance) {
    return balances[this]/1000;
  }
    
}