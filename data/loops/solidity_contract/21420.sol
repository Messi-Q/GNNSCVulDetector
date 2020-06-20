pragma solidity ^0.4.18;

 

 
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

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

contract XdacToken is StandardToken, Ownable {
    string public name = "XDAC COIN";
    string public symbol = "XDAC";
    uint8 public decimals = 18;
     
    function XdacToken(uint256 _initial_supply) public {
        totalSupply_ = _initial_supply;
        balances[msg.sender] = _initial_supply;
        Transfer(0x0, msg.sender, _initial_supply);
    }
}

 

 
contract XdacTokenCrowdsale is Ownable {

    using SafeMath for uint256;
    uint256[] roundGoals;
    uint256[] roundRates;
    uint256 minContribution;

     
    ERC20 public token;

     
    address public wallet;

    mapping(address => Contributor) public contributors;
     
    address[] addresses;

     
    uint256 public weiDelivered;


    event TokenRefund(address indexed purchaser, uint256 amount);
    event TokenPurchase(address indexed purchaser, address indexed contributor, uint256 value, uint256 amount);

    struct Contributor {
        uint256 eth;
        bool whitelisted;
        bool created;
    }


    function XdacTokenCrowdsale(
        address _wallet,
        uint256[] _roundGoals,
        uint256[] _roundRates,
        uint256 _minContribution,
        uint256 _initial_supply
    ) public {
        require(_wallet != address(0));
        require(_roundRates.length == 5);
        require(_roundGoals.length == 5);
        roundGoals = _roundGoals;
        roundRates = _roundRates;
        minContribution = _minContribution;
        token = new XdacToken(_initial_supply);
        wallet = _wallet;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _contributor) public payable {
        require(_contributor != address(0));
        require(msg.value != 0);
        require(msg.value >= minContribution);
        require(weiDelivered.add(msg.value) <= roundGoals[4]);

         
        uint256 tokens = _getTokenAmount(msg.value);

        TokenPurchase(msg.sender, _contributor, msg.value, tokens);
        _forwardFunds();
    }

     
    function _getCurrentRound() internal view returns (uint) {
        for (uint i = 0; i < 5; i++) {
            if (weiDelivered < roundGoals[i]) {
                return i;
            }
        }
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint curRound = _getCurrentRound();
        uint256 calculatedTokenAmount = 0;
        uint256 roundWei = 0;
        uint256 weiRaisedIntermediate = weiDelivered;
        uint256 weiAmount = _weiAmount;

        for (curRound; curRound < 5; curRound++) {
            if (weiRaisedIntermediate.add(weiAmount) > roundGoals[curRound]) {
                roundWei = roundGoals[curRound].sub(weiRaisedIntermediate);
                weiRaisedIntermediate = weiRaisedIntermediate.add(roundWei);
                weiAmount = weiAmount.sub(roundWei);
                calculatedTokenAmount = calculatedTokenAmount.add(roundWei.mul(roundRates[curRound]));
            }
            else {
                calculatedTokenAmount = calculatedTokenAmount.add(weiAmount.mul(roundRates[curRound]));
                break;
            }
        }
        return calculatedTokenAmount;
    }


     
    function _getEthAmount(uint256 _tokenAmount) internal view returns (uint256) {
        uint curRound = _getCurrentRound();
        uint256 calculatedWeiAmount = 0;
        uint256 roundWei = 0;
        uint256 weiRaisedIntermediate = weiDelivered;
        uint256 tokenAmount = _tokenAmount;

        for (curRound; curRound < 5; curRound++) {
            if(weiRaisedIntermediate.add(tokenAmount.div(roundRates[curRound])) > roundGoals[curRound]) {
                roundWei = roundGoals[curRound].sub(weiRaisedIntermediate);
                weiRaisedIntermediate = weiRaisedIntermediate.add(roundWei);
                tokenAmount = tokenAmount.sub(roundWei.div(roundRates[curRound]));
                calculatedWeiAmount = calculatedWeiAmount.add(tokenAmount.div(roundRates[curRound]));
            }
            else {
                calculatedWeiAmount = calculatedWeiAmount.add(tokenAmount.div(roundRates[curRound]));
                break;
            }
        }

        return calculatedWeiAmount;
    }

    function _forwardFunds() internal {
        Contributor storage contributor = contributors[msg.sender];
        contributor.eth = contributor.eth.add(msg.value);
        if (contributor.created == false) {
            contributor.created = true;
            addresses.push(msg.sender);
        }
        if (contributor.whitelisted) {
            _deliverTokens(msg.sender);
        }
    }

    function _deliverTokens(address _contributor) internal {
        Contributor storage contributor = contributors[_contributor];
        uint256 amountEth = contributor.eth;
        uint256 amountToken = _getTokenAmount(amountEth);
        require(amountToken > 0);
        require(amountEth > 0);
        require(contributor.whitelisted);
        contributor.eth = 0;
        weiDelivered = weiDelivered.add(amountEth);
        wallet.transfer(amountEth);
        token.transfer(_contributor, amountToken);
    }

    function _refundTokens(address _contributor) internal {
        Contributor storage contributor = contributors[_contributor];
        uint256 ethAmount = contributor.eth;
        require(ethAmount > 0);
        contributor.eth = 0;
        TokenRefund(_contributor, ethAmount);
        _contributor.transfer(ethAmount);
    }

    function _whitelistAddress(address _contributor) internal {
        Contributor storage contributor = contributors[_contributor];
        contributor.whitelisted = true;
        if (contributor.created == false) {
            contributor.created = true;
            addresses.push(_contributor);
        }
         
        if (contributor.eth > 0) {
            _deliverTokens(_contributor);
        }
    }

    function _sendToken(address _address, uint256 _amountTokens) internal{
        XdacToken _token = XdacToken(token);
        require(_token.balanceOf(_token.owner()) >= _amountTokens);
        _token.transfer(_address, _amountTokens);
    }

     

    function whitelistAddresses(address[] _contributors) public onlyOwner {
        for (uint256 i = 0; i < _contributors.length; i++) {
            _whitelistAddress(_contributors[i]);
        }
    }


    function whitelistAddress(address _contributor) public onlyOwner {
        _whitelistAddress(_contributor);
    }

    function transferTokenOwnership(address _newOwner) public onlyOwner returns(bool success) {
        XdacToken _token = XdacToken(token);
        _token.transfer(_newOwner, _token.balanceOf(_token.owner()));
        _token.transferOwnership(_newOwner);
        return true;
    }

    function sendToken(address _address, uint256 _amountTokens) public onlyOwner returns(bool success) {
        _sendToken(_address, _amountTokens);
        return true;
    }

    function sendTokens(address[] _addresses, uint256[] _amountTokens) public onlyOwner returns(bool success) {
        require(_addresses.length > 0);
        require(_amountTokens.length > 0);
        require(_addresses.length  == _amountTokens.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            _sendToken(_addresses[i], _amountTokens[i]);
        }
        return true;
    }
     
    function refundTokensForAddress(address _contributor) public onlyOwner {
        _refundTokens(_contributor);
    }


     

    function getAddresses() public onlyOwner view returns (address[] )  {
        return addresses;
    }

     
    function refundTokens() public {
        _refundTokens(msg.sender);
    }
     
    function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
        return _getTokenAmount(_weiAmount);
    }

     
    function getEthAmount(uint256 _tokenAmount) public view returns (uint256) {
        return _getEthAmount(_tokenAmount);
    }

    function getCurrentRate() public view returns (uint256) {
        return roundRates[_getCurrentRound()];
    }
}