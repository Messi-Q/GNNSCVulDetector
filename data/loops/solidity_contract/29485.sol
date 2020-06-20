pragma solidity ^0.4.18;


 

library SafeMath {


    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}


 


 

contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}


 

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint) {
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

}


 

contract Ownable {
    address public owner;
    address public newOwner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() { 
        require(msg.sender == owner);
        _;
    }

    modifier onlyNewOwner() {
        require(msg.sender == newOwner);
        _;
    }
     

    function proposeNewOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() external onlyNewOwner {
        require(newOwner != owner);
        owner = newOwner;
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
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}


 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public  {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}


 

contract Pausable is Ownable {


    event Pause();
    event Unpause();

    bool public paused = true;


     
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



 

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

}


 

contract AcjToken is BurnableToken, MintableToken, PausableToken {
    using SafeMath for uint256;

    string public constant name = "Artist Connect Coin";
    string public constant symbol = "ACJ";
    uint public constant decimals = 18;
    
    function AcjToken() public {
        totalSupply = 150000000 ether; 
        balances[msg.sender] = totalSupply;
        paused = true;
    }

    function activate() external onlyOwner {
        unpause();
        finishMinting();
    }

     
     
     
    function initialTransfer(address _to, uint _value) external onlyOwner returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function burn(uint256 _amount) public onlyOwner {
        super.burn(_amount);
    }

}

 


contract AcjCrowdsale is Ownable {

    using SafeMath for uint256;
    
     
    uint public constant BONUS_PRESALE = 10;            
     
    uint public constant BONUS_MID = 10;                
     
    uint public constant BONUS_HI = 20;                 
     
    uint public constant BONUS_MID_QTY = 150 ether;     
     
    uint public constant BONUS_HI_QTY = 335 ether;      
     
    uint public startPresale;            
    uint public endPresale;             
    uint public startIco;              
    uint public endIco;               
     
    uint public constant REFUND_PERIOD = 30 days;
     
    mapping(address => uint256) public tokenBalances;    
     
    address public token;
     
    uint256 public constant TOKENS_TOTAL_SUPPLY = 150000000 ether; 
     
    uint256 public constant TOKENS_FOR_SALE = 75000000 ether;    
     
    uint256 public constant TOKENS_SOFT_CAP = 500000 ether;       
     
    uint256 public tokensSold;                             
     
    uint256 public tokensDistributed;                                         
     
    uint256 public ethTokenRate;                                 
     
    mapping(address => bool) public admins;                    
     
    uint256 public weiReceived;                            
     
    uint256 public constant MIN_CONTRIBUTION = 100 finney;           
     
    mapping(address => uint256) public contributions;
     
    mapping(address => bool) public refunds;
     
    address public companyWallet;     

     
    event Contribute(address indexed _from, uint _amount); 
     
    event TokenRateUpdated(uint _newRate);                  
     
    event Refunded(address indexed _from, uint _amount);    
    
    modifier belowTotalSupply {
        require(tokensDistributed < TOKENS_TOTAL_SUPPLY);
        _;
    }

    modifier belowHardCap {
        require(tokensDistributed < TOKENS_FOR_SALE);
        _;
    }

    modifier adminOnly {
        require(msg.sender == owner || admins[msg.sender] == true);
        _;
    }

    modifier crowdsaleFailed {
        require(isFailed());
        _;
    }

    modifier crowdsaleSuccess {
        require(isSuccess());
        _;
    }

    modifier duringSale {
        require(now < endIco);
        require((now > startPresale && now < endPresale) || now > startIco);
        _;
    }

    modifier afterSale {
        require(now > endIco);
        _;
    }

    modifier aboveMinimum {
        require(msg.value >= MIN_CONTRIBUTION);
        _;
    }

     
    function AcjCrowdsale(
        uint _presaleStart,
        uint _presaleEnd,
        uint _icoStart,
        uint _icoEnd,
        uint256 _rate,
        address _token
    ) public 
    {
        require(_presaleEnd > _presaleStart);
        require(_icoStart > _presaleEnd);
        require(_icoEnd > _icoStart);
        require(_rate > 0); 

        startPresale = _presaleStart;
        endPresale = _presaleEnd;
        startIco = _icoStart;
        endIco = _icoEnd;
        ethTokenRate = _rate;
        
        admins[msg.sender] = true;
        companyWallet = msg.sender;

        token = _token;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
     
    function addAdmin(address _adr) external onlyOwner {
        require(_adr != address(0));
        admins[_adr] = true;
    }

    function removeAdmin(address _adr) external onlyOwner {
        require(_adr != address(0));
        admins[_adr] = false;
    }

     
    function updateCompanyWallet(address _wallet) external adminOnly {
        companyWallet = _wallet;
    }

     
    function proposeTokenOwner(address _newOwner) external adminOnly {
        AcjToken _token = AcjToken(token);
        _token.proposeNewOwner(_newOwner);
    }

    function acceptTokenOwnership() external onlyOwner {    
        AcjToken _token = AcjToken(token);
        _token.acceptOwnership();
    }

     
    function activateToken() external adminOnly crowdsaleSuccess afterSale {
        AcjToken _token = AcjToken(token);
        _token.activate();
    }

     
    function adjustTokenExchangeRate(uint _rate) external adminOnly {
        require(now > endPresale && now < startIco);
        ethTokenRate = _rate;
        TokenRateUpdated(_rate);
    }

          
    function refundContribution() external crowdsaleFailed afterSale {
        require(!refunds[msg.sender]);
        require(contributions[msg.sender] > 0);

        uint256 _amount = contributions[msg.sender];
        tokenBalances[msg.sender] = 0;
        refunds[msg.sender] = true;
        Refunded(msg.sender, contributions[msg.sender]);
        msg.sender.transfer(_amount);
    }

          
    function withdrawUnclaimed() external adminOnly {
        require(now > endIco + REFUND_PERIOD || isSuccess());
        companyWallet.transfer(this.balance);
    }

     
    function reserveTokens(address _beneficiary, uint256 _tokensQty) external adminOnly belowTotalSupply {
        require(_beneficiary != address(0));
        uint _distributed = tokensDistributed.add(_tokensQty);

        require(_distributed <= TOKENS_TOTAL_SUPPLY);

        tokenBalances[_beneficiary] = _tokensQty.add(tokenBalances[_beneficiary]);
        tokensDistributed = _distributed;

        AcjToken _token = AcjToken(token);
        _token.initialTransfer(_beneficiary, _tokensQty);
    }

          
    function buyTokens(address _beneficiary) public payable duringSale aboveMinimum belowHardCap {
        require(_beneficiary != address(0));
        uint256 _weiAmount = msg.value;        
        uint256 _tokensQty = msg.value.mul(getBonus(_weiAmount));
        uint256 _distributed = _tokensQty.add(tokensDistributed);
        uint256 _sold = _tokensQty.add(tokensSold);

        require(_distributed <= TOKENS_TOTAL_SUPPLY);
        require(_sold <= TOKENS_FOR_SALE);

        contributions[_beneficiary] = _weiAmount.add(contributions[_beneficiary]);
        tokenBalances[_beneficiary] = _tokensQty.add(tokenBalances[_beneficiary]);
        weiReceived = weiReceived.add(_weiAmount);
        tokensDistributed = _distributed;
        tokensSold = _sold;

        Contribute(_beneficiary, msg.value);

        AcjToken _token = AcjToken(token);
        _token.initialTransfer(_beneficiary, _tokensQty);
    }

     
    function hasEnded() public view returns(bool) {
        return now > endIco;
    }

     
    function isSuccess() public view returns(bool) {
        if (tokensDistributed >= TOKENS_SOFT_CAP) {
            return true;
        }
        return false;
    }

     
    function isFailed() public view returns(bool) {
        if (tokensDistributed < TOKENS_SOFT_CAP && now > endIco) {
            return true;
        }
        return false;
    }

     
    function getBonus(uint256 _wei) internal constant returns(uint256 ethToAcj) {
        uint256 _bonus = 0;

         
        if (endPresale > now) {
            _bonus = _bonus.add(BONUS_PRESALE); 
        }

         
        if (_wei >= BONUS_HI_QTY) { 
            _bonus = _bonus.add(BONUS_HI);
        } else if (_wei >= BONUS_MID_QTY) {
            _bonus = _bonus.add(BONUS_MID);
        }

        return ethTokenRate.mul(100 + _bonus) / 100;
    }

}