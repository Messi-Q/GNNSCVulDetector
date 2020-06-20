pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}


 
contract FundableToken is BasicToken {
     
    mapping(address => uint) public funds;

     
    uint public totalFunds;

    function FundableToken() {}
}


 
contract TransformAgent {
     
    uint256 public originalSupply;
     
    uint256 public originalFunds;

     
    function isTransformAgent() public constant returns (bool) {
        return true;
    }

    function transformFrom(address _from, uint256 _tokens, uint256 _funds) public;

}


 
contract TransformableToken is FundableToken, Ownable {

     
    TransformAgent public transformAgent;

     
    uint256 public totalTransformedTokens;

     
    enum TransformState {Unknown, NotAllowed, WaitingForAgent, ReadyToTransform, Transforming}

     
    event Transform(address indexed _from, address indexed _to, uint256 _tokens, uint256 _funds);

     
    event TransformAgentSet(address agent);

     
    function transform() public {

        TransformState state = getTransformState();
        require(state == TransformState.ReadyToTransform || state == TransformState.Transforming);

        uint tokens = balances[msg.sender];
        uint investments = funds[msg.sender];
        require(tokens > 0);  

        balances[msg.sender] = 0;
        funds[msg.sender] = 0;

         
        totalSupply = totalSupply.sub(tokens);
        totalFunds = totalFunds.sub(investments);

        totalTransformedTokens = totalTransformedTokens.add(tokens);

         
        transformAgent.transformFrom(msg.sender, tokens, investments);
        Transform(msg.sender, transformAgent, tokens, investments);

         
        if(totalSupply == 0)
            selfdestruct(owner);
    }

     
    function setTransformAgent(address agent) onlyOwner external {
        require(agent != 0x0);
         
        require(getTransformState() != TransformState.Transforming);

        transformAgent = TransformAgent(agent);

         
        require(transformAgent.isTransformAgent());
         
        require(transformAgent.originalSupply() == totalSupply);
        require(transformAgent.originalFunds() == totalFunds);

        TransformAgentSet(transformAgent);
    }

     
    function getTransformState() public constant returns(TransformState) {
        if(address(transformAgent) == 0x00) return TransformState.WaitingForAgent;
        else if(totalTransformedTokens == 0) return TransformState.ReadyToTransform;
        else return TransformState.Transforming;
    }
}


 
contract MintableToken is BasicToken {
     

    function mint(address _to, uint _amount) internal {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
         
        Transfer(0x0, _to, _amount);
    }
}


 
 
contract UbermenschPrefundToken is MintableToken, TransformableToken {
    string constant public name = "Ubermensch Prefund";
    string constant public symbol = "UMP";
    uint constant public decimals = 8;

     
    uint constant public TOKEN_PRICE = 0.0025 * 1 ether;
     
    uint constant public TOKEN_CAP = 20000000 * (10 ** decimals);

    uint public investorCount;
    address public multisigWallet;
    bool public stopped;

     
    event Invested(address indexed investor, uint weiAmount, uint tokenAmount);

    function UbermenschPrefundToken(address multisig){
         
         
         
         
         
        transferOwnership(multisig);
        multisigWallet = multisig;
    }

    modifier onlyActive(){
        require(!stopped);
         
        require(getTransformState() == TransformState.WaitingForAgent);
        _;
    }

     
    function getCurrentBonus() public constant returns (uint){
        if(totalSupply < 7000000 * (10 ** decimals))
            return 180;
        if(totalSupply < 14000000 * (10 ** decimals))
            return 155;
        return 140;
    }

     
     
    function invest(address to) onlyActive public payable {
        uint amount = msg.value;
         
        uint tokenAmount = getCurrentBonus().mul(amount).mul(10 ** decimals / 100).div(TOKEN_PRICE);

        require(tokenAmount >= 0);

        if(funds[to] == 0) {
             
            ++investorCount;
        }

         
        funds[to] = funds[to].add(amount);
        totalFunds = totalFunds.add(amount);

         
        mint(to, tokenAmount);

         
         
         
        require(totalSupply <= TOKEN_CAP);

         
        multisigWallet.transfer(amount);

         
        Invested(to, amount, tokenAmount);
    }

    function buy() public payable {
        invest(msg.sender);
    }

    function transfer(address _to, uint _value){
        throw;  
    }

     
    function stop() onlyOwner {
        stopped = true;
    }

     
    function () payable{
        buy();
    }
}