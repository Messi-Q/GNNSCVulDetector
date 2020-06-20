pragma solidity ^0.4.17;

 
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

   
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0));
        require(newOwner != address(this));
        require(newOwner != owner);  
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

   
    function transfer(address _to, uint256 _value) public returns (bool){
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
 

 
contract MintableToken is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

   
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(0X0, _to, _amount);
        return true;
    }

   
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract MooToken is MintableToken {
   
    string public name = "MOO token";
    string public symbol = "XMOO";
    uint256 public decimals = 18;

    event EmergencyERC20DrainWasCalled(address tokenaddress, uint256 _amount);

   
    bool public tradingStarted = false;

   
    modifier hasStartedTrading() {
        require(tradingStarted);
        _;
    }

   
    function startTrading() public onlyOwner returns(bool) {
        require(!tradingStarted);
        tradingStarted = true;
        return true;
    }

   
    function transfer(address _to, uint _value) hasStartedTrading public returns (bool) {
        return super.transfer(_to, _value);
    }

   
    function transferFrom(address _from, address _to, uint _value) hasStartedTrading public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function emergencyERC20Drain( ERC20 oddToken, uint amount ) public onlyOwner returns(bool){
        oddToken.transfer(owner, amount);
        EmergencyERC20DrainWasCalled(oddToken, amount);
        return true;
    }

    function isOwner(address _owner) public view returns(bool){
        if (owner == _owner) {
            return true;    
    } else {
            return false;    
    } 
    }
}


