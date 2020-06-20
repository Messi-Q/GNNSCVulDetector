pragma solidity ^0.4.18;

 

 
 
 
 
 
 
 

 
 
 
 
 
 
 

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);

     
     
     
     
    function onBurn(address _owner, uint _amount) public returns(bool);
}

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'EFX_0.1';  


     
     
     
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

     
    Checkpoint[] totalPledgedFeesHistory;  

     
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


 
 
 

    uint constant MAX_UINT = 2**256 - 1;

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < MAX_UINT) {
                require(allowed[_from][msg.sender] >= _amount);
                allowed[_from][msg.sender] -= _amount;
            }
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

 
 
 

    
    
   function totalPledgedFees() public constant returns (uint) {
       return totalPledgedFeesAt(block.number);
   }

    
    
    
   function totalPledgedFeesAt(uint _blockNumber) public constant returns(uint) {

        
        
        
        
        
       if ((totalPledgedFeesHistory.length == 0)
           || (totalPledgedFeesHistory[0].fromBlock > _blockNumber)) {
           if (address(parentToken) != 0) {
               return parentToken.totalPledgedFeesAt(min(_blockNumber, parentSnapShotBlock));
           } else {
               return 0;
           }

        
       } else {
           return getValueAt(totalPledgedFeesHistory, _blockNumber);
       }
   }

 
 
 

    
    
   function pledgeFees(uint _value) public onlyController returns (bool) {
       uint curTotalFees = totalPledgedFees();
       require(curTotalFees + _value >= curTotalFees);  
       updateValueAtNow(totalPledgedFeesHistory, curTotalFees + _value);
       return true;
   }

    
    
   function reducePledgedFees(uint _value) public onlyController returns (bool) {
       uint curTotalFees = totalPledgedFees();
       require(curTotalFees >= _value);
       updateValueAtNow(totalPledgedFeesHistory, curTotalFees - _value);
       return true;
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

 

contract NEC is MiniMeToken {

  function NEC(
    address _tokenFactory,
    address efxVaultWallet
  ) public MiniMeToken(
    _tokenFactory,
    0x0,                     
    0,                       
    "Ethfinex Nectar Token",  
    18,                      
    "NEC",                   
    true                     
    ) {
        generateTokens(efxVaultWallet, 1000000000000000000000000000);
        enableBurning(false);
    }

     
    bool public burningEnabled;


 
 
 

    function enableBurning(bool _burningEnabled) public onlyController {
        burningEnabled = _burningEnabled;
    }

    function burnAndRetrieve(uint256 _tokensToBurn) public returns (bool success) {
        require(burningEnabled);

        var previousBalanceFrom = balanceOfAt(msg.sender, block.number);
        if (previousBalanceFrom < _tokensToBurn) {
            return false;
        }

         
         
         
        if (isContract(controller)) {
            require(TokenController(controller).onBurn(msg.sender, _tokensToBurn));
        }

        Burned(msg.sender, _tokensToBurn);
        return true;
    }

    event Burned(address indexed who, uint256 _amount);

}

 
 
contract Owned {
     
     
    modifier onlyOwner { require (msg.sender == owner); _; }

    address public owner;

     
    function Owned() public { owner = msg.sender;}

     
     
     
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

 


 
contract Whitelist is Owned {

  bool public listActive = true;

   
  function isRegistered(address _user) public constant returns (bool) {
    if (!listActive) {
      return true;
    } else {
      return isOnList[_user];
    }
  }

   
  modifier authorised () {
    require(isAuthorisedMaker[msg.sender]);
    _;
  }

   
  mapping (address => bool) public isOnList;

   
  mapping (address => bool) public isAuthorisedMaker;


   
   
  function register(address[] newUsers) public onlyOwner {
    for (uint i = 0; i < newUsers.length; i++) {
      isOnList[newUsers[i]] = true;
    }
  }

   
   
  function deregister(address[] bannedUsers) public onlyOwner {
    for (uint i = 0; i < bannedUsers.length; i++) {
      isOnList[bannedUsers[i]] = false;
    }
  }

   
   
  function authoriseMaker(address maker) public onlyOwner {
      isAuthorisedMaker[maker] = true;
       
      address[] memory makers = new address[](1);
      makers[0] = maker;
      register(makers);
  }

   
   
  function deauthoriseMaker(address maker) public onlyOwner {
      isAuthorisedMaker[maker] = false;
  }

  function activateWhitelist(bool newSetting) public onlyOwner {
      listActive = newSetting;
  }

   

  function getRegistrationStatus(address _user) constant external returns (bool) {
    return isOnList[_user];
  }

  function getAuthorisationStatus(address _maker) constant external returns (bool) {
    return isAuthorisedMaker[_maker];
  }

  function getOwner() external constant returns (address) {
    return owner;
  }

}

 
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


 

contract NectarController is TokenController, Whitelist {
    using SafeMath for uint256;

    NEC public tokenContract;    
    address public vaultAddress;         

    uint public periodLength = 30;        
    uint public startTime;               

    mapping (uint => uint) public windowFinalBlock;   


     
     
     

    function NectarController(
        address _vaultAddress,
        address _tokenAddress
    ) public {
        require(_vaultAddress != 0);                 
        tokenContract = NEC(_tokenAddress);  
        vaultAddress = _vaultAddress;
        startTime = block.timestamp;
        windowFinalBlock[0] = block.number-1;
    }

     
     
     
     

    function ()  public payable {
        doTakerPayment();
    }

    function contributeForMakers(address _owner) public payable authorised {
        doMakerPayment(_owner);
    }

 
 
 

     
     
     
    function proxyPayment(address _owner) public payable returns(bool) {
        doTakerPayment();
        return true;
    }

     
     
     
    function proxyAccountingCreation(address _owner, uint _pledgedAmount, uint _tokensToCreate) public onlyOwner returns(bool) {
         
         
         
         
         
        doProxyAccounting(_owner, _pledgedAmount, _tokensToCreate);
        return true;
    }


     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool) {
        if (isRegistered(_to) && isRegistered(_from)) {
          return true;
        } else {
          return false;
        }
    }

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool)
    {
        if (isRegistered(_owner)) {
          return true;
        } else {
          return false;
        }
    }

     
     
     
     
     
    function onBurn(address _owner, uint _tokensToBurn) public
        returns(bool)
    {
         
        require(msg.sender == address(tokenContract));

        uint256 feeTotal = tokenContract.totalPledgedFees();
        uint256 totalTokens = tokenContract.totalSupply();
        uint256 feeValueOfTokens = (feeTotal.mul(_tokensToBurn)).div(totalTokens);

         
        require (tokenContract.destroyTokens(_owner, _tokensToBurn));
        require (this.balance >= feeValueOfTokens);
        require (_owner.send(feeValueOfTokens));

        LogClaim(_owner, feeValueOfTokens);
        return true;
    }

 
 
 


     
     
     
     
    function doMakerPayment(address _owner) internal {

        require ((tokenContract.controller() != 0) && (msg.value != 0) );
        tokenContract.pledgeFees(msg.value);
        require (vaultAddress.send(msg.value));

         
         
        if(windowFinalBlock[currentWindow()-1] == 0) {
            windowFinalBlock[currentWindow()-1] = block.number -1;
        }

        uint256 newIssuance = getFeeToTokenConversion(msg.value);
        require (tokenContract.generateTokens(_owner, newIssuance));

        LogContributions (_owner, msg.value, true);
        return;
    }

     
     
    function doTakerPayment() internal {

        require ((tokenContract.controller() != 0) && (msg.value != 0) );
        tokenContract.pledgeFees(msg.value);
        require (vaultAddress.send(msg.value));

        LogContributions (msg.sender, msg.value, false);
        return;
    }

     
     
    function doProxyAccounting(address _owner, uint _pledgedAmount, uint _tokensToCreate) internal {

        require ((tokenContract.controller() != 0));
        if(windowFinalBlock[currentWindow()-1] == 0) {
            windowFinalBlock[currentWindow()-1] = block.number -1;
        }
        tokenContract.pledgeFees(_pledgedAmount);

        if(_tokensToCreate > 0) {
            uint256 newIssuance = getFeeToTokenConversion(_pledgedAmount);
            require (tokenContract.generateTokens(_owner, _tokensToCreate));
        }

        LogContributions (msg.sender, _pledgedAmount, true);
        return;
    }

     
     
    function setVault(address _newVaultAddress) public onlyOwner {
        vaultAddress = _newVaultAddress;
    }

     
     
    function upgradeController(address _newControllerAddress) public onlyOwner {
        tokenContract.changeController(_newControllerAddress);
        UpgradedController(_newControllerAddress);
    }

 
 
 

     
     
    function getFeeToTokenConversion(uint256 _contributed) public constant returns (uint256) {

         
         
         
         

        uint calculationBlock = windowFinalBlock[currentWindow()-1];
        uint256 previousSupply = tokenContract.totalSupplyAt(calculationBlock);
        uint256 initialSupply = tokenContract.totalSupplyAt(windowFinalBlock[0]);
        uint256 feeTotal = tokenContract.totalPledgedFeesAt(calculationBlock);
        uint256 newTokens = (_contributed.mul(previousSupply.div(1000)).div((initialSupply.div(1000)).add(feeTotal))).mul(1000);
        return newTokens;
    }

    function currentWindow() public constant returns (uint) {
       return windowAt(block.timestamp);
    }

    function windowAt(uint timestamp) public constant returns (uint) {
      return timestamp < startTime
          ? 0
          : timestamp.sub(startTime).div(periodLength * 1 days) + 1;
    }

     
    function topUpBalance() public payable {
         
        LogFeeTopUp(msg.value);
    }

     
    function evacuateToVault() public onlyOwner{
        vaultAddress.transfer(this.balance);
        LogFeeEvacuation(this.balance);
    }

     
    function enableBurning(bool _burningEnabled) public onlyOwner{
        tokenContract.enableBurning(_burningEnabled);
    }


 
 
 

     
     
     
    function claimTokens(address _token) public onlyOwner {

        NEC token = NEC(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

    event LogFeeTopUp(uint _amount);
    event LogFeeEvacuation(uint _amount);
    event LogContributions (address _user, uint _amount, bool _maker);
    event LogClaim (address _user, uint _amount);

    event UpgradedController (address newAddress);


}