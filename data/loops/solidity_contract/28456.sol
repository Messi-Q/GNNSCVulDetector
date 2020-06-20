pragma solidity ^0.4.18;

 
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


contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
    
}


contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }else {
            return false;
        }
    }
    

     

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
}


     

    function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}

contract ANOToken is BasicToken {

using SafeMath for uint256;

string public name = "Anonium";                                  
string public symbol = "ANO";                                    
uint8 public decimals = 18;                                      
uint256 public totalSupply = 21000000000 * 10**18;               

 
uint256 public tokensAllocatedToCrowdFund;                       
uint256 public totalAllocatedTokens;                             

 
address public crowdFundAddress;                                 
address public founderMultiSigAddress;                           

 
event ChangeFoundersWalletAddress(uint256  _blockTimeStamp, address indexed _foundersWalletAddress);

 

  modifier onlyCrowdFundAddress() {
    require(msg.sender == crowdFundAddress);
    _;
  }

  modifier nonZeroAddress(address _to) {
    require(_to != 0x0);
    _;
  }

  modifier onlyFounders() {
    require(msg.sender == founderMultiSigAddress);
    _;
  }


  
    
   function ANOToken (address _crowdFundAddress) public {
    crowdFundAddress = _crowdFundAddress;
    founderMultiSigAddress = msg.sender;

    tokensAllocatedToCrowdFund = totalSupply;                    

     
    balances[crowdFundAddress] = tokensAllocatedToCrowdFund;
  
  }

 
  function changeSupply(uint256 _amount) public onlyCrowdFundAddress {
    totalAllocatedTokens += _amount;
  }

 
  function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) public onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
    founderMultiSigAddress = _newFounderMultiSigAddress;
    ChangeFoundersWalletAddress(now, founderMultiSigAddress);
  }

   

  function burnToken() public onlyCrowdFundAddress returns (bool) {
    totalSupply = totalSupply.sub(balances[msg.sender]);
    balances[msg.sender] = 0;
    return true;
  }

}

contract ANOCrowdsale {

using SafeMath for uint256;

ANOToken token;                                                   

uint256 public startDate;                                         
uint256 public endDate;                                           
uint256 private weekNo = 0;                                        
uint256 public allocatedToken = 21000000000 * 10 ** 18;           
uint256 private tokenAllocatedForWeek;                            
uint256 private tokenSoldForWeek;                                 
uint256 public ethRaised;                                         
uint32 public tokenRate = 6078;                                   
uint32 public appreciationRate = 1216;                            
bool private isTokenSet = false;                                  

address public founderAddress;                                    
address public beneficiaryAddress;                                

 
struct weeklyData {
    uint256 startTime;
    uint256 endTime;
    uint32 weekRate;
}

 
mapping(uint256 => weeklyData) public weeklyRate;

 
event LogWeekRate(uint32 _weekRate, uint256 _timestamp);

 
modifier isBetween() {
    require(now >= startDate && now <= endDate);
    _;
}

 
modifier onlyFounder() {
    require(msg.sender == founderAddress);
    _;
}

 
event TokenBought(address indexed _investor, uint256 _tokenQuantity);

 

function () public payable {
    buyTokens(msg.sender);
}

 

function setWeeklyRate() private returns (bool) {
    for (uint32 i = 0; i < 40; ++i) {
        uint32 weekRate = tokenRate + appreciationRate * i;
        uint256 weekStartTime = now + i * 1 weeks;
        uint256 weekEndTime = now + (i+1) * 1 weeks;
        weeklyRate[i] = weeklyData(weekStartTime, weekEndTime, weekRate);
    }
    return true;
}

 

function getWeeklyRate() private returns (uint32) {
   if (now <= weeklyRate[weekNo].endTime && now >= weeklyRate[weekNo].startTime) {
       return weeklyRate[weekNo].weekRate;
   } if (now <= weeklyRate[weekNo + 1].endTime && now >= weeklyRate[weekNo + 1].startTime ) {
        weekNo = weekNo + 1;
        setWeeklyAllocation();
        return weeklyRate[weekNo + 1].weekRate;
   } else {
       uint256 increasedBy = now - startDate;
       uint256 weekIncreasedBy = increasedBy.div(604800);     
       setWeeklyAllocation();
       weekNo = weekNo.add(weekIncreasedBy);
       LogWeekRate(weeklyRate[weekNo].weekRate, now);
       return weeklyRate[weekNo].weekRate;
   }
}

 
function fundTransfer(uint256 weiAmount) internal {
        beneficiaryAddress.transfer(weiAmount);
    }

 
function setWeeklyAllocation() private {
    tokenAllocatedForWeek = (tokenAllocatedForWeek + (tokenAllocatedForWeek - tokenSoldForWeek)).div(2);
    tokenSoldForWeek = 0;
}

 

function ANOCrowdsale (address _founderAddress, address _beneficiaryAddress) public {
    startDate = now;
    endDate = now + 40 weeks;
    founderAddress = _founderAddress;
    beneficiaryAddress = _beneficiaryAddress;
    require(setWeeklyRate());
    tokenAllocatedForWeek = allocatedToken.div(2);
}

 

function setTokenAddress (address _tokenAddress) public onlyFounder returns (bool) {
    require(isTokenSet == false);
    token = ANOToken(_tokenAddress);
    isTokenSet = !isTokenSet;
    return true;
}

 

function buyTokens(address _investor) 
public 
isBetween
payable
returns (bool) 
{
   require(isTokenSet == true);
   require(_investor != address(0));
   uint256 rate = uint256(getWeeklyRate());
   uint256 tokenAmount = (msg.value.div(rate)).mul(10 ** 8);
   require(tokenAllocatedForWeek >= tokenSoldForWeek + tokenAmount);
   fundTransfer(msg.value);
   require(token.transfer(_investor, tokenAmount));
   tokenSoldForWeek = tokenSoldForWeek.add(tokenAmount);
   token.changeSupply(tokenAmount);
   ethRaised = ethRaised.add(msg.value);
   TokenBought(_investor, tokenAmount);
   return true;
}

 

function getWeekNo() public view returns (uint256) {
    return weekNo;
}

 

function endCrowdfund() public onlyFounder returns (bool) {
    require(isTokenSet == true);
    require(now > endDate);
    require(token.burnToken());
    return true;
}

}