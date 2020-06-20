pragma solidity ^0.4.2;
 
contract Owned {
     
    address public owner;

     
    function Owned() { owner = msg.sender; }

     
    function delegate(address _owner) onlyOwner
    { owner = _owner; }

     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}
 
contract Mortal is Owned {
     
    function kill() onlyOwner
    { suicide(owner); }
}

 
 
contract ERC20 
{
 
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256);

 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract TokenHash is Mortal, ERC20 {
     
    string public name;
    string public symbol;

     
    uint8 public decimals;

     
    mapping(bytes32 => uint256) balances;
    mapping(bytes32 => mapping(bytes32 => uint256)) allowances;
 
     
    function balanceOf(address _owner) constant returns (uint256)
    { return balances[sha3(_owner)]; }

     
    function balanceOf(bytes32 _owner) constant returns (uint256)
    { return balances[_owner]; }

     
    function allowance(address _owner, address _spender) constant returns (uint256)
    { return allowances[sha3(_owner)][sha3(_spender)]; }

     
    function allowance(bytes32 _owner, bytes32 _spender) constant returns (uint256)
    { return allowances[_owner][_spender]; }

     
    function TokenHash(string _name, string _symbol, uint8 _decimals, uint256 _count) {
        name        = _name;
        symbol      = _symbol;
        decimals    = _decimals;
        totalSupply = _count;
        balances[sha3(msg.sender)] = _count;
    }
 
     
    function transfer(address _to, uint256 _value) returns (bool) {
        var sender = sha3(msg.sender);

        if (balances[sender] >= _value) {
            balances[sender]    -= _value;
            balances[sha3(_to)] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

     
    function transfer(bytes32 _to, uint256 _value) returns (bool) {
        var sender = sha3(msg.sender);

        if (balances[sender] >= _value) {
            balances[sender] -= _value;
            balances[_to]    += _value;
            TransferHash(sender, _to, _value);
            return true;
        }
        return false;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var to    = sha3(_to);
        var from  = sha3(_from);
        var sender= sha3(msg.sender);
        var avail = allowances[from][sender]
                  > balances[from] ? balances[from]
                                   : allowances[from][sender];
        if (avail >= _value) {
            allowances[from][sender] -= _value;
            balances[from] -= _value;
            balances[to]   += _value;
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

     
    function transferFrom(bytes32 _from, bytes32 _to, uint256 _value) returns (bool) {
        var sender= sha3(msg.sender);
        var avail = allowances[_from][sender]
                  > balances[_from] ? balances[_from]
                                    : allowances[_from][sender];
        if (avail >= _value) {
            allowances[_from][sender] -= _value;
            balances[_from] -= _value;
            balances[_to]   += _value;
            TransferHash(_from, _to, _value);
            return true;
        }
        return false;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {
        allowances[sha3(msg.sender)][sha3(_spender)] += _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
 
     
    function approve(bytes32 _spender, uint256 _value) returns (bool) {
        allowances[sha3(msg.sender)][_spender] += _value;
        ApprovalHash(sha3(msg.sender), _spender, _value);
        return true;
    }

     
    function unapprove(address _spender)
    { allowances[sha3(msg.sender)][sha3(_spender)] = 0; }
 
     
    function unapprove(bytes32 _spender)
    { allowances[sha3(msg.sender)][_spender] = 0; }
 
     
    event TransferHash(bytes32 indexed _from,  bytes32 indexed _to,      uint256 _value);
    event ApprovalHash(bytes32 indexed _owner, bytes32 indexed _spender, uint256 _value);
}


 
 
 
 

contract Registrar {
	event Changed(string indexed name);

	function owner(string _name) constant returns (address o_owner);
	function addr(string _name) constant returns (address o_address);
	function subRegistrar(string _name) constant returns (address o_subRegistrar);
	function content(string _name) constant returns (bytes32 o_content);
}

 
 
 
 

contract AiraRegistrarService is Registrar, Mortal {
	struct Record {
		address addr;
		address subRegistrar;
		bytes32 content;
	}
	
    function owner(string _name) constant returns (address o_owner)
    { return 0; }

	function disown(string _name) onlyOwner {
		delete m_toRecord[_name];
		Changed(_name);
	}

	function setAddr(string _name, address _a) onlyOwner {
		m_toRecord[_name].addr = _a;
		Changed(_name);
	}
	function setSubRegistrar(string _name, address _registrar) onlyOwner {
		m_toRecord[_name].subRegistrar = _registrar;
		Changed(_name);
	}
	function setContent(string _name, bytes32 _content) onlyOwner {
		m_toRecord[_name].content = _content;
		Changed(_name);
	}
	function record(string _name) constant returns (address o_addr, address o_subRegistrar, bytes32 o_content) {
		o_addr = m_toRecord[_name].addr;
		o_subRegistrar = m_toRecord[_name].subRegistrar;
		o_content = m_toRecord[_name].content;
	}
	function addr(string _name) constant returns (address) { return m_toRecord[_name].addr; }
	function subRegistrar(string _name) constant returns (address) { return m_toRecord[_name].subRegistrar; }
	function content(string _name) constant returns (bytes32) { return m_toRecord[_name].content; }

	mapping (string => Record) m_toRecord;
}

contract AiraEtherFunds is TokenHash {
    function AiraEtherFunds(address _bot_reg, string _name, string _symbol)
            TokenHash(_name, _symbol, 18, 0) {
        reg = AiraRegistrarService(_bot_reg);
    }

     
    event ActivationRequest(address indexed ident, bytes32 indexed code);

     
    uint256 public limit;
    
    function setLimit(uint256 _limit) onlyOwner
    { limit = _limit; }

     
    uint256 public fee;
    
    function setFee(uint256 _fee) onlyOwner
    { fee = _fee; }

     
    function activate(string _code) payable {
        var value = msg.value;
 
         
        if (fee > 0) {
            if (value < fee) throw;
            balances[sha3(owner)] += fee;
            value                 -= fee;
        }

         
        if (limit > 0 && value > limit) {
            var refund = value - limit;
            if (!msg.sender.send(refund)) throw;
            value = limit;
        }

         
        balances[sha3(msg.sender)] += value;
        totalSupply                += value;

         
        ActivationRequest(msg.sender, stringToBytes32(_code));
    }

     
    function stringToBytes32(string memory source) constant returns (bytes32 result)
    { assembly { result := mload(add(source, 32)) } }

     
    function refill(address _dest) payable returns (bool)
    { return refill(sha3(_dest)); }

     
    function () payable
    { refill(msg.sender); }

     
    function refill(bytes32 _dest) payable returns (bool) {
         
        if (balances[_dest] + msg.value > limit) throw;

         
        balances[_dest] += msg.value;
        totalSupply     += msg.value;
        return true;
    }

     
    function sendFrom(bytes32 _from, address _to, uint256 _value) {
        var sender = sha3(msg.sender);
        var avail = allowances[_from][sender]
                  > balances[_from] ? balances[_from]
                                    : allowances[_from][sender];
        if (avail >= _value) {
            allowances[_from][sender] -= _value;
            balances[_from]           -= _value;
            totalSupply               -= _value;
            if (!_to.send(_value)) throw;
        }
    }

    AiraRegistrarService public reg;
    modifier onlySecure { if (msg.sender != reg.addr("AiraSecure")) throw; _; }

     
    function secureApprove(bytes32 _client, uint256 _value) onlySecure {
        var ethBot = reg.addr("AiraEth");
        if (ethBot != 0) {
            allowances[_client][sha3(ethBot)] += _value;
            ApprovalHash(_client, sha3(ethBot), _value);
        }
    }

     
    function secureUnapprove(bytes32 _client) onlySecure {
        var ethBot = reg.addr("AiraEth");
        if (ethBot != 0)
            allowances[_client][sha3(ethBot)] = 0;
    }

     
    function kill() onlyOwner { throw; }
}