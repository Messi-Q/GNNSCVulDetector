pragma solidity ^0.4.19;

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

contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
 }

   
  function transferOwnership(address newOwner) public onlyOwner {
      owner = newOwner;
  }
 
}
  
contract ERC20 {

    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public;
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract RAOToken is Ownable, ERC20 {

    using SafeMath for uint256;

     
    string public name = "RadioYo Coin";
    string public symbol = "RAO";
    uint256 public decimals = 18;
    uint256 public numberDecimal18 = 1000000000000000000;

    uint256 public initialPrice = 3000e18;
    uint256 public _totalSupply = 33000000e18;
    uint256 public _icoSupply = 33000000e18;
    uint256 public _softcap = 165000e18;

     
    mapping (address => uint256) balances;

     
    mapping (address => bool) whitelist;

     
    mapping (address => uint256) vault;
    
    
     
    mapping (address => uint256) balancesWaitingKYC;

     
    mapping (address => mapping(address => uint256)) allowed;
    
     
    uint256 public startTime; 
    uint256 public endTime; 
    uint256 public sealdate;

     
    address public multisig;

     
    uint256 public RATE;

    uint256 public kycLevel = 15 ether;


    uint256 public hardCap = 200000000e18;
    
     
    uint256 public totalNumberTokenSold=0;

    bool public mintingFinished = false;

    bool public tradable = true;

    bool public active = true;

    event MintFinished();
    event StartTradable();
    event PauseTradable();
    event HaltTokenAllOperation();
    event ResumeTokenAllOperation();
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Burn(address indexed burner, uint256 value);


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier canTradable() {
        require(tradable);
        _;
    }

    modifier isActive() {
        require(active);
        _;
    }
    
    modifier saleIsOpen(){
        require(startTime <= getNow() && getNow() <= endTime);
        _;
    }

     
     
     
    function RAOToken(address _multisig) public {
        require(_multisig != 0x0);
        multisig = _multisig;
        RATE = initialPrice;
        startTime = now;

         
        sealdate = startTime + 180 days;

         
        endTime = startTime + 60 days;
        balances[multisig] = _totalSupply;

        owner = msg.sender;
    }

     
     
    function () external payable {
        
        if (!validPurchase()) {
            refundFunds(msg.sender);
        }
        
        tokensale(msg.sender);
    }

    function whitelisted(address user) public constant returns (bool) {
        return whitelist[user];
    }

     
     
     
    function tokensale(address recipient) internal canMint isActive saleIsOpen {
        require(recipient != 0x0);
        require(whitelisted(recipient));
        
        uint256 weiAmount = msg.value;
        uint256 numberRaoToken = weiAmount.mul(RATE).div(1 ether);
        
        require(_icoSupply >= numberRaoToken);   
                
        totalNumberTokenSold = totalNumberTokenSold.add(numberRaoToken);

        _icoSupply = _icoSupply.sub(numberRaoToken);

        TokenPurchase(msg.sender, recipient, weiAmount, numberRaoToken);

         if (weiAmount < kycLevel) {
            updateBalances(recipient, numberRaoToken);
         } else {
            balancesWaitingKYC[recipient] = balancesWaitingKYC[recipient].add(numberRaoToken); 
         }
        forwardFunds();
         
        setWhitelistStatus(recipient, false);
         
    }
    
    function updateBalances(address receiver, uint256 tokens) internal {
        balances[multisig] = balances[multisig].sub(tokens);
        balances[receiver] = balances[receiver].add(tokens);
    }
    
     
     function refundFunds(address origin) internal {
        origin.transfer(msg.value);
    }

     
     
    function forwardFunds() internal {
        multisig.transfer(msg.value);
    }

    function setWhitelistStatus(address user,bool status) public returns (bool) {
        if (status == true) {
             
            require(msg.sender == owner);
            whitelist[user] = true;        
        } else {
             
            require(msg.sender == owner || msg.sender == user);
            whitelist[user] = false;
        }
        return whitelist[user];
    }
    
    function setWhitelistForBulk(address[] listAddresses, bool status) public onlyOwner {
        for (uint256 i = 0; i < listAddresses.length; i++) {
            whitelist[listAddresses[i]] = status;
        }
    }
    
     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = getNow() >= startTime && getNow() <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool notReachedHardCap = hardCap >= totalNumberTokenSold;
        return withinPeriod && nonZeroPurchase && notReachedHardCap;
    }

     
    function hasEnded() public constant returns (bool) {
        return getNow() > endTime;
    }

    function getNow() public constant returns (uint) {
        return now;
    }

     
    function changeMultiSignatureWallet (address _multisig) public onlyOwner isActive {
        multisig = _multisig;
    }

     
    function changeTokenRate(uint _tokenPrice) public onlyOwner isActive {
        RATE = _tokenPrice;
    }

     
    function finishMinting() public onlyOwner isActive {
        mintingFinished = true;
        MintFinished();
    }



     
    function startTradable(bool _tradable) public onlyOwner isActive {
        tradable = _tradable;
        if (tradable)
            StartTradable();
        else
            PauseTradable();
    }

     
    function updateICODate(uint256 _startTime, uint256 _endTime) public onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
    }
    
     
    function changeStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

     
    function changeEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

     
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
     
    function totalNumberTokenSold() public constant returns (uint256) {
        return totalNumberTokenSold;
    }


     
    function changeTotalSupply(uint256 newSupply) public onlyOwner {
        _totalSupply = newSupply;
    }


     
     
     
    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }


    function vaultBalanceOf(address who) public constant returns (uint256) {
        return vault[who];
    }

    function transferToVault(address recipient, uint256 amount) public onlyOwner isActive {
        require (
            balances[multisig] >= amount && amount > 0
        );

        balances[multisig] = balances[multisig].sub(amount);
         
         
        vault[recipient] = vault[recipient].add(amount);

    }

     
     
     
    function balanceOfKyCToBeApproved(address who) public constant returns (uint256) {
        return balancesWaitingKYC[who];
    }
    

    function approveBalancesWaitingKYC(address[] listAddresses) public onlyOwner {
         for (uint256 i = 0; i < listAddresses.length; i++) {
             address client = listAddresses[i];
             balances[multisig] = balances[multisig].sub(balancesWaitingKYC[client]);
             balances[client] = balances[client].add(balancesWaitingKYC[client]);
             balancesWaitingKYC[client] = 0;
        }
    }

    function remit() public {
        require(vault[msg.sender] > 0 && now >= sealdate);
        balances[msg.sender] = balances[msg.sender].add(vault[msg.sender]);
        vault[msg.sender] = 0;
    }

    function remitFor(address person) public onlyOwner {
        require(vault[person] > 0 && now >= sealdate);
        balances[person] = balances[person].add(vault[person]);
        vault[person] = 0;
    }

    function addTimeToSeal(uint256 time) public onlyOwner {
        sealdate = sealdate.add(time);
    }

    function setSealDate(uint256 _sealdate) public onlyOwner {
        sealdate = _sealdate;
    } 

    function resetTimeSeal() public onlyOwner {
        sealdate = now;
    }

    function getSealDate() public constant returns (uint256) {
        return sealdate;
    }

    
    function modifyCurrentHardCap(uint256 _hardCap) public onlyOwner isActive {
        hardCap = _hardCap;
    }


    function burn(uint256 _value) public {
        require(_value <= balances[multisig]);
        balances[multisig] = balances[multisig].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        Burn(multisig, _value);
        
    }


     
     
     
     
    function transfer(address to, uint256 value) public canTradable isActive {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
    }
    
    function transferToAll(address[] tos, uint256[] values) public onlyOwner canTradable isActive {
        require(
            tos.length == values.length
            );
        
        for(uint256 i = 0; i < tos.length; i++){
        require(_icoSupply >= values[i]);   
        totalNumberTokenSold = totalNumberTokenSold.add(values[i]);
        _icoSupply = _icoSupply.sub(values[i]);
        updateBalances(tos[i],values[i]);
        }
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public canTradable isActive {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
    }

     
     
     
     
     
    function approve(address spender, uint256 value) public isActive {
        require (
            balances[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
    }

     
     
     
     
    function allowance(address _owner, address spender) public constant returns (uint256) {
        return allowed[_owner][spender];
    }

     
     
    function getRate() public constant returns (uint256 result) {
      return RATE;
    }
    
    function getTokenDetail() public constant returns (string, string, uint256, uint256, uint256, uint256, uint256) {
        return (name, symbol, startTime, endTime, _totalSupply, _icoSupply, totalNumberTokenSold);
    }

}