pragma solidity 0.4.18;

 
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

 

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
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

contract Presale {

  using SafeMath for uint256;
  uint256 private weiRaised;
  uint256 private startTime;
  uint256 private endTime;
  uint256 private rate;

  uint256 private cap;

  function Presale(uint256 _startTime, uint256 duration, uint256 _rate, uint256 _cap) public {
    require(_rate > 0);
    require(_cap > 0);
    require(_startTime >= now);
    require(duration > 0);

    rate = _rate;
    cap = _cap;
    startTime = _startTime;
    endTime = startTime + duration * 1 days;
    weiRaised = 0;
  }

  function totalWei() public constant returns(uint256) {
    return weiRaised;
  }

  function capRemaining() public constant returns(uint256) {
    return cap.sub(weiRaised);
  }

  function totalCap() public constant returns(uint256) {
    return cap;
  }

  function buyTokens(address purchaser, uint256 value) internal returns(uint256) {
    require(validPurchase(value));
    uint256 tokens = rate.mul(value);
    weiRaised = weiRaised.add(value);
    return tokens;
  }

  function hasEnded() internal constant returns(bool) {
    return now > endTime || weiRaised >= cap;
  }

  function hasStarted() internal constant returns(bool) {
    return now > startTime;
  }

  function validPurchase(uint256 value) internal view returns (bool) {
    bool withinCap = weiRaised.add(value) <= cap;
    return withinCap && withinPeriod();
  }

  function presaleRate() public view returns(uint256) {
    return rate;
  }

  function withinPeriod () private constant returns(bool) {
    return now >= startTime && now <= endTime;
  }
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 
contract VestingTrustee is Ownable, CanReclaimToken {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    struct Grant {
        uint256 value;
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 installmentLength;  
        uint256 transferred;
        bool revokable;
        uint256 prevested;
        uint256 vestingPercentage;
    }

     
    mapping (address => Grant) public grants;

     
    uint256 public totalVesting;

    event NewGrant(address indexed _from, address indexed _to, uint256 _value);
    event TokensUnlocked(address indexed _to, uint256 _value);
    event GrantRevoked(address indexed _holder, uint256 _refund);

     
     
    function VestingTrustee(address _token) {
        require(_token != address(0));

        token = ERC20(_token);
    }

     
     
     
     
     
     
     
     
    function grant(address _to, uint256 _value, uint256 _start, uint256 _cliff, uint256 _end,
        uint256 _installmentLength, uint256 vestingPercentage, uint256 prevested, bool _revokable)
        external onlyOwner {

        require(_to != address(0));
        require(_to != address(this));  
        require(_value > 0);
        require(_value.sub(prevested) > 0);
        require(vestingPercentage > 0);

         
        require(grants[_to].value == 0);

         
        require(_start <= _cliff && _cliff <= _end);

         
        require(_installmentLength > 0 && _installmentLength <= _end.sub(_start));

         
        require(totalVesting.add(_value.sub(prevested)) <= token.balanceOf(address(this)));

         
        grants[_to] = Grant({
            value: _value,
            start: _start,
            cliff: _cliff,
            end: _end,
            installmentLength: _installmentLength,
            transferred: prevested,
            revokable: _revokable,
            prevested: prevested,
            vestingPercentage: vestingPercentage
        });

        totalVesting = totalVesting.add(_value.sub(prevested));
        NewGrant(msg.sender, _to, _value);
    }

     
     
    function revoke(address _holder) public onlyOwner {
        Grant memory grant = grants[_holder];

         
        require(grant.revokable);

         
         
        uint256 refund = grant.value.sub(grant.transferred);

         
        delete grants[_holder];

         
        totalVesting = totalVesting.sub(refund);
        token.transfer(msg.sender, refund);

        GrantRevoked(_holder, refund);
    }

     
     
     
     
    function vestedTokens(address _holder, uint256 _time) external constant returns (uint256) {
        Grant memory grant = grants[_holder];
        if (grant.value == 0) {
            return 0;
        }

        return calculateVestedTokens(grant, _time);
    }

     
     
     
     
    function calculateVestedTokens(Grant _grant, uint256 _time) private constant returns (uint256) {
         
        if (_time < _grant.cliff) {
            return _grant.prevested;
        }

         
        if (_time >= _grant.end) {
            return _grant.value;
        }

         
        uint256 installmentsPast = _time.sub(_grant.cliff).div(_grant.installmentLength) + 1;


         
        return _grant.prevested.add(_grant.value.mul(installmentsPast.mul(_grant.vestingPercentage)).div(100));
    }

     
     
    function unlockVestedTokens() external {
        Grant storage grant = grants[msg.sender];

         
        require(grant.value != 0);

         
        uint256 vested = calculateVestedTokens(grant, now);
        if (vested == 0) {
            revert();
        }

         
        uint256 transferable = vested.sub(grant.transferred);
        if (transferable == 0) {
            revert();
        }

        grant.transferred = grant.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        token.transfer(msg.sender, transferable);
        TokensUnlocked(msg.sender, transferable);
    }

    function reclaimEther() external onlyOwner {
      assert(owner.send(this.balance));
    }
}

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

 

 
 
 
 
 
 
 




contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.2';  


     
     
     
    struct  Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal {

           if (_amount == 0) {
               Transfer(_from, _to, _amount);     
               return;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);

           require(previousBalanceFrom >= _amount);

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

         
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

         
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

         
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

 
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

   
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      WhitelistedAddressAdded(addr);
      success = true;
    }
  }

   
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

   
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

   
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

