pragma solidity ^0.4.19;

 
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

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract BitGuildToken {
     
    string public name = "BitGuild PLAT";
    string public symbol = "PLAT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * 10 ** uint256(decimals);  

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function BitGuildToken() public {
        balanceOf[msg.sender] = totalSupply;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}

 
contract BitGuildWhitelist {

  address admin;

  mapping (address => bool) public whitelist;
  uint256 public totalWhitelisted = 0;

  event AddressWhitelisted(address indexed user, bool whitelisted);

  function BitGuildWhitelist() public {
    admin = msg.sender;
  }

   
  function () external payable {
    revert();
  }

   
  function whitelistAddress(address[] _users, bool _whitelisted) public {
    require(msg.sender == admin);
    for (uint i = 0; i < _users.length; i++) {
      if (whitelist[_users[i]] == _whitelisted) continue;
      if (_whitelisted) {
        totalWhitelisted++;
      } else {
        if (totalWhitelisted > 0) {
          totalWhitelisted--;
        }
      }
      AddressWhitelisted(_users[i], _whitelisted);
      whitelist[_users[i]] = _whitelisted;
    }
  }
}

 
contract BitGuildCrowdsale {
  using SafeMath for uint256;

   
  BitGuildToken public token;

   
  BitGuildWhitelist public whitelist;

   
  uint256 public startTime;
  uint256 public endTime;

   
  uint256 public cap = 14062.5 ether;

   
  address public wallet;

   
  uint256 public rate = 80000;

   
  uint256 public minContribution = 0.5 ether;
  uint256 public maxContribution = 1500 ether;

   
  uint256 public weiRaised;
  mapping (address => uint256) public contributions;

   
  bool public crowdsaleFinalized = false;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function BitGuildCrowdsale(uint256 _startTime, uint256 _endTime, address _token, address _wallet, address _whitelist) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_token != address(0));
    require(_wallet != address(0));
    require(_whitelist != address(0));

    startTime = _startTime;
    endTime = _endTime;
    token = BitGuildToken(_token);
    wallet = _wallet;
    whitelist = BitGuildWhitelist(_whitelist);
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(whitelist.whitelist(beneficiary));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);
    contributions[beneficiary] = contributions[beneficiary].add(weiAmount);

     
    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

     
    wallet.transfer(msg.value);
  }

   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    bool endTimeReached = now > endTime;
    return capReached || endTimeReached || crowdsaleFinalized;
  }

   
  function bonusPercentForWeiAmount(uint256 weiAmount) public pure returns(uint256) {
    if (weiAmount >= 500 ether) return 1000;  
    if (weiAmount >= 250 ether) return 750;   
    if (weiAmount >= 100 ether) return 500;   
    if (weiAmount >= 50 ether) return 375;    
    if (weiAmount >= 15 ether) return 250;    
    if (weiAmount >= 5 ether) return 125;     
    return 0;  
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    uint256 tokens = weiAmount.mul(rate);
    uint256 bonus = bonusPercentForWeiAmount(weiAmount);
    tokens = tokens.mul(10000 + bonus).div(10000);
    return tokens;
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool moreThanMinPurchase = msg.value >= minContribution;
    bool lessThanMaxPurchase = contributions[msg.sender] + msg.value <= maxContribution;
    bool withinCap = weiRaised.add(msg.value) <= cap;

    return withinPeriod && moreThanMinPurchase && lessThanMaxPurchase && withinCap && !crowdsaleFinalized;
  }

   
  function finalizeCrowdsale() public {
    require(msg.sender == wallet);
    crowdsaleFinalized = true;
     
    uint256 tokensLeft = token.balanceOf(this);
    token.transfer(wallet, tokensLeft);
  }
}