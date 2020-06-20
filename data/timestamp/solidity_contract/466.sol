 
pragma solidity ^0.4.11;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 



 



 



 
library SafeMathLibExt {

  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function divides(uint a, uint b) returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }

}

 





 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    if (halted) throw;
    _;
  }

  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) throw;
    _;
  }

  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

 



 
contract PricingStrategy {

  address public tier;

   
  function isPricingStrategy() public constant returns (bool) {
    return true;
  }

   
  function isSane(address crowdsale) public constant returns (bool) {
    return true;
  }

   
  function isPresalePurchase(address purchaser) public constant returns (bool) {
    return false;
  }

   
  function updateRate(uint newOneTokenInWei) public;

   
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}

 



 
contract FinalizeAgent {

  bool public reservedTokensAreDistributed = false;

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

   
  function isSane() public constant returns (bool);

  function distributeReservedTokens(uint reservedTokensDistributionBatch);

   
  function finalizeCrowdsale();

}
 









 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract FractionalERC20Ext is ERC20 {

  uint public decimals;
  uint public minCap;

}



 
contract CrowdsaleExt is Haltable {

   
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

  using SafeMathLibExt for uint;

   
  FractionalERC20Ext public token;

   
  PricingStrategy public pricingStrategy;

   
  FinalizeAgent public finalizeAgent;

   
  string public name;

   
  address public multisigWallet;

   
  uint public minimumFundingGoal;

   
  uint public startsAt;

   
  uint public endsAt;

   
  uint public tokensSold = 0;

   
  uint public weiRaised = 0;

   
  uint public investorCount = 0;

   
  bool public finalized;

  bool public isWhiteListed;

  address[] public joinedCrowdsales;
  uint8 public joinedCrowdsalesLen = 0;
  uint8 public joinedCrowdsalesLenMax = 50;
  struct JoinedCrowdsaleStatus {
    bool isJoined;
    uint8 position;
  }
  mapping (address => JoinedCrowdsaleStatus) joinedCrowdsaleState;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

  struct WhiteListData {
    bool status;
    uint minCap;
    uint maxCap;
  }

   
  bool public isUpdatable;

   
  mapping (address => WhiteListData) public earlyParticipantWhitelist;

   
  address[] public whitelistedParticipants;

   
  uint public ownerTestValue;

   
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized}

   
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

   
  event Whitelisted(address addr, bool status, uint minCap, uint maxCap);
  event WhitelistItemChanged(address addr, bool status, uint minCap, uint maxCap);

   
  event StartsAtChanged(uint newStartsAt);

   
  event EndsAtChanged(uint newEndsAt);

  function CrowdsaleExt(string _name, address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, bool _isUpdatable, bool _isWhiteListed) {

    owner = msg.sender;

    name = _name;

    token = FractionalERC20Ext(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    if(multisigWallet == 0) {
        throw;
    }

    if(_start == 0) {
        throw;
    }

    startsAt = _start;

    if(_end == 0) {
        throw;
    }

    endsAt = _end;

     
    if(startsAt >= endsAt) {
        throw;
    }

     
    minimumFundingGoal = _minimumFundingGoal;

    isUpdatable = _isUpdatable;

    isWhiteListed = _isWhiteListed;
  }

   
  function() payable {
    throw;
  }

   
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {

     
    if(getState() == State.PreFunding) {
       
      throw;
    } else if(getState() == State.Funding) {
       
       
      if(isWhiteListed) {
        if(!earlyParticipantWhitelist[receiver].status) {
          throw;
        }
      }
    } else {
       
      throw;
    }

    uint weiAmount = msg.value;

     
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised, tokensSold, msg.sender, token.decimals());

    if(tokenAmount == 0) {
       
      throw;
    }

    if(isWhiteListed) {
      if(tokenAmount < earlyParticipantWhitelist[receiver].minCap && tokenAmountOf[receiver] == 0) {
         
        throw;
      }

       
      if (isBreakingInvestorCap(receiver, tokenAmount)) {
        throw;
      }

      updateInheritedEarlyParticipantWhitelist(receiver, tokenAmount);
    } else {
      if(tokenAmount < token.minCap() && tokenAmountOf[receiver] == 0) {
        throw;
      }
    }

    if(investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }

     
    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

     
    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);

     
    if(isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
      throw;
    }

    assignTokens(receiver, tokenAmount);

     
    if(!multisigWallet.send(weiAmount)) throw;

     
    Invested(receiver, weiAmount, tokenAmount, customerId);
  }

   
  function invest(address addr) public payable {
    investInternal(addr, 0);
  }

   
  function buy() public payable {
    invest(msg.sender);
  }

  function distributeReservedTokens(uint reservedTokensDistributionBatch) public inState(State.Success) onlyOwner stopInEmergency {
     
    if(finalized) {
      throw;
    }

     
    if(address(finalizeAgent) != address(0)) {
      finalizeAgent.distributeReservedTokens(reservedTokensDistributionBatch);
    }
  }

  function areReservedTokensDistributed() public constant returns (bool) {
    return finalizeAgent.reservedTokensAreDistributed();
  }

  function canDistributeReservedTokens() public constant returns(bool) {
    CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
    if ((lastTierCntrct.getState() == State.Success) && !lastTierCntrct.halted() && !lastTierCntrct.finalized() && !lastTierCntrct.areReservedTokensDistributed()) return true;
    return false;
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

     
    if(finalized) {
      throw;
    }

     
    if(address(finalizeAgent) != address(0)) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }

   
  function setFinalizeAgent(FinalizeAgent addr) public onlyOwner {
    assert(address(addr) != address(0));
    assert(address(finalizeAgent) == address(0));
    finalizeAgent = addr;

     
    if(!finalizeAgent.isFinalizeAgent()) {
      throw;
    }
  }

   
  function setEarlyParticipantWhitelist(address addr, bool status, uint minCap, uint maxCap) public onlyOwner {
    if (!isWhiteListed) throw;
    assert(addr != address(0));
    assert(maxCap > 0);
    assert(minCap <= maxCap);
    assert(now <= endsAt);

    if (!isAddressWhitelisted(addr)) {
      whitelistedParticipants.push(addr);
      Whitelisted(addr, status, minCap, maxCap);
    } else {
      WhitelistItemChanged(addr, status, minCap, maxCap);
    }

    earlyParticipantWhitelist[addr] = WhiteListData({status:status, minCap:minCap, maxCap:maxCap});
  }

  function setEarlyParticipantWhitelistMultiple(address[] addrs, bool[] statuses, uint[] minCaps, uint[] maxCaps) public onlyOwner {
    if (!isWhiteListed) throw;
    assert(now <= endsAt);
    assert(addrs.length == statuses.length);
    assert(statuses.length == minCaps.length);
    assert(minCaps.length == maxCaps.length);
    for (uint iterator = 0; iterator < addrs.length; iterator++) {
      setEarlyParticipantWhitelist(addrs[iterator], statuses[iterator], minCaps[iterator], maxCaps[iterator]);
    }
  }

  function updateInheritedEarlyParticipantWhitelist(address reciever, uint tokensBought) private {
    if (!isWhiteListed) throw;
    if (tokensBought < earlyParticipantWhitelist[reciever].minCap && tokenAmountOf[reciever] == 0) throw;

    uint8 tierPosition = getTierPosition(this);

    for (uint8 j = tierPosition + 1; j < joinedCrowdsalesLen; j++) {
      CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
      crowdsale.updateEarlyParticipantWhitelist(reciever, tokensBought);
    }
  }

  function updateEarlyParticipantWhitelist(address addr, uint tokensBought) public {
    if (!isWhiteListed) throw;
    assert(addr != address(0));
    assert(now <= endsAt);
    assert(isTierJoined(msg.sender));
    if (tokensBought < earlyParticipantWhitelist[addr].minCap && tokenAmountOf[addr] == 0) throw;
     
    uint newMaxCap = earlyParticipantWhitelist[addr].maxCap;
    newMaxCap = newMaxCap.minus(tokensBought);
    earlyParticipantWhitelist[addr] = WhiteListData({status:earlyParticipantWhitelist[addr].status, minCap:0, maxCap:newMaxCap});
  }

  function isAddressWhitelisted(address addr) public constant returns(bool) {
    for (uint i = 0; i < whitelistedParticipants.length; i++) {
      if (whitelistedParticipants[i] == addr) {
        return true;
        break;
      }
    }

    return false;
  }

  function whitelistedParticipantsLength() public constant returns (uint) {
    return whitelistedParticipants.length;
  }

  function isTierJoined(address addr) public constant returns(bool) {
    return joinedCrowdsaleState[addr].isJoined;
  }

  function getTierPosition(address addr) public constant returns(uint8) {
    return joinedCrowdsaleState[addr].position;
  }

  function getLastTier() public constant returns(address) {
    if (joinedCrowdsalesLen > 0)
      return joinedCrowdsales[joinedCrowdsalesLen - 1];
    else
      return address(0);
  }

  function setJoinedCrowdsales(address addr) private onlyOwner {
    assert(addr != address(0));
    assert(joinedCrowdsalesLen <= joinedCrowdsalesLenMax);
    assert(!isTierJoined(addr));
    joinedCrowdsales.push(addr);
    joinedCrowdsaleState[addr] = JoinedCrowdsaleStatus({
      isJoined: true,
      position: joinedCrowdsalesLen
    });
    joinedCrowdsalesLen++;
  }

  function updateJoinedCrowdsalesMultiple(address[] addrs) public onlyOwner {
    assert(addrs.length > 0);
    assert(joinedCrowdsalesLen == 0);
    assert(addrs.length <= joinedCrowdsalesLenMax);
    for (uint8 iter = 0; iter < addrs.length; iter++) {
      setJoinedCrowdsales(addrs[iter]);
    }
  }

  function setStartsAt(uint time) onlyOwner {
    assert(!finalized);
    assert(isUpdatable);
    assert(now <= time);  
    assert(time <= endsAt);
    assert(now <= startsAt);

    CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
    if (lastTierCntrct.finalized()) throw;

    uint8 tierPosition = getTierPosition(this);

     
    for (uint8 j = 0; j < tierPosition; j++) {
      CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
      assert(time >= crowdsale.endsAt());
    }

    startsAt = time;
    StartsAtChanged(startsAt);
  }

   
  function setEndsAt(uint time) public onlyOwner {
    assert(!finalized);
    assert(isUpdatable);
    assert(now <= time); 
    assert(startsAt <= time);
    assert(now <= endsAt);

    CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
    if (lastTierCntrct.finalized()) throw;


    uint8 tierPosition = getTierPosition(this);

    for (uint8 j = tierPosition + 1; j < joinedCrowdsalesLen; j++) {
      CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
      assert(time <= crowdsale.startsAt());
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }

   
  function setPricingStrategy(PricingStrategy _pricingStrategy) public onlyOwner {
    assert(address(_pricingStrategy) != address(0));
    assert(address(pricingStrategy) == address(0));
    pricingStrategy = _pricingStrategy;

     
    if(!pricingStrategy.isPricingStrategy()) {
      throw;
    }
  }

   
  function setMultisig(address addr) public onlyOwner {

     
    if(investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
      throw;
    }

    multisigWallet = addr;
  }

   
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

   
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }

   
  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }

   
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (address(finalizeAgent) == 0) return State.Preparing;
    else if (!finalizeAgent.isSane()) return State.Preparing;
    else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else return State.Failure;
  }

   
  function isCrowdsale() public constant returns (bool) {
    return true;
  }

   
   
   

   
  modifier inState(State state) {
    if(getState() != state) throw;
    _;
  }


   
   
   

   
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) public constant returns (bool limitBroken);

  function isBreakingInvestorCap(address receiver, uint tokenAmount) public constant returns (bool limitBroken);

   
  function isCrowdsaleFull() public constant returns (bool);

   
  function assignTokens(address receiver, uint tokenAmount) private;
}

 







 
contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            throw;
        }
    }

    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        throw;
    }
    _;
  }

   
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        throw;
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}


 
contract NullFinalizeAgentExt is FinalizeAgent {

  CrowdsaleExt public crowdsale;

  function NullFinalizeAgentExt(CrowdsaleExt _crowdsale) {
    crowdsale = _crowdsale;
  }

   
  function isSane() public constant returns (bool) {
    return true;
  }

  function distributeReservedTokens(uint reservedTokensDistributionBatch) public {
  }

   
  function finalizeCrowdsale() public {
  }

}