pragma solidity 0.4.18;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint256) {
        uint c = a / b;
        return c;
    }

    function sub(uint256 a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint a, uint b) internal pure returns (uint) {
        uint c = a ** b;
        assert(c >= a);
        return c;
    }
}


 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address _who) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) public balances;

     
    uint64 public dateTransferable = 1518825600;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        uint64 _now = uint64(block.timestamp);
        require(_now >= dateTransferable);
        require(_to != address(this));  
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }
}


 
contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public constant returns (uint256);
    function transferFrom(address _from, address _to, uint256 value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Ownable {

    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
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

     
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

     
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}


 
contract MintableToken is BasicToken, Ownable {

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[owner] = balances[owner].add(_amount);
        Mint(owner, _amount);
        Transfer(0x0, owner, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}


 
contract Xineoken is BasicToken, Ownable, Pausable, MintableToken {

    using SafeMath for uint256;
    
    string public name = "Xineoken";
    uint256 public decimals = 2;
    string public symbol = "XIN";

     
    uint256 public buyPrice = 10526315789474;
     
    uint256 public buyPriceFinal = 52631578947368;
     
    uint256 public allocatedTokens = 0;
     
    uint256 public stage1Tokens = 330000000 * (10 ** decimals);
     
    uint256 public stage2Tokens = 660000000 * (10 ** decimals);
     
    uint256 public minimumBuyAmount = 100000000000000000;
    
    function Xineoken() public {
        totalSupply = 1000000000 * (10 ** decimals);
        balances[owner] = totalSupply;
    }

     
    function () public payable {
        buyToken();
    }
    
     
    function calculateTokenAmount(uint256 _value) public view returns (uint256) {

        var tokenAmount = uint256(0);
        var tokenAmountCurrentStage = uint256(0);
        var tokenAmountNextStage = uint256(0);
  
        var stage1TokensNoDec = stage1Tokens / (10 ** decimals);
        var stage2TokensNoDec = stage2Tokens / (10 ** decimals);
        var allocatedTokensNoDec = allocatedTokens / (10 ** decimals);
  
        if (allocatedTokensNoDec < stage1TokensNoDec) {
            tokenAmount = _value / buyPrice;
            if (tokenAmount.add(allocatedTokensNoDec) > stage1TokensNoDec) {
                tokenAmountCurrentStage = stage1TokensNoDec.sub(allocatedTokensNoDec);
                tokenAmountNextStage = (_value.sub(tokenAmountCurrentStage.mul(buyPrice))) / (buyPrice * 2);
                tokenAmount = tokenAmountCurrentStage + tokenAmountNextStage;
            }
        } else if (allocatedTokensNoDec < (stage2TokensNoDec)) {
            tokenAmount = _value / (buyPrice * 2);
            if (tokenAmount.add(allocatedTokensNoDec) > stage2TokensNoDec) {
                tokenAmountCurrentStage = stage2TokensNoDec.sub(allocatedTokensNoDec);
                tokenAmountNextStage = (_value.sub(tokenAmountCurrentStage.mul(buyPrice * 2))) / buyPriceFinal;
                tokenAmount = tokenAmountCurrentStage + tokenAmountNextStage;
            }
        } else {
            tokenAmount = _value / buyPriceFinal;
        }

        return tokenAmount;
    }

     
    function buyToken() public whenNotPaused payable {

        require(msg.sender != 0x0);
        require(msg.value >= minimumBuyAmount);
        
        uint256 weiAmount = msg.value;
        uint256 tokens = calculateTokenAmount(weiAmount);

        require(tokens > 0);

        uint256 totalTokens = tokens * (10 ** decimals);

        balances[owner] = balances[owner].sub(totalTokens);
        balances[msg.sender] = balances[msg.sender].add(totalTokens);
        allocatedTokens = allocatedTokens.add(totalTokens);
        Transfer(owner, msg.sender, totalTokens);
        
        forwardFunds();
    }

     
    function allocateTokens(address _to, uint256 _tokens) public onlyOwner returns (bool) {
        require(balanceOf(owner) >= _tokens);
        balances[owner] = balances[owner].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        allocatedTokens = allocatedTokens.add(_tokens);
        Transfer(owner, _to, _tokens);
        return true;
    }

     
    function setBuyPrice(uint256 _newBuyPrice, uint256 _newBuyPriceFinal) public onlyOwner returns (bool) {
        buyPrice = _newBuyPrice;
        buyPriceFinal = _newBuyPriceFinal;
        return true;
    }

     
    function setTransferableDate(uint64 _date) public onlyOwner {
        dateTransferable = _date;
    }

     
    function setMinimumBuyAmount(uint256 _amount) public onlyOwner {
        minimumBuyAmount = _amount;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
             
            var previousOwner = owner;
            var ownerBalance = balances[previousOwner];
            balances[previousOwner] = balances[previousOwner].sub(ownerBalance);
            balances[newOwner] = balances[newOwner].add(ownerBalance);
            owner = newOwner;
            Transfer(previousOwner, newOwner, ownerBalance);
        }
    }

     
    function forwardFunds() internal {
        if (!owner.send(msg.value)) {
            revert();
        }
    }
}