contract Crowdsale is Presale, Pausable, CanReclaimToken, Whitelist {

  using SafeMath for uint256;
  address public whitelistAddress;
  address public wallet;  
  MiniMeToken public token;  
  uint256 private weiRaised = 0;  
  uint256 private cap = 0;  
  bool private publicSaleInitialized = false;
  bool private finalized = false;
  uint256 private tokensSold = 0;  
  uint256 private startTime;  
  uint256 private endTime;  
  uint256 public maxTokens;
  mapping(address => uint256) public contributions;  
  mapping(address => uint256) public investorCaps;  
  address[] public investors;  
  address[] public founders;  
  address[] public advisors;  
  VestingTrustee public trustee;
  address public reserveWallet;  

   
   
  struct Tier {
    uint256 rate;
    uint256 max;
  }

  uint public privateSaleTokensAvailable;
  uint public privateSaleTokensSold = 0;
  uint public publicTokensAvailable;

  uint8 public totalTiers = 0;  
  bool public tiersInitialized = false;
  uint256 public maxTiers = 6;  
  Tier[6] public tiers;  

  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
  enum Stage { Preparing, Presale, PresaleFinished, PublicSale, Success, Finalized }

  function Crowdsale(
    uint256 _presaleStartTime,  
    uint256 _presaleDuration,  
    uint256 _presaleRate,  
    uint256 _presaleCap,  
    address erc20Token,  
    address _wallet,
    uint8 _tiers,
    uint256 _cap,
    address _reserveWallet)
    public
    Presale(_presaleStartTime, _presaleDuration, _presaleRate, _presaleCap)
    {
      require(_wallet != address(0));
      require(erc20Token != address(0));
      require(_tiers > 0 && _tiers <= maxTiers);
      require(_cap > 0);
      require(_reserveWallet != address(0));
      token = MiniMeToken(erc20Token);
      wallet = _wallet;
      totalTiers = _tiers;
      cap = _cap;
      reserveWallet = _reserveWallet;
      trustee = new VestingTrustee(erc20Token);
      maxTokens = 1000000000 * (10 ** 18);  
      privateSaleTokensAvailable = maxTokens.mul(22).div(100);
      publicTokensAvailable = maxTokens.mul(28).div(100);
      super.addAddressToWhitelist(msg.sender);

    }

  function() public payable {
    buyTokens(msg.sender, msg.value);
  }

  function getStage() public constant returns(Stage) {
    if (finalized) return Stage.Finalized;
    if (!tiersInitialized || !Presale.hasStarted()) return Stage.Preparing;
    if (!Presale.hasEnded()) return Stage.Presale;
    if (Presale.hasEnded() && !hasStarted()) return Stage.PresaleFinished;
    if (!hasEnded()) return Stage.PublicSale;
    if (hasEnded()) return Stage.Success;
    return Stage.Preparing;
  }

  modifier inStage(Stage _stage) {
    require(getStage() == _stage);
    _;
  }

   
   
  function initTiers(uint256[] rates, uint256[] totalWeis) public onlyWhitelisted returns(uint256) {
    require(token.controller() == address(this));
    require(!tiersInitialized);
    require(rates.length == totalTiers && rates.length == totalWeis.length);
    uint256 tierMax = 0;

    for (uint8 i=0; i < totalTiers; i++) {

      require(totalWeis[i] > 0 && rates[i] > 0);

      tierMax = tierMax.add(totalWeis[i]);
      tiers[i] = Tier({
        rate: rates[i],
        max: tierMax
      });
    }

    require(tierMax == cap);
    tiersInitialized = true;
    return tierMax;
  }

   
  function setCapForParticipants(address[] participants, uint256[] caps) onlyWhitelisted public  {
    require(participants.length <= 50 && participants.length == caps.length);
    for (uint8 i=0; i < participants.length; i++) {
      investorCaps[participants[i]] = caps[i];
    }
  }


  function addGrant(address assignee, uint256 value, bool isFounder) public onlyWhitelisted whenNotPaused {
    require(value > 0);
    require(assignee != address(0));
    uint256 start;
    uint256 cliff;
    uint256 vestingPercentage;
    uint256 initialTokens;
    if(isFounder) {
      start = now;
      cliff = start + 12*30 days;  
      vestingPercentage = 20;  
      founders.push(assignee);
    }
    else {
       
       
      initialTokens = value.mul(10).div(100);
      transferTokens(assignee, initialTokens);
      start = now;
      cliff = start + 6*30 days;   
      vestingPercentage = 15;  
      advisors.push(assignee);
    }

    uint256 end = now + 3 * 1 years;  
    uint256 installmentLength = 6 * 30 days;  
    bool revokable = true;
    transferTokens(trustee, value.sub(initialTokens));
    trustee.grant(assignee, value, start, cliff, end, installmentLength, vestingPercentage, initialTokens, revokable);
  }

   
  function finalize() public onlyWhitelisted inStage(Stage.Success) {
    require(!finalized);
     
    trustee.transferOwnership(msg.sender);
     
    token.enableTransfers(true);
     
    uint256 unsold = maxTokens.sub(token.totalSupply());
    transferTokens(reserveWallet, unsold);

     
     
    token.changeController(0x0);
    finalized = true;
  }

   
  function startPublicSale(uint _startTime, uint _duration) public onlyWhitelisted inStage(Stage.PresaleFinished) {
    require(_startTime >= now);
    require(_duration > 0);
    startTime = _startTime;
    endTime = _startTime + _duration * 1 days;
    publicSaleInitialized = true;
  }

   
  function totalWei() public constant returns(uint256) {
    uint256 presaleWei = super.totalWei();
    return presaleWei.add(weiRaised);
  }

  function totalPublicSaleWei() public constant returns(uint256) {
    return weiRaised;
  }
   
  function totalCap() public constant returns(uint256) {
    uint256 presaleCap = super.totalCap();
    return presaleCap.add(cap);
  }

   
   
  function totalTokens() public constant returns(uint256) {
    return tokensSold;
  }

   
  function buyTokens(address purchaser, uint256 value) internal  whenNotPaused returns(uint256) {
    require(value > 0);
    Stage stage = getStage();
    require(stage == Stage.Presale || stage == Stage.PublicSale);

     
    uint256 purchaseAmount = Math.min256(value, investorCaps[purchaser].sub(contributions[purchaser]));
    require(purchaseAmount > 0);
    uint256 numTokens;

     
    if (stage == Stage.Presale) {
      if (Presale.totalWei().add(purchaseAmount) > Presale.totalCap()) {
        purchaseAmount = Presale.capRemaining();
      }
      numTokens = Presale.buyTokens(purchaser, purchaseAmount);
    } else if (stage == Stage.PublicSale) {

      uint totalWei = weiRaised.add(purchaseAmount);
      uint8 currentTier = getTier(weiRaised);  
      if (totalWei >= cap) {  
        totalWei = cap;
         
        purchaseAmount = cap.sub(weiRaised);
      }

       
       
      if (totalWei <= tiers[currentTier].max) {
        numTokens = purchaseAmount.mul(tiers[currentTier].rate);
      } else {
         
        uint remaining = tiers[currentTier].max.sub(weiRaised);
        numTokens = remaining.mul(tiers[currentTier].rate);

         
        uint256 excess = totalWei.sub(tiers[currentTier].max);
         
        numTokens = numTokens.add(excess.mul(tiers[currentTier + 1].rate));
      }

       
      weiRaised = weiRaised.add(purchaseAmount);
    }

     
    require(tokensSold.add(numTokens) <= publicTokensAvailable);
    tokensSold = tokensSold.add(numTokens);

     
    forwardFunds(purchaser, purchaseAmount);
     
    transferTokens(purchaser, numTokens);

     
    if (value.sub(purchaseAmount) > 0) {
      msg.sender.transfer(value.sub(purchaseAmount));
    }

     
    TokenPurchase(purchaser, numTokens, purchaseAmount);

    return numTokens;
  }



  function forwardFunds(address purchaser, uint256 value) internal {
     
    if (contributions[purchaser] == 0) {
      investors.push(purchaser);
    }
     
    contributions[purchaser] = contributions[purchaser].add(value);
    wallet.transfer(value);
  }

  function changeEndTime(uint _endTime) public onlyWhitelisted {
    endTime = _endTime;
  }

  function changeFundsWallet(address _newWallet) public onlyWhitelisted {
    require(_newWallet != address(0));
    wallet = _newWallet;
  }

  function changeTokenController() onlyWhitelisted public {
    token.changeController(msg.sender);
  }

  function changeTrusteeOwner() onlyWhitelisted public {
    trustee.transferOwnership(msg.sender);
  }
  function changeReserveWallet(address _reserve) public onlyWhitelisted {
    require(_reserve != address(0));
    reserveWallet = _reserve;
  }

  function setWhitelistAddress(address _whitelist) public onlyWhitelisted {
    require(_whitelist != address(0));
    whitelistAddress = _whitelist;
  }

  function transferTokens(address to, uint256 value) internal {
    token.generateTokens(to, value);
  }

  function sendPrivateSaleTokens(address to, uint256 value) public whenNotPaused onlyWhitelisted {
    require(privateSaleTokensSold.add(value) <= privateSaleTokensAvailable);
    privateSaleTokensSold = privateSaleTokensSold.add(value);
    transferTokens(to, value);
  }

  function hasEnded() internal constant returns(bool) {
    return now > endTime || weiRaised >= cap;
  }

  function hasStarted() internal constant returns(bool) {
    return publicSaleInitialized && now >= startTime;
  }

  function getTier(uint256 _weiRaised) internal constant returns(uint8) {
    for (uint8 i = 0; i < totalTiers; i++) {
      if (_weiRaised < tiers[i].max) {
        return i;
      }
    }
     
    return totalTiers + 1;
  }



  function getCurrentTier() public constant returns(uint8) {
    return getTier(weiRaised);
  }


   
  function proxyPayment(address _owner) public payable returns(bool) {
    return true;
  }

  function onApprove(address _owner, address _spender, uint _amount) public returns(bool) {
    return true;
  }

  function onTransfer(address _from, address _to, uint _amount) public returns(bool) {
    return true;
  }

  function getTokenSaleTime() public constant returns(uint256, uint256) {
    return (startTime, endTime);
  }
}