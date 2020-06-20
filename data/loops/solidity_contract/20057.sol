pragma solidity ^0.4.11;

 
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

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

 
contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
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
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract MintableToken is StandardToken, Ownable, Pausable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    uint256 public constant maxTokensToMint = 1000000000 ether;
    uint256 public constant maxTokensToBuy  = 600000000 ether;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) whenNotPaused onlyOwner returns (bool) {
        return mintInternal(_to, _amount);
    }

     
    function finishMinting() whenNotPaused onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function mintInternal(address _to, uint256 _amount) internal canMint returns (bool) {
        require(totalSupply.add(_amount) <= maxTokensToMint);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(this, _to, _amount);
        return true;
    }
}

contract Test is MintableToken {

    string public constant name = "HIH";

    string public constant symbol = "HIH";

    bool public preIcoActive = false;

    bool public preIcoFinished = false;

    bool public icoActive = false;

    bool public icoFinished = false;

    bool public transferEnabled = false;

    uint8 public constant decimals = 18;

    uint256 public constant maxPreIcoTokens = 100000000 ether;

    uint256 public preIcoTokensCount = 0;

    uint256 public tokensForIco = 600000000 ether;

    address public wallet = 0xa74fF9130dBfb9E326Ad7FaE2CAFd60e52129CF0;

    uint256 public dateStart = 1511987870;

    uint256 public rateBase = 35000;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);


     
    function transfer(address _to, uint _value) whenNotPaused canTransfer returns (bool) {
        require(_to != address(this) && _to != address(0));
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) whenNotPaused canTransfer returns (bool) {
        require(_to != address(this) && _to != address(0));
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

     
    modifier canTransfer() {
        require(transferEnabled);
        _;
    }

     
    function enableTransfer() onlyOwner returns (bool) {
        transferEnabled = true;
        return true;
    }

    function startPre() onlyOwner returns (bool) {
        require(!preIcoActive && !preIcoFinished && !icoActive && !icoFinished);
        preIcoActive = true;
        dateStart = block.timestamp;
        return true;
    }

    function finishPre() onlyOwner returns (bool) {
        require(preIcoActive && !preIcoFinished && !icoActive && !icoFinished);
        preIcoActive = false;
        tokensForIco = maxTokensToBuy.sub(totalSupply);
        preIcoTokensCount = totalSupply;
        preIcoFinished = true;
        return true;
    }

    function startIco() onlyOwner returns (bool) {
        require(!preIcoActive && preIcoFinished && !icoActive && !icoFinished);
        icoActive = true;
        return true;
    }

    function finishIco() onlyOwner returns (bool) {
        require(!preIcoActive && preIcoFinished && icoActive && !icoFinished);
        icoActive = false;
        icoFinished = true;
        return true;
    }

    modifier canBuyTokens() {
        require(preIcoActive || icoActive);
        require(block.timestamp >= dateStart);
        _;
    }

    function () payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) whenNotPaused canBuyTokens payable {
        require(beneficiary != 0x0);
        require(msg.value > 0);
        require(msg.value >= 10 finney);

        uint256 weiAmount = msg.value;
        uint256 tokens = 0;
        if(preIcoActive){
            tokens = buyPreIcoTokens(weiAmount);
        }else if(icoActive){
            tokens = buyIcoTokens(weiAmount);
        }
        mintInternal(beneficiary, tokens);
        forwardFunds();

    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function changeWallet(address _newWallet) onlyOwner returns (bool) {
        require(_newWallet != 0x0);
        wallet = _newWallet;
        return true;
    }

    function buyPreIcoTokens(uint256 _weiAmount) internal returns(uint256){
        uint8 percents = 0;

        if(block.timestamp - dateStart <= 10 days){
            percents = 20;
        }

        if(block.timestamp - dateStart <= 8 days){
            percents = 40;
        }

        if(block.timestamp - dateStart <= 6 days){
            percents = 60;
        }

        if(block.timestamp - dateStart <= 4 days){
            percents = 80;
        }

        if(block.timestamp - dateStart <= 2 days){   
            percents = 100;
        }

        uint256 tokens = _weiAmount.mul(rateBase).mul(2);

        if(percents > 0){
            tokens = tokens.add(tokens.mul(percents).div(100));     
        }

        require(totalSupply.add(tokens) <= maxPreIcoTokens);

        return tokens;

    }

    function buyIcoTokens(uint256 _weiAmount) internal returns(uint256){
        uint256 rate = getRate();
        uint256 tokens = _weiAmount.mul(rate);

        tokens = tokens.add(tokens.mul(30).div(100));     

        require(totalSupply.add(tokens) <= maxTokensToBuy);

        return tokens;

    }

    function getRate() internal returns(uint256){
        uint256 rate = rateBase;
        uint256 step = tokensForIco.div(5);


        uint8 additionalPercents = 0;

        if(totalSupply < step){
            additionalPercents = 0;
        }else{
            uint256 currentRound = totalSupply.sub(preIcoTokensCount).div(step);

            if(currentRound >= 4){
                additionalPercents = 30;
            }

            if(currentRound >= 3 && currentRound < 4){
                additionalPercents = 30;
            }

            if(currentRound >= 2&& currentRound < 3){
                additionalPercents = 20;
            }

            if(currentRound >= 1 && currentRound < 2){
                additionalPercents = 10;
            }
        }

        if(additionalPercents > 0){
            rate -= rateBase.mul(additionalPercents).div(100);     
        }

        return rate;
    }

    function setDateStart(uint256 _dateStart) onlyOwner returns (bool) {
        require(_dateStart > block.timestamp);
        dateStart = _dateStart;
        return true;
    }

    function setRate(uint256 _rate) onlyOwner returns (bool) {
        require(_rate > 0);
        rateBase = _rate;
        return true;
    }

}