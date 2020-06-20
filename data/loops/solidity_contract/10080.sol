pragma solidity 0.4.24;


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
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

}

contract CanReclaimToken is Ownable {
     
    function reclaimToken(ERC20Basic token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }
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
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
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
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

 
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

interface BLLNDividendInterface {
    function setTokenAddress(address _tokenAddress) external;
    function buyToken() external payable;
    function withdraw(uint256 _amount) external;
    function withdrawTo(address _to, uint256 _amount) external;
    function updateDividendBalance(uint256 _totalSupply, address _address, uint256 _tokensAmount) external;
    function transferTokens(address _from, address _to, uint256 _amount) external returns (bool);
    function shareDividends() external payable;
    function getDividendBalance(address _address) external view returns (uint256);
}

contract BLLNToken is MintableToken, CanReclaimToken {
    string public constant name = "Billion Token";
    string public constant symbol = "BLLN";
    uint32 public constant decimals = 0;
    uint256 public constant maxTotalSupply = 250*(10**6);
    BLLNDividendInterface public dividend;

    constructor(address _dividendAddress) public {
        require(_dividendAddress != address(0));
        dividend = BLLNDividendInterface(_dividendAddress);
    }

    modifier canMint() {
        require(totalSupply_ < maxTotalSupply);
        _;
    }

    modifier onlyDividend() {
        require(msg.sender == address(dividend));
        _;
    }

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length == size + 4);
        _;
    }

    function () public {}

    function mint(address _to, uint256 _amount) public onlyDividend canMint returns (bool) {
        require(_to != address(0));
        require(_amount != 0);
        uint256 newTotalSupply = totalSupply_.add(_amount);
        require(newTotalSupply <= maxTotalSupply);

        totalSupply_ = newTotalSupply;
        balances[_to] = balances[_to].add(_amount);

        dividend.updateDividendBalance(totalSupply_, _to, _amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2*32) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        require(dividend.transferTokens(msg.sender, _to, _value));
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}

contract Log {
    function ln(uint256 _x)  public pure returns (int256) {
        require(_x < 2**255);
        require(_x >= 10**18);

        int256 epsilon = 1000;
        int256 x = int256(_x);
        int256 result = 0;
        while (x >= 1.5*(10**18)) {
            result = result + 405465108108164381;  
            x = x * 2 / 3;
        }
        x = x - 10**18;
        int256 next = x;
        int step = 1;
        while (next > epsilon) {
            result = result + (next / step);
            step = step + 1;
            next = next * x / 10**18;
            result = result - (next / step);
            step = step + 1;
            next = next * x / 10**18;
        }
        return result;
    }
}

