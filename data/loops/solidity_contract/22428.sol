pragma solidity 0.4.21;
contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
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

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

     
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

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract BBTCToken is StandardToken, Owned {

     

     
    string public constant name = "BloxOffice token";
     
    string public constant symbol = "BBTC";
     
    uint8 public constant decimals = 18;

    bool public tokenSaleClosed = false;



     

     
    address public _fundowner = 0x761cE04C269314fAfCC545301414BfDA21539A75;

     
    address public _devteam = 0xb3871355181558059fB22ae7AfAd415499ae6f1E;

     
    address public _mentors = 0x589789B67aE612f47503E80ED14A18593C1C79BE;

     
    address public _bounty = 0x923A03dE5816CCB29684F6D420e774d721Ac6962;

     
    address public _privateSale = 0x90aBD12D92c0E5f5BcD2195ee3C6C15026506B96;

     

     
    uint256 public totalSupply = 999999999 * 10**uint256(decimals);

     
    uint256 public TOKENS_SALE_HARD_CAP = 669999999 * 10**uint256(decimals);

     
    uint256 public DEV_TEAM = 160000000 * 10**uint256(decimals);

     
    uint256 public MENTORS = 80000000 * 10**uint256(decimals);

     
    uint256 public BOUNTY = 20000000 * 10**uint256(decimals);

     
    uint256 public PRIVATE = 70000000 * 10**uint256(decimals);

     
    uint256 public currentSupply;


     
     
    uint64 private constant privateSaleDate = 1519756200;

     
    uint64 private constant presaleStartDate = 1523730600;
     
    uint64 private constant presaleEndDate = 1526408999;


     
    uint64 private constant crowdSaleStart = 1526927400;
     
    uint64 private constant crowdSaleEnd = 1530901799;


     
    uint256 public constant BASE_RATE = 2500;

     
    function BBTCToken(){
       
       
      balances[_devteam] = DEV_TEAM;

       
      balances[_mentors] = MENTORS;

       
      balances[_bounty] = BOUNTY;

       
      balances[_privateSale] = PRIVATE;

    }

     
    function startSale () public onlyOwner{
      tokenSaleClosed = false;
    }

     
    function stopSale () public onlyOwner {
      tokenSaleClosed = true;
    }

     
      function saleDue() public view returns (bool) {
          return crowdSaleEnd < uint64(block.timestamp);
      }

    modifier inProgress {
        require(currentSupply < TOKENS_SALE_HARD_CAP
                && !tokenSaleClosed
                && !saleDue());
        _;
    }

     
     
    function () public payable {
        purchaseTokens(msg.sender);
    }

     
     
    function purchaseTokens(address _beneficiary) internal inProgress {

        uint256 tokens = computeTokenAmount(msg.value);

        balances[_beneficiary] = balances[_beneficiary].add(tokens);

         
        _fundowner.transfer(msg.value);
    }


     
     
     
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
         
        uint64 discountPercentage = currentTierDiscountPercentage();

        uint256 tokenBase = ethAmount.mul(BASE_RATE);
        uint256 tokenBonus = tokenBase.mul(discountPercentage).div(100);

        tokens = tokenBase.add(tokenBonus);
    }


     
       
      function currentTierDiscountPercentage() internal view returns (uint64) {
          uint64 _now = uint64(block.timestamp);

          if(_now > crowdSaleStart) return 0;
          if(_now > presaleStartDate) return 10;
          if(_now > privateSaleDate) return 15;
          return 0;
      }

     
     
     
    function doIssueTokens(address _beneficiary, uint256 _tokensAmount) public {
        require(_beneficiary != address(0));

         
        uint256 increasedTotalSupply = currentSupply.add(_tokensAmount);
         
        require(increasedTotalSupply <= TOKENS_SALE_HARD_CAP);

         
          currentSupply = increasedTotalSupply;
         
        balances[_beneficiary] = balances[_beneficiary].add(_tokensAmount);
    }


     
    function price() public view returns (uint256 tokens) {
      return computeTokenAmount(1 ether);
    }
  }