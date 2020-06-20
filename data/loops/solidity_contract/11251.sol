pragma solidity ^0.4.24;


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
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

           return true;
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


 
contract BurnableMiniMeToken is MiniMeToken {
  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _amount) public returns (bool) {
    uint curTotalSupply = totalSupply();
    require(curTotalSupply >= _amount);
    uint previousBalanceFrom = balanceOf(msg.sender);
    require(previousBalanceFrom >= _amount);
    updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
    updateValueAtNow(balances[msg.sender], previousBalanceFrom - _amount);
    Transfer(msg.sender, 0, _amount);
    return true;
  }
}


pragma solidity^0.4.18;


  
contract RankingBallGoldToken is MiniMeToken, BurnableMiniMeToken { 
    function RankingBallGoldToken(address _tokenFactory)
      MiniMeToken(
        _tokenFactory,
        0x0,                      
        0,                        
        "RankingBall Gold",   
        18,                       
        "RBG",                    
        true                      
      ) {} 
}


interface POSTokenI {
   
   
   
   
   
   
  function supportsInterface(bytes4 interfaceID) public view returns (bool);

   
  function transferOwnershipTo(address _to) public;
}

interface MintableTokenI {
  function mint(address _to, uint256 _amount) public returns (bool);
}

interface MiniMeTokenI {
  function generateTokens(address _to, uint256 _amount) public returns (bool);
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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


 
 
 
 
contract POSController is Ownable, TokenController {
  using SafeMath for uint256;

  struct Claim {
    uint128 fromBlock;
    uint128 claimedValue;
  }

  address public token;

   
  uint256 public posInterval;
  uint256 public posRate;
  uint256 public posCoeff;

  uint256 public initBlockNumber;

  mapping (address => Claim[]) public claims;

  event Claimed(address indexed _owner, uint256 _amount);

   
  function POSController(
    address _token,
    uint256 _posInterval,
    uint256 _initBlockNumber,
    uint256 _posRate,
    uint256 _posCoeff
  ) public {
    require(_token != address(0));

    require(_posInterval != 0);
    require(_posRate != 0);
    require(_posCoeff != 0);

    token = _token;
    posInterval = _posInterval;
    posRate = _posRate;
    posCoeff = _posCoeff;

    if (_initBlockNumber == 0) {
      initBlockNumber = block.number;
    } else {
      initBlockNumber = _initBlockNumber;
    }
  }

   

   
   
  function claimTokens(address _owner) public {
    doClaim(_owner, claims[_owner]);
  }

   
  function claimTokenOwnership(address _to) public onlyOwner {
    POSTokenI(token).transferOwnershipTo(_to);
  }

   
  function proxyPayment(address _owner) public payable returns(bool) {
    revert();  
    return false;
  }

   
  function onTransfer(address _from, address _to, uint _amount) public returns(bool) {
    claimTokens(_from);
    claimTokens(_to);
    return true;
  }

   
  function onApprove(address _owner, address _spender, uint _amount) public returns(bool) {
    return true;
  }

   
  function doClaim(address _owner, Claim[] storage c) internal {
    uint256 claimRate;

    if (c.length == 0 && claimable(block.number)) {
      claimRate = getClaimRate(0);
    } else if (c.length > 0 && claimable(c[c.length - 1].fromBlock)) {
      claimRate = getClaimRate(c[c.length - 1].fromBlock);
    }

    if (claimRate > 0) {
      Claim storage newClaim = c[c.length++];

      uint256 balance = ERC20(token).balanceOf(_owner);

       
      if (balance == 0) {
        return;
      }

       
      uint256 targetBalance = balance.mul(posCoeff.add(claimRate)).div(posCoeff);
      uint256 claimedValue = targetBalance.sub(balance);

      newClaim.claimedValue = uint128(claimedValue);
      newClaim.fromBlock = uint128(block.number);

      require(generateTokens(_owner, newClaim.claimedValue));

      emit Claimed(_owner, newClaim.claimedValue);
    }
  }

  function generateTokens(address _to, uint256 _value) internal returns (bool) {
    if (POSTokenI(token).supportsInterface(bytes4(keccak256("mint(address,uint256)")))) {
      return MintableTokenI(token).mint(_to, _value);
    } else if (POSTokenI(token).supportsInterface(bytes4(keccak256("generateTokens(address,uint256)")))) {
      return MiniMeTokenI(token).generateTokens(_to, _value);
    }

    return false;
  }

  function claimable(uint256 _blockNumber) internal view returns (bool) {
    if (_blockNumber < initBlockNumber) return false;

    return (_blockNumber - initBlockNumber) >= posInterval;
  }

  function getClaimRate(uint256 _fromBlock) internal view returns (uint256) {
     
     
     
    uint256 lastIntervalBlock;

    if (_fromBlock == 0) {  
      lastIntervalBlock = initBlockNumber;
    } else {  
      uint256 offset = _fromBlock.sub(initBlockNumber) % posInterval;
      lastIntervalBlock = _fromBlock.sub(offset);
    }

     
    uint256 pow = block.number.sub(lastIntervalBlock) / posInterval;

     
    if (pow == 0) {
      return 0;
    }

     
    uint256 rate = posRate;

     
     
     
     
     
     
    for (uint256 i = 0; i < pow - 1; i++) {
      rate = rate.mul(posCoeff.add(posRate)).div(posCoeff).add(posRate);
    }

    return rate;
  }
}





 
 
contract BalanceUpdatableMiniMeToken is MiniMeToken {

   
  function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {

    if (_amount == 0) {
      Transfer(_from, _to, _amount);
      return true;
    }

    require(parentSnapShotBlock < block.number);
    require((_to != 0) && (_to != address(this)));

    uint previousBalanceFrom = balanceOfAt(_from, block.number);
    require(previousBalanceFrom >= _amount);

    if (isContract(controller)) {
      require(TokenController(controller).onTransfer(_from, _to, _amount));

       
      previousBalanceFrom = balanceOfAt(_from, block.number);
      require(previousBalanceFrom >= _amount);
    }

    updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

    var previousBalanceTo = balanceOfAt(_to, block.number);
    require(previousBalanceTo + _amount >= previousBalanceTo);  
    updateValueAtNow(balances[_to], previousBalanceTo + _amount);

    Transfer(_from, _to, _amount);

    return true;
  }
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
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
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


 
 
 
contract TokenControllerBridge is ERC20, Ownable {
  function () public payable {
    require(isContract(owner));
    require(TokenController(owner).proxyPayment.value(msg.value)(msg.sender));
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (isContract(owner)) {  
      require(balanceOf(msg.sender) >= _value);
      require(TokenController(owner).onTransfer(msg.sender, _to, _value));
    }

    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (isContract(owner)) {  
      require(balanceOf(_from) >= _value);
      require(TokenController(owner).onTransfer(_from, _to, _value));
    }

    return super.transferFrom(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    if (isContract(owner)) {
      require(TokenController(owner).onApprove(msg.sender, _spender, _value));
    }

    return super.approve(_spender, _value);
  }

   
   
   
  function isContract(address _addr) internal view returns(bool) {
    uint256 size;
    if (_addr == 0) return false;
    assembly {
      size := extcodesize(_addr)
    }
    return size > 0;
  }
}


 
 
 
contract POSMintableTokenAPI is POSTokenI, TokenControllerBridge {
  function supportsInterface(bytes4 interfaceID) public view returns (bool) {
    return interfaceID == bytes4(keccak256("mint(address,uint256)"));  
  }

  function transferOwnershipTo(address _to) public {
    transferOwnership(_to);
  }
}


 
 
 
contract POSMiniMeTokenAPI is POSTokenI, Controlled {
  function supportsInterface(bytes4 interfaceID) public view returns (bool) {
    return interfaceID == bytes4(keccak256("generateTokens(address,uint256)"));  
  }

  function transferOwnershipTo(address _to) public {
    changeController(_to);
  }
}


 
 
 
 
contract POSMiniMeToken is BalanceUpdatableMiniMeToken, POSMiniMeTokenAPI {}


contract RankingBallGoldCustomToken is POSMiniMeToken, RankingBallGoldToken {
  function RankingBallGoldCustomToken(address _tokenFactory)
    RankingBallGoldToken(_tokenFactory)
    public
  {}
}