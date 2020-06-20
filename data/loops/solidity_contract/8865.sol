pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  function Ownable() public {
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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
    
  mapping (address => uint256) balances;
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

contract StandardToken is ERC20, BurnableToken {

  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
}

contract BittechToken is StandardToken {

  string constant public name = "Bittech Token";
  string constant public symbol = "BTECH";
  uint256 constant public decimals = 18;

  address constant public bountyWallet = 0x8E8d4cdADbc027b192DfF91c77382521B419E5A2;
  uint256 public bountyPart = uint256(5000000).mul(10 ** decimals); 
  address constant public adviserWallet = 0x1B9D19Af310E8cB35D0d3B8977b65bD79C5bB299;
  uint256 public adviserPart = uint256(1000000).mul(10 ** decimals);
  address constant public reserveWallet = 0xa323DA182fDfC10861609C2c98894D9745ABAB91;
  uint256 public reservePart = uint256(20000000).mul(10 ** decimals);
  address constant public ICOWallet = 0x1ba99f4F5Aa56684423a122D72990A7851AaFD9e;
  uint256 public ICOPart = uint256(60000000).mul(10 ** decimals);
  uint256 public PreICOPart = uint256(5000000).mul(10 ** decimals);
  address constant public teamWallet = 0x69548B7740EAf1200312d803f8bDd04F77523e09;
  uint256 public teamPart = uint256(9000000).mul(10 ** decimals);

  uint256 constant public yearSeconds = 31536000;  
  uint256 constant public secsPerBlock = 15;  
  uint256 public INITIAL_SUPPLY = uint256(100000000).mul(10 ** decimals);  

  uint256 public withdrawTokens = 0;
  uint256 public startTime;

  function BittechToken() public {
    totalSupply_ = INITIAL_SUPPLY;

    balances[bountyWallet] = bountyPart;
    emit Transfer(this, bountyWallet, bountyPart);

    balances[adviserWallet] = adviserPart;
    emit Transfer(this, adviserWallet, adviserPart);

    balances[reserveWallet] = reservePart;
    emit Transfer(this, reserveWallet, reservePart);

    balances[ICOWallet] = ICOPart;
    emit Transfer(this, ICOWallet, ICOPart);

    balances[msg.sender] = PreICOPart;
    emit Transfer(this, msg.sender, PreICOPart);

    balances[this] = teamPart;
    emit Transfer(this, this, teamPart); 

    startTime = block.number;
  }

  modifier onlyTeam() {
    require(msg.sender == teamWallet);
    _;
  }

  function viewTeamTokens() public view returns (uint256) {

    if (block.number >= startTime.add(yearSeconds.div(secsPerBlock))) {
      return 3000000;
    }

    if (block.number >= startTime.add(yearSeconds.div(secsPerBlock).mul(2))) {
      return 6000000;
    }

    if (block.number >= startTime.add(yearSeconds.div(secsPerBlock).mul(3))) {
      return 9000000;
    }

  }

  function getTeamTokens(uint256 _tokens) public onlyTeam {
    uint256 tokens = _tokens.mul(10 ** decimals);
    require(withdrawTokens.add(tokens) <= viewTeamTokens().mul(10 ** decimals));
    transfer(teamWallet, tokens);
    emit Transfer(this, teamWallet, tokens);
    withdrawTokens = withdrawTokens.add(tokens);
  }
  
}

contract BittechPresale is Pausable {
    using SafeMath for uint256;

    BittechToken public tokenReward;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public balanceOfUSD;
    uint256 constant public tokenHardCap = 5000000000000000000000000;  
    uint256 constant public decim = 1000000000000000000;  
    uint256 public tokensRaised = 0;
    uint256 public minimalPriceUSD = 2000000;
    uint256 public ETHUSD = 520;
    uint256 public tokenPricePerUSD = 100;
    bool public presaleFinished = false;
    
    modifier whenNotFinished() {
        require(!presaleFinished);
        _;
    }

    modifier whenFinished() {
        require(presaleFinished);
        _;
    }

    function BittechPresale(address _tokenReward) public {
        tokenReward = BittechToken(_tokenReward);
        owner = 0x8Ce2e52b5A75035E9d282226A42A6C6E551f1198;
    }
    
    function () public payable {
        buy(msg.sender);
    }

    function getBonus(address investor) public view returns (uint256) {
        if (balanceOfUSD[investor] <= 10000) return 100;
        else if (balanceOfUSD[investor] <= 30000) return 110;
        else if (balanceOfUSD[investor] <= 50000) return 120;
        else if (balanceOfUSD[investor] <= 100000) return 130;
        else return 140;
    }

    function buy(address buyer) whenNotPaused whenNotFinished public payable {
        require(buyer != address(0));
        require(msg.value.mul(ETHUSD) >= minimalPriceUSD.mul(decim).div(1000));
        
        uint256 tokens = msg.value.mul(ETHUSD).mul(getBonus(buyer)).mul(tokenPricePerUSD).div(100).div(100);
        tokenReward.transfer(buyer, tokens);
        uint256 receivedDollars = msg.value.mul(ETHUSD).div(decim);
        balanceOfUSD[buyer] = balanceOfUSD[buyer].add(receivedDollars);
        balanceOf[buyer] = balanceOf[buyer].add(msg.value);

        tokensRaised = tokensRaised.add(tokens);

        if (tokensRaised >= tokenHardCap) {
            presaleFinished = true;
            uint256 tokenBalance = tokenReward.balanceOf(address(this));
            tokenReward.burn(tokenBalance);
        }
        owner.transfer(msg.value);
    }

    function transferFunds() onlyOwner public {
        owner.transfer(address(this).balance);
    }
    
    function transferTokens(address who, uint amount) onlyOwner public {
        tokenReward.transfer(who, amount);
    }

    function finishPresale() onlyOwner public {
        presaleFinished = true;

        uint256 tokenBalance = tokenReward.balanceOf(address(this));
        tokenReward.burn(tokenBalance);
    }

    function updatePrice(uint256 _ETHUSD) onlyOwner public {
        ETHUSD = _ETHUSD;
    }

    function updateMinimal(uint256 _minimalPriceUSD) onlyOwner public {
        minimalPriceUSD = _minimalPriceUSD;
    }

    function updateTokenPricePerUSD(uint256 _tokenPricePerUSD) onlyOwner public {
        tokenPricePerUSD = _tokenPricePerUSD;
    }

}