contract BLLNDividend is Ownable, Log, BLLNDividendInterface, CanReclaimToken {
    using SafeMath for uint256;

    event PresaleFinished();

    event DividendsArrived(
        uint256 newD_n
    );

    struct UserHistory {
        uint256 lastD_n;
        uint256 tokens;
    }

    uint256 internal constant rounding = 10**18;

    BLLNToken public m_token;
    bool public m_presaleFinished;
    uint256 public m_sharedDividendBalance;
    uint256 public m_maxTotalSupply;
    uint256 public m_tokenPrice = 300 szabo;  
    uint256 public m_tokenDiscountThreshold;

    uint256 public m_D_n;
    uint256 public m_totalTokens;
    mapping (address => uint256) public m_dividendBalances;
    mapping (address => UserHistory) public m_userHistories;

    constructor(uint256 _maxTotalSupply) public {
        require(_maxTotalSupply > 0);

        m_presaleFinished = false;
        owner = msg.sender;
        m_maxTotalSupply = _maxTotalSupply;
        m_tokenDiscountThreshold = 10**4;
    }

    modifier onlyToken() {
        require(msg.sender == address(m_token));
        _;
    }

    modifier onlyPresale() {
        require(!m_presaleFinished);
        _;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0));
        m_token = BLLNToken(_tokenAddress);
    }

    function setTokenDiscountThreshold(uint256 _discountThreshold) external onlyOwner {
        require(_discountThreshold > 0);
        m_tokenDiscountThreshold = _discountThreshold;
    }

    function mintPresale(uint256 _presaleAmount, address _receiver) external onlyOwner onlyPresale returns (bool) {
        require(_presaleAmount > 0);
        require(_receiver != address(0));
        require(address(m_token) != address(0));
        require(m_token.mint(_receiver, _presaleAmount));
        return true;
    }

    function finishPresale() external onlyOwner onlyPresale returns (bool) {
        m_presaleFinished = true;
        emit PresaleFinished();
        return true;
    }

    function buyToken() external payable {
        buyTokens(msg.sender);
    }

    function withdraw(uint256 _amount) external {
        require(_amount != 0);
        uint256 userBalance = m_dividendBalances[msg.sender].add(getDividendAmount(msg.sender));
        require(userBalance >= _amount);

        takeDividends(msg.sender);

        m_dividendBalances[msg.sender] = userBalance.sub(_amount);
        msg.sender.transfer(_amount);
    }

    function withdrawTo(address _to, uint256 _amount) external {
        require(_amount != 0);
        require(_to != address(0));
        uint256 userBalance = m_dividendBalances[msg.sender].add(getDividendAmount(msg.sender));
        require(userBalance >= _amount);

        takeDividends(msg.sender);

        m_dividendBalances[msg.sender] = userBalance.sub(_amount);
        _to.transfer(_amount);
    }

    function updateDividendBalance(uint256 _totalSupply, address _address, uint256 _tokensAmount) external onlyToken {
        m_totalTokens = m_totalTokens.add(_tokensAmount);
        require(m_totalTokens == _totalSupply);

        takeDividends(_address);
        m_userHistories[_address].tokens = m_userHistories[_address].tokens.add(_tokensAmount);
    }

    function transferTokens(address _from, address _to, uint256 _amount) external onlyToken returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        takeDividends(_from);
        takeDividends(_to);

        m_userHistories[_from].tokens = m_userHistories[_from].tokens.sub(_amount);
        m_userHistories[_to].tokens = m_userHistories[_to].tokens.add(_amount);
        return true;
    }

    function shareDividends() external onlyOwner payable {
        require(msg.value > 0);
        m_sharedDividendBalance = m_sharedDividendBalance.add(msg.value);
        m_D_n = m_D_n.add(msg.value.mul(rounding).div(m_totalTokens));

        emit DividendsArrived(m_D_n);
    }

    function getDividendBalance(address _address) external view returns (uint256) {
        return m_dividendBalances[_address].add(getDividendAmount(_address));
    }

    function getDividendAmount(address _address) public view returns (uint256) {
        UserHistory memory history = m_userHistories[_address];
        if (history.tokens == 0) {
            return 0;
        }

        uint256 dividends = m_D_n.sub(history.lastD_n).mul(history.tokens);

        dividends = dividends.div(rounding);

        return dividends;
    }

    function buyTokens(address _receiver) public payable {
        require(msg.value > 0);

        uint256 totalSupply = m_token.totalSupply();
        uint256 tokens;
        uint256 change;
        (tokens, change) = calculateTokensFrom(msg.value, totalSupply);
        uint256 tokenPrice = msg.value.sub(change);

        m_sharedDividendBalance = m_sharedDividendBalance.add(tokenPrice);

        m_D_n = m_D_n.add(tokenPrice.mul(rounding).div(m_totalTokens));
        m_dividendBalances[_receiver] = m_dividendBalances[_receiver].add(change);

        require(m_token.mint(_receiver, tokens));
        emit DividendsArrived(m_D_n);
    }

    function calculateTokensFrom(uint256 _value, uint256 _totalSupply) public view returns (uint256, uint256) {
        require(_value >= m_tokenPrice);
        return calculateTokensAmountToSale(_value, _totalSupply);
    }

    function priceFor(uint256 _tokenAmount) public view returns (uint256) {
        uint256 price = m_tokenPrice.mul(_tokenAmount);
        return price;
    }

    function priceWithDiscount(uint256 _tokenAmount, uint256 _totalTokens) public view returns (uint256) {
        uint256 s = _totalTokens.add(_tokenAmount).mul(rounding).div(_totalTokens);
        int256 log = ln(s);
        return m_tokenPrice.mul(_totalTokens).mul(uint256(log)).div(rounding);
    }

    function tokensAmountFrom(uint256 _value) public view returns (uint256) {
        uint256 tokensAmount = _value.div(m_tokenPrice);
        return tokensAmount;
    }

     
    function takeDividends(address _user) private {
        uint256 userAmount = getDividendAmount(_user);
        m_userHistories[_user].lastD_n = m_D_n;
        if (userAmount == 0) {
            return;
        }
        m_dividendBalances[_user] = m_dividendBalances[_user].add(userAmount);
        m_sharedDividendBalance = m_sharedDividendBalance.sub(userAmount);
    }

    function calculateTokensAmountToSale(uint256 _value, uint256 _totalSupply) private view returns (uint256, uint256) {
        uint256 maxTotalSupply = m_maxTotalSupply;
        require(_totalSupply < maxTotalSupply);

        uint256 remainingTokens = maxTotalSupply.sub(_totalSupply);
        uint256 remainingPrice = priceFor(remainingTokens);

        if (remainingPrice < _value) {
            return (remainingTokens, _value - remainingPrice);
        }

        uint256 approxTokens = tokensAmountFrom(_value);
        uint256 approxPrice;

        if (approxTokens >= m_tokenDiscountThreshold) {
            approxPrice = priceWithDiscount(approxTokens, _totalSupply);
        } else {
            approxPrice = priceFor(approxTokens);
        }

        uint256 change = _value.sub(approxPrice);
        return (approxTokens, change);
    }
}