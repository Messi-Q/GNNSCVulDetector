pragma solidity ^0.4.24;

 

 
 
library SafeMath 
{
  function mul(uint256 a, uint256 b) internal pure returns (uint256) 
  {
      if (a==0)
      {
          return 0;
      }
      
    uint256 c = a * b;
    assert(c / a == b);  
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) 
  {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256)
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic
{
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic
{
     
    address public constant FOUNDER_ADDRESS1 = 0xcb8Fb8Bf927e748c0679375B26fb9f2F12f3D5eE;
    address public constant FOUNDER_ADDRESS2 = 0x1Ebfe7c17a22E223965f7B80c02D3d2805DFbE5F;
    address public constant FOUNDER_ADDRESS3 = 0x9C5076C3e95C0421699A6D9d66a219BF5Ba5D826;
    
    address public constant FOUNDER_FUND_1 = 9000000000;
    address public constant FOUNDER_FUND_2 = 9000000000;
    address public constant FOUNDER_FUND_3 = 7000000000;
    
     
    address public constant MEW_RESERVE_FUND = 0xD11ffBea1cE043a8d8dDDb85F258b1b164AF3da4;  
    address public constant MEW_CROWDSALE_FUND = 0x842C4EA879050742b42c8b2E43f1C558AD0d1741;  
    
    uint256 public constant decimals = 18;
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  
   
  mapping(address => uint256) public mCanSpend;
  mapping(address => uint256) public mEtherSpent;
  
  int256 public mEtherValid;
  int256 public mEtherInvalid;
  
   
   
   
  uint256 public constant TOTAL_RESERVE_FUND =  40 * (10**9) * 10**decimals;   
  uint256 public constant TOTAL_CROWDSALE_FUND =  60 * (10**9) * 10**decimals;   
  uint256 public PRIME_VESTING_DATE = 0xffffffffffffffff;  
  uint256 public FINAL_AML_DATE = 0xffffffffffffffff;  
  uint256 public constant FINAL_AML_DAYS = 90;
  uint256 public constant DAYSECONDS = 24*60*60; 
  
  mapping(address => uint256) public mVestingDays;   
  mapping(address => uint256) public mVestingBalance;  
  mapping(address => uint256) public mVestingSpent;  
  mapping(address => uint256) public mVestingBegins;  
  
  mapping(address => uint256) public mVestingAllowed;  
  
   
  function GetEtherSpent(address from) view public returns (uint256)
  {
      return mEtherSpent[from];
  }
  
   
   
  function RevokeTokens(address target) internal
  {
       
       
      require(mCanSpend[target]!=9);
      mCanSpend[target]=9;
      
      uint256 _value = balances[target];
      
      balances[target] = 0; 
      
      balances[MEW_RESERVE_FUND] = balances[MEW_RESERVE_FUND].add(_value);
      
       
      emit Transfer(target, MEW_RESERVE_FUND, _value);
  }
  
  function LockedCrowdSale(address target) view internal returns (bool)
  {
      if (mCanSpend[target]==0 && mEtherSpent[target]>0)
      {
          return true;
      }
      return false;
  }
  
  function CheckRevoke(address target) internal returns (bool)
  {
       
       
       
      if (LockedCrowdSale(target))
      {
         if (block.timestamp>FINAL_AML_DATE)
         {
             RevokeTokens(target);
             return true;
         }
      }
      
      return false;
  }
  
  function ComputeVestSpend(address target) public returns (uint256)
  {
      require(mCanSpend[target]==2);  
      int256 vestingDays = int256(mVestingDays[target]);
      int256 vestingProgress = (int256(block.timestamp)-int256(mVestingBegins[target]))/(int256(DAYSECONDS));
      
       
      if (vestingProgress>vestingDays)
      {
          vestingProgress=vestingDays;
      }
          
       
      if (vestingProgress>0)
      {
              
        int256 allowedVest = ((int256(mVestingBalance[target])*vestingProgress))/vestingDays;
                  
        int256 combined = allowedVest-int256(mVestingSpent[target]);
        
         
        mVestingAllowed[target] = uint256(combined);
        
        return uint256(combined);
      }
      
       
      mVestingAllowed[target]=0;
      
       
      return 0;
  }
  
   
   
   
  function canSpend(address from, uint256 amount) internal returns (bool permitted)
  {
      uint256 currentTime = block.timestamp;
      
       
      if (mCanSpend[from]==8)
      {
          return false;
      }
      
       
      if (mCanSpend[from]==9)
      {
          return false;
      }
      
       
       
      if (LockedCrowdSale(from))
      {
          return false;
      }
      
      if (mCanSpend[from]==1)
      {
           
          if (currentTime>PRIME_VESTING_DATE)
          {
             return true;
          }
          return false;
      }
      
       
      if (mCanSpend[from]==2)
      {
              
        if (ComputeVestSpend(from)>=amount)
            {
              return true;
            }
            else
            {
              return false;   
            }
      }
      
      return false;
  }
  
    
   
   
  function canTake(address from) view public returns (bool permitted)
  {
      uint256 currentTime = block.timestamp;
      
       
      if (mCanSpend[from]==8)
      {
          return false;
      }
      
       
      if (mCanSpend[from]==9)
      {
          return false;
      }
      
       
       
      if (LockedCrowdSale(from))
      {
          return false;
      }
      
      if (mCanSpend[from]==1)
      {
           
          if (currentTime>PRIME_VESTING_DATE)
          {
             return true;
          }
          return false;
      }
      
       
      if (mCanSpend[from]==2)
      {
          return false;
      }
      
      return true;
  }
  

   
  function transfer(address _to, uint256 _value) public returns (bool success) 
  {
        
      if (CheckRevoke(msg.sender)||CheckRevoke(_to))
      {
          return false;
      }
     
    require(canSpend(msg.sender, _value)==true); 
    require(canTake(_to)==true);  
    
    if (balances[msg.sender] >= _value) 
    {
       
       
      if (mCanSpend[msg.sender]==2)
      {
        mVestingSpent[msg.sender] = mVestingSpent[msg.sender].add(_value);
      }
      
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(msg.sender, _to, _value);
      
      
       
      mCanSpend[_to]=1;
      
      return true;
    } 
    else
    {
      return false;
    }
  }
  
   
  function simpletransfer(address _to, uint256 _whole, uint256 _fraction) public returns (bool success) 
  {
    require(_fraction<10000); 
    
    uint256 main = _whole.mul(10**decimals);  
    uint256 part = _fraction.mul(10**14);
    uint256 value = main + part;
    
     
    return transfer(_to, value);
  }

   
  function balanceOf(address _owner) public constant returns (uint256 returnbalance) 
  {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic 
{
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken 
{
   
   
   
   
  mapping (address => mapping (address => uint256)) allowed;

   
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) 
   {
       
      if (CheckRevoke(msg.sender)||CheckRevoke(_to))
      {
          return false;
      }
      
      require(canSpend(_from, _value)== true); 
      require(canTake(_to)==true);  
     
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) 
    {
      balances[_to] = balances[_to].add(_value);
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      emit Transfer(_from, _to, _value);
      
      
       
      mCanSpend[_to]=1;
      
       
      if (mCanSpend[msg.sender]==2)
      {
        mVestingSpent[msg.sender] = mVestingSpent[msg.sender].add(_value);
      }
      return true;
    } 
    else 
    {
      
      return false;
    }
  }
  
   
  function approve(address _spender, uint256 _value) public returns (bool)
  {
       
      if (CheckRevoke(msg.sender))
      {
          return false;
      }
      
      require(canSpend(msg.sender, _value)==true); 
      
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) 
  {
       
      if (CheckRevoke(msg.sender))
      {
          return false;
      }
      require(canSpend(msg.sender, _addedValue)==true); 
      
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success)
  {
       
      if (CheckRevoke(msg.sender))
      {
          return false;
      }
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


 
contract Ownable
{
  address public owner;
  address internal auxOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public
  {
      
        address newOwner = msg.sender;
        owner = 0;
        owner = newOwner;
    
  }


   
  modifier onlyOwner() 
  {
    require(msg.sender == owner || msg.sender==auxOwner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public 
  {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 

contract MintableToken is StandardToken, Ownable
{
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  uint256 internal mCanPurchase = 1;
  uint256 internal mSetupReserve = 0;
  uint256 internal mSetupCrowd = 0;
  
   
  uint256 public constant MINIMUM_ETHER_SPEND = (250 * 10**(decimals-3));
  uint256 public constant MAXIMUM_ETHER_SPEND = 300 * 10**decimals;

   
   
   


  modifier canMint() 
  {
    require(!mintingFinished);
    _;
  }
  
  function allocateVestable(address target, uint256 amount, uint256 vestdays, uint256 vestingdate) public onlyOwner
  {
       
       
       
      
       
      
       
      uint256 vestingAmount = amount * 10**decimals;
    
       
      mCanSpend[target]=2;
      mVestingBalance[target] = vestingAmount;
      mVestingDays[target] = vestdays;
      mVestingBegins[target] = vestingdate;
      mVestingSpent[target] = 0;
      
       
      balances[target] = vestingAmount;
      
       
       
      if (mCanPurchase==0)
      {
        require(vestingAmount <= balances[MEW_CROWDSALE_FUND]); 
        balances[MEW_CROWDSALE_FUND] = balances[MEW_CROWDSALE_FUND].sub(vestingAmount); 
         
        emit Transfer(MEW_CROWDSALE_FUND, target, vestingAmount);
      }
      else
      {
         
        require(vestingAmount <= balances[MEW_RESERVE_FUND]); 
        balances[MEW_RESERVE_FUND] = balances[MEW_RESERVE_FUND].sub(vestingAmount);
         
        emit Transfer(MEW_RESERVE_FUND, target, vestingAmount);
      }
  }
  
  function SetAuxOwner(address aux) onlyOwner public
  {
      require(auxOwner == 0); 
       
      auxOwner = aux;
  }
 
  function Purchase(address _to, uint256 _ether, uint256 _amount, uint256 exchange) onlyOwner public returns (bool) 
  {
    require(mCanSpend[_to]==0);  
    require(mSetupCrowd==1); 
    require(mCanPurchase==1); 
      
    require( _amount >= MINIMUM_ETHER_SPEND * exchange); 
    require( (_amount+balances[_to]) <= MAXIMUM_ETHER_SPEND * exchange); 
   
     
    if (balances[MEW_CROWDSALE_FUND]<_amount)
    {
         return false;
    }

     
    mCanSpend[_to] = 0;
    
     
    if (mCanSpend[_to]==0)
    {
        mEtherInvalid = mEtherInvalid + int256(_ether);
    }
    else
    {
         
        mEtherValid = mEtherValid + int256(_ether);
    }
    
     
    mEtherSpent[_to] = _ether;
      
     
    uint256 newBalance = balances[_to].add(_amount);
    uint256 newCrowdBalance = balances[MEW_CROWDSALE_FUND].sub(_amount);
    
    balances[_to]=0;
    balances[MEW_CROWDSALE_FUND] = 0;
      
     
    balances[_to] = newBalance;
    balances[MEW_CROWDSALE_FUND] = newCrowdBalance;
   
    emit Transfer(MEW_CROWDSALE_FUND, _to, _amount);
    
    return true;
  }
  
  function Unlock_Tokens(address target) public onlyOwner
  {
      
      require(mCanSpend[target]==0); 
      
       
       
      
      mCanSpend[target]=1;
      
      
     
    uint256 etherToken = mEtherSpent[target];
    
     
    mEtherInvalid = mEtherInvalid - int256(etherToken);
    mEtherValid = mEtherValid + int256(etherToken);
    
  }
  
  
  function Revoke(address target) public onlyOwner
  {
       
       
      RevokeTokens(target);
  }
  
  function BlockRefunded(address target) public onlyOwner
  {
      require(mCanSpend[target]!=8);
       
       
      
       
      mCanSpend[target]=8;
      
       
      mEtherInvalid = mEtherInvalid-int256(mEtherSpent[target]);
  }
  
  function SetupReserve(address multiSig) public onlyOwner
  {
      require(mSetupReserve==0); 
      require(multiSig>0); 
      
       
       
      
       
      mint(MEW_RESERVE_FUND, TOTAL_RESERVE_FUND);
     
        
      allocateVestable(FOUNDER_ADDRESS1, 9000000000, 365, PRIME_VESTING_DATE);
      allocateVestable(FOUNDER_ADDRESS2, 9000000000, 365, PRIME_VESTING_DATE);
      allocateVestable(FOUNDER_ADDRESS3, 7000000000, 365, PRIME_VESTING_DATE);
  }
  
  function SetupCrowdSale() public onlyOwner
  {
      require(mSetupCrowd==0); 
       
      mint(MEW_CROWDSALE_FUND, TOTAL_CROWDSALE_FUND);
      
       
      mSetupCrowd=1;
  }
  
  function CloseSaleFund() public onlyOwner
  {
      uint256 remainingFund;
      
      remainingFund = balances[MEW_CROWDSALE_FUND];
      
      balances[MEW_CROWDSALE_FUND] = 0;
      
      balances[MEW_RESERVE_FUND] = balances[MEW_RESERVE_FUND].add(remainingFund);
      
       
      emit Transfer(MEW_CROWDSALE_FUND, MEW_RESERVE_FUND, remainingFund);
      
       
       
      PRIME_VESTING_DATE = block.timestamp;
      FINAL_AML_DATE = PRIME_VESTING_DATE + FINAL_AML_DAYS*DAYSECONDS;
      
       
      mVestingBegins[FOUNDER_ADDRESS1]=PRIME_VESTING_DATE;
      mVestingBegins[FOUNDER_ADDRESS2]=PRIME_VESTING_DATE;
      mVestingBegins[FOUNDER_ADDRESS3]=PRIME_VESTING_DATE;
      
       
      mCanPurchase = 0;
  }
  
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) 
  {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    
     
    mCanSpend[_to] = 1;
    
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) 
  {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract MEWcoin is MintableToken 
{
    string public constant name = "MEWcoin (Official vFloorplan Ltd 30/07/18)";
    string public constant symbol = "MEW";
    string public version = "1.0";
}


contract Crowdsale 
{
    function buyTokens(address _recipient) public payable;
}

contract MultiSig
{
    function () public payable 
    {
       
    }
}

 
 
 
 
contract MEWCrowdsale is Crowdsale 
{
    using SafeMath for uint256;

     
    uint256 public constant decimals = 18;
    uint256 public constant tenthousandths = 14;
    
     
     
    
     
    uint8 internal constant STATE_UNINITIALISED       = 0xff;
    uint8 internal constant STATE_FUND_INITIALISED    = 0;
    uint8 internal constant STATE_PRESALE             = 1;
    uint8 internal constant STATE_PHASEFIRST          = 2;
    uint8 internal constant STATE_PHASESECOND         = 3;
    uint8 internal constant STATE_PHASEFINAL          = 4;
    uint8 internal constant STATE_EXTENSION           = 5;
    uint8 internal constant STATE_SALE_PAUSE          = 99;
    uint8 internal constant STATE_FINISHED            = 10;
    
     
    uint8 public mCURRENT_STATE = STATE_UNINITIALISED;
    
    uint256 public mFUNDING_SALE_TIMESTAMP = 0;                                           
    uint256 public mFUNDING_CURRENT_DURATION = 0;                                         
    uint256 public mFUNDING_BONUS = 0;
    
    uint256 private constant CONST_DAY_SECONDS=60*60*24;
    
    uint256[6] public FUNDING_SALE_DURATION = [0,42,14,14,28,7];   
    uint256[6] public FUNDING_SALE_BONUS = [0,150,125,110,100,100];  
    
    uint256 private mTOKEN_EXCHANGE_RATE = 0;                                     
    uint256 public constant TOTAL_RESERVE_FUND = 40 * 1000000000 * 10**decimals;  
    uint256 public constant TOTAL_TOKEN_SUPPLY = 100 * (10**9) * 10**decimals;    
    uint256 public constant GAS_PRICE_LIMIT = 200 * 10**9;                        
    
     
    uint256 public mPausedTime = 0;
    
    address internal mOwner = 0;
    
     
    uint256 internal constant SIGNING_TIME=900;
    uint256[2] internal signatures;
    address internal newAddress;
    address public mDepositWallet;

     
    event CreateMEW(address indexed _to, uint256 _value);

    MEWcoin public mToken;  
    MultiSig public mMultiSigWallet;  

     
    constructor() public 
    {
        require(mCURRENT_STATE == STATE_UNINITIALISED); 
         
        if (mOwner!=0)
        {
            require (msg.sender == mOwner); 
        }
        
       
      mToken = new MEWcoin();
      mMultiSigWallet = MultiSig(mToken.MEW_RESERVE_FUND());
      mDepositWallet = address(mMultiSigWallet);

       
      require(mOwner == 0); 
      require(address(mToken.MEW_RESERVE_FUND) != 0x0); 
      require(uint256(mToken.decimals()) == decimals); 
      
       
      mOwner = msg.sender;
      
       
      mToken.SetAuxOwner(mOwner);
      
       
      mToken.SetupReserve(mMultiSigWallet);
      mToken.SetupCrowdSale();
      emit CreateMEW(address(mToken.MEW_RESERVE_FUND), mToken.TOTAL_RESERVE_FUND());
      emit CreateMEW(address(mToken.MEW_CROWDSALE_FUND), mToken.TOTAL_CROWDSALE_FUND());
      
       
      mCURRENT_STATE = STATE_FUND_INITIALISED;
      
       
      mToken.finishMinting();
      
    }

     
    function startPRESALE() public 
    {
        require (msg.sender == mOwner); 
        require (mCURRENT_STATE == STATE_FUND_INITIALISED);  
        incSALESTATE();
        
         
         
        
         
         
         
         
        
         
         
    }
    
    function incSALESTATE() public
    {
        require (msg.sender == mOwner); 
        require (mCURRENT_STATE!=STATE_FINISHED); 
        require (mCURRENT_STATE!=STATE_EXTENSION); 
        
         
        if (mCURRENT_STATE >= STATE_FUND_INITIALISED)
        {
             
            mCURRENT_STATE++;
             
            mFUNDING_BONUS = FUNDING_SALE_BONUS[mCURRENT_STATE];
            
             
            mFUNDING_SALE_TIMESTAMP = block.timestamp;
            mFUNDING_CURRENT_DURATION = block.timestamp + FUNDING_SALE_DURATION[mCURRENT_STATE]*CONST_DAY_SECONDS;
            
             
            mTOKEN_EXCHANGE_RATE = 5000*mFUNDING_BONUS;
        }
    }
    
     
    function pauseSALE() public 
    {
        require (msg.sender == mOwner); 
        require (mPausedTime == 0); 
        mPausedTime = mFUNDING_CURRENT_DURATION.sub(block.timestamp);
        mFUNDING_CURRENT_DURATION = 0;
    }
    
    function unpauseSALE() public
    {
        require (mPausedTime !=0); 
        require (msg.sender == mOwner); 
        mFUNDING_CURRENT_DURATION = block.timestamp.add(mPausedTime);
        mPausedTime=0;
    }
    
    function () public payable 
    {
      require( mCURRENT_STATE>=STATE_PRESALE); 
      buyTokens(msg.sender);
     
    }

     
    function buyTokens(address beneficiary) public payable
    {
         
          require (mCURRENT_STATE>=STATE_PRESALE); 
           
          require (block.timestamp >= mFUNDING_SALE_TIMESTAMP); 
          require (block.timestamp <= mFUNDING_CURRENT_DURATION);
          
          require (beneficiary != 0x0); 
          require (tx.gasprice <= GAS_PRICE_LIMIT); 
    
          uint256 tokens = msg.value.mul(mTOKEN_EXCHANGE_RATE);
          
           
          forwardFunds();
          
           
          require(mToken.Purchase(beneficiary, msg.value, tokens, mTOKEN_EXCHANGE_RATE) == true); 
    }

    function finalize() public 
    {
      require (msg.sender == mOwner); 
      require (mCURRENT_STATE!=STATE_FINISHED);
      
       
      mCURRENT_STATE = STATE_FINISHED;
      
      mToken.CloseSaleFund();
    }
    
    function changeWallet(address newWallet) public
    {
        address SIGN_ADDRESS1 = address(0xa5a5f62BfA22b1E42A98Ce00131eA658D5E29B37);
        address SIGN_ADDRESS2 = address(0x9115a6162D6bC3663dC7f4Ea46ad87db6B9CB926);
        
        require (msg.sender == SIGN_ADDRESS1 || msg.sender == SIGN_ADDRESS2); 
        
         
        uint256 blocktime = block.timestamp;
        
         
        if (msg.sender == SIGN_ADDRESS1)
        {
            signatures[0] = blocktime;
        }
        
        if (msg.sender == SIGN_ADDRESS2)
        {
            signatures[1] = blocktime;
            
        }
        
         
        if (newAddress==0)
        {
            newAddress = newWallet;
            return;
        }
        
        uint256 time1=blocktime - signatures[0];
        uint256 time2=blocktime - signatures[1];
        
         
        if ((time1<SIGNING_TIME) && (time2<SIGNING_TIME))
        {
            require(newAddress==newWallet); 
            {
                 
                mDepositWallet = newWallet;
                signatures[0]=0;
                signatures[1]=0;
                newAddress=0;
            }
        }
    }

     
    function forwardFunds() internal
    {
        require(mDepositWallet!=0); 
        
        mDepositWallet.transfer(msg.value);
    }
}