contract MooTokenSale is Ownable {
    using SafeMath for uint256;

   
    MooToken public token;
    uint256 public decimals;
    uint256 public oneCoin;

   
    uint256 public PRESALE_STARTTIMESTAMP;
    uint256 public PRESALE_ENDTIMESTAMP;

   
    uint256 public PUBLICSALE_STARTTIMESTAMP;
    uint256 public PUBLICSALE_ENDTIMESTAMP;

   
    address public multiSig;

    function setWallet(address _newWallet) public onlyOwner returns (bool) {
        multiSig = _newWallet;
        WalletUpdated(_newWallet);
        return true;
    } 

    uint256 rate;  
    uint256 public minContribution = 0.0001 ether;   
    uint256 public maxContribution = 1000 ether;
    uint256 public tokensOfTeamAndAdvisors;

   
    uint256 public weiRaised;

   
    uint256 public tokenRaised;

   
    uint256 public maxTokens;

   
    uint256 public tokensForSale;  
   
   

   
    uint256 public numberOfContributors = 0;

   
    address public cs;
   
    address public Admin;

   
    uint public basicRate;

   
    uint public maxTokenCap;
   
    bool public suspended;
 

    mapping (address => bool) public authorised;  
    mapping (address => uint) adminCallMintToTeamCount;  

    event TokenPurchase(address indexed purchaser, uint256 amount, uint256 _tokens);
    event TokenPlaced(address indexed beneficiary, uint256 _tokens);
    event SaleClosed();
    event TradingStarted();
    event Closed();
    event AdminUpdated(address newAdminAddress);
    event CsUpdated(address newCSAddress);
    event EmergencyERC20DrainWasCalled(address tokenaddress, uint256 _amount);
    event AuthoriseStatusUpdated(address accounts, bool status);
    event SaleResumed();
    event SaleSuspended();
    event WalletUpdated(address newwallet);
   

    function MooTokenSale() public {
        PRESALE_STARTTIMESTAMP = 1516896000;
         
        PRESALE_ENDTIMESTAMP = 1522209600;
         
        PUBLICSALE_STARTTIMESTAMP = 1522382400;
         
        PUBLICSALE_ENDTIMESTAMP = 1525060800; 
         
      
        multiSig = 0x90420B8aef42F856a0AFB4FFBfaA57405FB190f3;
   
        token = new MooToken();
        decimals = token.decimals();
        oneCoin = 10 ** decimals;
        maxTokens = 500 * (10**6) * oneCoin;
        tokensForSale = 200260050 * oneCoin;  
        basicRate = 1800;
        rate = basicRate;
        tokensOfTeamAndAdvisors = 99739950 * oneCoin;   
        maxTokenCap = basicRate * maxContribution * 11/10;
        suspended = false;
    }


    function currentTime() public constant returns (uint256) {
        return now;
    }

     
    function getCurrentRate() public view returns (uint256) {
    
        if (currentTime() <= PRESALE_ENDTIMESTAMP) {
            return basicRate * 5/4;
        }

        if (tokenRaised <= 10000000 * oneCoin) {
            return basicRate * 11/10;
    } else if (tokenRaised <= 20000000 * oneCoin) {
        return basicRate * 1075/1000;
    } else if (tokenRaised <= 30000000 * oneCoin) {
        return basicRate * 105/100;
    } else {
        return basicRate ;
    }
    }


   
    function hasEnded() public constant returns (bool) {
        if (currentTime() > PUBLICSALE_ENDTIMESTAMP)
            return true;  
        if (tokenRaised >= tokensForSale)
            return true;  
        return false;
    }

 
    function suspend() external onlyAdmin returns(bool) {
        if (suspended == true) {
            return false;
        }
        suspended = true;
        SaleSuspended();
        return true;
    }


 
    function resume() external onlyAdmin returns(bool) {
        if (suspended == false) {
            return false;
        }
        suspended = false;
        SaleResumed();
        return true;
    }

  
   
    modifier onlyCSorAdmin() {
        require((msg.sender == Admin) || (msg.sender==cs));
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == Admin);
        _;
    }

   
    modifier onlyAuthorised() {
        require (authorised[msg.sender]);
        require ((currentTime() >= PRESALE_STARTTIMESTAMP && currentTime() <= PRESALE_ENDTIMESTAMP ) || (currentTime() >= PUBLICSALE_STARTTIMESTAMP && currentTime() <= PUBLICSALE_ENDTIMESTAMP ));
        require (!(hasEnded()));
        require (multiSig != 0x0);
        require (msg.value > 1 finney);
        require(!suspended);
        require(tokensForSale > tokenRaised);  
        _;
    }

   
    function authoriseAccount(address whom) onlyCSorAdmin public returns(bool) {
        require(whom != address(0));
        require(whom != address(this));
        authorised[whom] = true;
        AuthoriseStatusUpdated(whom, true);
        return true;
    }

   
    function authoriseManyAccounts(address[] many) onlyCSorAdmin public returns(bool) {
        require(many.length > 0);  
        for (uint256 i = 0; i < many.length; i++) {
            require(many[i] != address(0));
            require(many[i] != address(this));  
            authorised[many[i]] = true;
            AuthoriseStatusUpdated(many[i], true);
        }
        return true;            
    }

   
    function blockAccount(address whom) onlyCSorAdmin public returns(bool){
        require(whom != address(0));
        require(whom != address(this));
        authorised[whom] = false;
        AuthoriseStatusUpdated(whom, false);
        return true;
    }

   
    function setCS(address newCS) onlyOwner public returns (bool){
        require(newCS != address(0));
        require(newCS != address(this));
        require(newCS != owner);  
        cs = newCS;
        CsUpdated(newCS);
        return true;
    }

   
    function setAdmin(address newAdmin) onlyOwner public returns (bool) {
        require(newAdmin != address(0));
        require(newAdmin != address(this));
        require(newAdmin != owner);  
        Admin = newAdmin;
        AdminUpdated(newAdmin);
        return true;
    }

   
    function setBasicRate(uint newRate) onlyAdmin public returns (bool){
        require(0 < newRate && newRate < 5000);
        basicRate = newRate;
        return true;
    }

    function setMaxTokenCap(uint _newMaxTokenCap) onlyAdmin public returns (bool){
        require(0 < _newMaxTokenCap && _newMaxTokenCap < tokensForSale);
        maxTokenCap = _newMaxTokenCap;
        return true;
    }
  
    function isOwner(address _owner) public view returns(bool){
        if (owner == _owner) {
            return true;    
    } else {
            return false;    
    } 
    }
  
    function isAdmin(address _admin) public view returns(bool){
        if (Admin == _admin) {
            return true;    
    } else {
            return false;    
    } 
    }

    function isCS(address _cs) public view returns(bool){
        if (cs == _cs) {
            return true;    
    } else {
            return false;    
    } 
    }

 
    function placeTokens(address beneficiary, uint256 _tokens) onlyAdmin public returns(bool){

     
        require(tokenRaised.add(_tokens) <= tokensForSale);  
     

        require(_tokens != 0);
        require(!hasEnded());
        if (token.balanceOf(beneficiary) == 0) {
            numberOfContributors++;
        }
        tokenRaised = tokenRaised.add(_tokens);  
        token.mint(beneficiary, _tokens);
        TokenPlaced(beneficiary, _tokens);
        return true;
    }

   
    function buyTokens(address beneficiary, uint256 amount) onlyAuthorised internal returns (bool){
      
        rate = getCurrentRate();
       
        if (currentTime() <= PRESALE_ENDTIMESTAMP) {
            minContribution = 50 ether;
            maxContribution = 1000 ether;
     
    } else {
            minContribution = 0.2 ether;
            maxContribution = 20 ether;
        }

     
        require(msg.value >= minContribution);
        require(msg.value <= maxContribution);
    
     
        uint256 tokens = amount.mul(rate);
   
   
     
        require(tokenRaised.add(tokens) <= tokensForSale);  
     
        require(token.balanceOf(beneficiary) + tokens <= maxTokenCap);  
     


     
        weiRaised = weiRaised.add(amount);
        if (token.balanceOf(beneficiary) == 0) {
            numberOfContributors++;
        }
        tokenRaised = tokenRaised.add(tokens);  
        token.mint(beneficiary, tokens);
        TokenPurchase(beneficiary, amount, tokens);
        multiSig.transfer(this.balance);  
        return true;
    }

   
    function finishSale() public onlyOwner {
        require(hasEnded());
     
        uint unassigned;    
        if(tokensForSale > tokenRaised) {
            unassigned = tokensForSale.sub(tokenRaised);
            tokenRaised = tokenRaised.add(unassigned);
            token.mint(multiSig,unassigned);
            TokenPlaced(multiSig,unassigned);
    }
        SaleClosed();
        token.startTrading(); 
        TradingStarted();
     
    }
 
 
    function mintToTeamAndAdvisors() public onlyAdmin {
        require(hasEnded());
        require(adminCallMintToTeamCount[msg.sender] == 0);  
        require(1535644800 <= currentTime() && currentTime() <= 1535731200);   
       
       
        adminCallMintToTeamCount[msg.sender]++; 
        tokenRaised = tokenRaised.add(tokensOfTeamAndAdvisors);
        token.mint(multiSig,tokensOfTeamAndAdvisors);
        TokenPlaced(multiSig, tokensOfTeamAndAdvisors);
    }
   
    function afterSaleMinting(uint _tokens) public onlyAdmin {
        require(hasEnded());
        uint limit = maxTokens.sub(tokensOfTeamAndAdvisors); 
      
        require(tokenRaised.add(_tokens) <= limit);  
        tokenRaised = tokenRaised.add(_tokens);
        token.mint(multiSig,_tokens);
        TokenPlaced(multiSig, _tokens);
    }  
 
    function close() public onlyOwner {
        require(1535731200 <= currentTime());   
        uint unassigned;
        if( maxTokens > tokenRaised) {
            unassigned = maxTokens.sub(tokenRaised);
            tokenRaised = tokenRaised.add(unassigned);
            token.mint(multiSig,unassigned);
            TokenPlaced(multiSig,unassigned);
            multiSig.transfer(this.balance);  
        }
        token.finishMinting();
        token.transferOwnership(owner);
        Closed();
    }
 


   
    function () public payable {
        buyTokens(msg.sender, msg.value);
    }

   
    function emergencyERC20Drain( ERC20 oddToken, uint amount ) public onlyCSorAdmin returns(bool){
        oddToken.transfer(owner, amount);
        EmergencyERC20DrainWasCalled(oddToken, amount);
        return true;
    }

}