pragma solidity ^0.4.20;



 



 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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



 



 

contract RxEALTokenContract is StandardToken {

   

   
  string public constant name = "RxEAL";
  string public constant symbol = "RXL";
  uint256 public constant decimals = 18;

   

   
   
  uint256 public constant INITIAL_SUPPLY = 96000000 * (10 ** decimals);
   
  address public vault = this;
   
  address public salesAgent;
   
  mapping (address => bool) public owners;

   

   
  event OwnershipGranted(address indexed _owner, address indexed revoked_owner);
  event OwnershipRevoked(address indexed _owner, address indexed granted_owner);
  event SalesAgentPermissionsTransferred(address indexed previousSalesAgent, address indexed newSalesAgent);
  event SalesAgentRemoved(address indexed currentSalesAgent);
  event Burn(uint256 value);

   

   
  modifier onlyOwner() {
    require(owners[msg.sender] == true);
    _;
  }

   

   
  function RxEALTokenContract() {
    owners[msg.sender] = true;
    totalSupply = INITIAL_SUPPLY;
    balances[vault] = totalSupply;
  }

   
  function grantOwnership(address _owner) onlyOwner public {
    require(_owner != address(0));
    owners[_owner] = true;
    OwnershipGranted(msg.sender, _owner);
  }

   
  function revokeOwnership(address _owner) onlyOwner public {
    require(_owner != msg.sender);
    owners[_owner] = false;
    OwnershipRevoked(msg.sender, _owner);
  }

   
  function transferSalesAgentPermissions(address _salesAgent) onlyOwner public {
    SalesAgentPermissionsTransferred(salesAgent, _salesAgent);
    salesAgent = _salesAgent;
  }

   
  function removeSalesAgent() onlyOwner public {
    SalesAgentRemoved(salesAgent);
    salesAgent = address(0);
  }

   
  function transferTokensFromVault(address _from, address _to, uint256 _amount) public {
    require(salesAgent == msg.sender);
    balances[vault] = balances[vault].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(_from, _to, _amount);
  }

   
  function burn(uint256 _value) onlyOwner public {
    require(_value > 0);
    balances[vault] = balances[vault].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_value);
  }

}



 



contract RxEALSaleContractExtended {
   
  using SafeMath for uint256;

   

   
  RxEALTokenContract public token;

   
  uint256 public startTime = 1520856000;
  uint256 public endTime = 1526040000;

   
  address public wallet1 = 0x56E4e5d451dF045827e214FE10bBF99D730d9683;
  address public wallet2 = 0x8C0988711E60CfF153359Ab6CFC8d45565C6ce79;
  address public wallet3 = 0x0EdF5c34ddE2573f162CcfEede99EeC6aCF1c2CB;
  address public wallet4 = 0xcBdC5eE000f77f3bCc0eFeF0dc47d38911CBD45B;

   
   

   
  uint256 public tier_rate_1 = 1800;
  uint256 public tier_cap_1 = 4584000;
   
  uint256 public tier_rate_2 = 1440;
  uint256 public tier_cap_2 = 14400000;
   
  uint256 public tier_rate_3 = 1320;
  uint256 public tier_cap_3 = 14400000;
   
  uint256 public tier_rate_4 = 1200;
  uint256 public tier_cap_4 = 14400000;

  uint256 public hard_cap;

   
  uint8 public current_tier = 1;

   
  uint256 public weiRaised;

   
  uint256 public soldTokens;
  uint256 public current_tier_sold_tokens;

   

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 tokens);

   

   
  function RxEALSaleContractExtended() {
    token = RxEALTokenContract(0xD6682Db9106e0cfB530B697cA0EcDC8F5597CD15);

    tier_cap_1 = tier_cap_1 * (10 ** token.decimals());
    tier_cap_2 = tier_cap_2 * (10 ** token.decimals());
    tier_cap_3 = tier_cap_3 * (10 ** token.decimals());
    tier_cap_4 = tier_cap_4 * (10 ** token.decimals());

    hard_cap = tier_cap_1 + tier_cap_2 + tier_cap_3 + tier_cap_4;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function tier_action(
    uint8 tier,
    uint256 left_wei,
    uint256 tokens_amount,
    uint8 next_tier,
    uint256 tier_rate,
    uint256 tier_cap
  ) internal returns (uint256, uint256) {
    if (current_tier == tier) {
       
      uint256 tokens_can_be_sold;
       
      uint256 tokens_to_be_sold = left_wei.mul(tier_rate);
       
      uint256 new_tier_sold_tokens = current_tier_sold_tokens.add(tokens_to_be_sold);

      if (new_tier_sold_tokens >= tier_cap) {
         

         
        uint256 spare_tokens = new_tier_sold_tokens.sub(tier_cap);
         
        tokens_can_be_sold = tokens_to_be_sold.sub(spare_tokens);

         
        current_tier_sold_tokens = 0;
         
        current_tier = next_tier;
      } else {
         

         
        tokens_can_be_sold = tokens_to_be_sold;
         
        current_tier_sold_tokens = new_tier_sold_tokens;
      }

       
      uint256 wei_amount = tokens_can_be_sold.div(tier_rate);
       
      left_wei = left_wei.sub(wei_amount);
       
      tokens_amount = tokens_amount.add(tokens_can_be_sold);
    }

    return (left_wei, tokens_amount);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(validPurchase());

    uint256 left_wei = msg.value;
    uint256 tokens_amount;

    (left_wei, tokens_amount) = tier_action(1, left_wei, tokens_amount, 2, tier_rate_1, tier_cap_1);
    (left_wei, tokens_amount) = tier_action(2, left_wei, tokens_amount, 3, tier_rate_2, tier_cap_2);
    (left_wei, tokens_amount) = tier_action(3, left_wei, tokens_amount, 4, tier_rate_3, tier_cap_3);
    (left_wei, tokens_amount) = tier_action(4, left_wei, tokens_amount, 4, tier_rate_4, tier_cap_4);

     
    uint256 purchase_wei_amount = msg.value.sub(left_wei);
    weiRaised = weiRaised.add(purchase_wei_amount);
    soldTokens = soldTokens.add(tokens_amount);

     
    if (left_wei > 0) {
      beneficiary.transfer(left_wei);
    }

     
    token.transferTokensFromVault(msg.sender, beneficiary, tokens_amount);
    TokenPurchase(msg.sender, beneficiary, purchase_wei_amount, tokens_amount);

    forwardFunds(purchase_wei_amount);
  }

   
  function forwardFunds(uint256 weiAmount) internal {
    uint256 value = weiAmount.div(4);

     
    if (value.mul(4) != weiAmount) {
      wallet1.transfer(weiAmount);
    } else {
      wallet1.transfer(value);
      wallet2.transfer(value);
      wallet3.transfer(value);
      wallet4.transfer(value);
    }
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = soldTokens < hard_cap;
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && withinCap;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime || soldTokens >= hard_cap;
  }
}