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


contract ERC20 {
     

    string public NAME;
    string public SYMBOL;
    uint8 public DECIMALS = 18;  

     
    uint private TOTALSUPPLY;

     
    mapping(address => uint256) balances;

     
     
     
    mapping(address => mapping (address => uint256)) allowed;

                  
     
     
     
    function totalSupply() public constant returns (uint256 _totalSupply);

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

             
     
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
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


contract Bitcub is Ownable, ERC20 {
    using SafeMath for uint256;

    string public constant NAME = "Bitcub";
    string public constant SYMBOL = "BCU";
    uint8 public constant DECIMALS = 18;  

     
    uint private constant TOTALSUPPLY = 500000000*(10**18);

     
    mapping(address => uint256) balances;

     
     
     
    mapping(address => mapping (address => uint256)) allowed;

     
    constructor() public {
         
        Ownable(msg.sender);

         
        balances[0xaf0A558783E92a1aEC9dd2D10f2Dc9b9AF371212] = 150000000*(10**18);
         
        emit Transfer(address(0), 0xaf0A558783E92a1aEC9dd2D10f2Dc9b9AF371212, 150000000*(10**18));

         
        balances[msg.sender] = TOTALSUPPLY.sub(150000000*(10**18)); 
         
        emit Transfer(address(0), msg.sender, TOTALSUPPLY.sub(150000000*(10**18)));
    }

                  
     
     
    function totalSupply() public constant returns (uint256 _totalSupply) {
         
        _totalSupply = TOTALSUPPLY;
    }

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));  
        require(_value <= balances[msg.sender]);  
        require(_value>0); 

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
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

               
     
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

}


 
 
contract BitcubCrowdsale is Ownable {
    using SafeMath for uint256;

     
    Bitcub public token;

     
    uint256 remainingTokens = 350000000 *(10**18);

     
    uint256 public startTime;
    uint256 public endTime;
    uint256 public tier1Start;
    uint256 public tier1End;
    uint256 public tier2Start;
    uint256 public tier2End;

     
    address public etherWallet;
     
    address public tokenWallet;

     
    uint256 public rate = 100;

     
    uint256 public weiRaised;

     
    uint256 public minPurchaseInEth = 0.01 ether;
  
     
     
    uint256 public maxInvestment = 250000 ether;
  
     
    mapping (address => uint256) internal invested;


     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    constructor() public {
         
        startTime = now ;
        tier1Start = startTime ;
        tier1End = 1528416000 ;  
        tier2Start = tier1End;
        tier2End = 1532131200 ;  
        endTime = 1538265600 ;  
        etherWallet = 0xaf0A558783E92a1aEC9dd2D10f2Dc9b9AF371212;
        tokenWallet = 0xaf0A558783E92a1aEC9dd2D10f2Dc9b9AF371212;

        require(startTime >= now);
        require(endTime >= startTime);
        require(etherWallet != address(0));

         
        Ownable(msg.sender);

         
        token = createTokenContract();
    }

    function createTokenContract() internal returns (Bitcub) {
       
       
        return new Bitcub();
    }

     
     
    function () external payable {
         
        buyTokens(msg.sender);
    }

     
    function finalizeCrowdsale() public onlyOwner returns (bool) {
        require(hasEnded());
        require(token.transfer(tokenWallet, remainingTokens));
        return true;
    }

     
     
    function buyTokens(address beneficiary) public payable {
         
        require(beneficiary != address(0));
         
        require(validPurchase(beneficiary));

        uint256 weiAmount = msg.value;

         
        uint256 tokens = getTokenAmount(weiAmount);

         
        require(weiAmount >= minPurchaseInEth); 

         
        require(token.transfer(beneficiary, tokens));

         
         
        weiRaised = weiRaised.add(weiAmount);
         
        remainingTokens = remainingTokens.sub(tokens);
         
        invested[beneficiary] = invested[beneficiary].add(msg.value);

        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

         
        forwardFunds();
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

     
    function getTokenAmount(uint256 weiAmount) internal returns(uint256) {
         
         
         
        if (now>=tier1Start && now < tier1End) {
            rate = 120;
        }else if (now>=tier2Start && now < tier2End) {
            rate = 110;
        }else {
            rate = 100;
        }

        return weiAmount.mul(rate);
    }

     
     
    function forwardFunds() internal {
        etherWallet.transfer(msg.value);
    }

     
    function validPurchase(address beneficiary) internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool withinMaxInvestment = ( invested[beneficiary].add(msg.value) <= maxInvestment );

        return withinPeriod && nonZeroPurchase && withinMaxInvestment;
    }

}