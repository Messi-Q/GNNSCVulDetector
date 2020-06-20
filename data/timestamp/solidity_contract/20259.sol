pragma solidity ^0.4.19;


 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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


 
contract BurnupGameAccessControl is Claimable, Pausable, CanReclaimToken {
    mapping (address => bool) public cfo;
    
    function BurnupGameAccessControl() public {
         
        cfo[msg.sender] = true;
    }
    
     
    modifier onlyCFO() {
        require(cfo[msg.sender]);
        _;
    }

     
     
     
    function setCFO(address addr, bool set) external onlyOwner {
        require(addr != address(0));

        if (!set) {
            delete cfo[addr];
        } else {
            cfo[addr] = true;
        }
    }
}


 
contract BurnupGameBase is BurnupGameAccessControl {
    using SafeMath for uint256;
    
    event ActiveTimes(uint256[] from, uint256[] to);
    event AllowStart(bool allowStart);
    event NextGame(
        uint256 rows,
        uint256 cols,
        uint256 initialActivityTimer,
        uint256 finalActivityTimer,
        uint256 numberOfFlipsToFinalActivityTimer,
        uint256 timeoutBonusTime,
        uint256 unclaimedTilePrice,
        uint256 buyoutReferralBonusPercentage,
        uint256 firstBuyoutPrizePoolPercentage,
        uint256 buyoutPrizePoolPercentage,
        uint256 buyoutDividendPercentage,
        uint256 buyoutFeePercentage,
        uint256 buyoutPriceIncreasePercentage
    );
    event Start(
        uint256 indexed gameIndex,
        address indexed starter,
        uint256 timestamp,
        uint256 prizePool
    );
    event End(uint256 indexed gameIndex, address indexed winner, uint256 indexed identifier, uint256 x, uint256 y, uint256 timestamp, uint256 prize);
    event Buyout(
        uint256 indexed gameIndex,
        address indexed player,
        uint256 indexed identifier,
        uint256 x,
        uint256 y,
        uint256 timestamp,
        uint256 timeoutTimestamp,
        uint256 newPrice,
        uint256 newPrizePool
    );
    event LastTile(
        uint256 indexed gameIndex,
        uint256 indexed identifier,
        uint256 x,
        uint256 y
    );
    event PenultimateTileTimeout(
        uint256 indexed gameIndex,
        uint256 timeoutTimestamp
    );
    event SpiceUpPrizePool(uint256 indexed gameIndex, address indexed spicer, uint256 spiceAdded, string message, uint256 newPrizePool);
    
     
    struct GameSettings {
        uint256 rows;  
        uint256 cols;  
        
         
        uint256 initialActivityTimer;  
        
         
        uint256 finalActivityTimer;  
        
         
         
        uint256 numberOfFlipsToFinalActivityTimer;  
        
         
        uint256 timeoutBonusTime;  
        
         
        uint256 unclaimedTilePrice;  
        
         
         
        uint256 buyoutReferralBonusPercentage;  
        
         
         
        uint256 firstBuyoutPrizePoolPercentage;  
        
         
         
        uint256 buyoutPrizePoolPercentage;  
    
         
         
         
        uint256 buyoutDividendPercentage;  
    
         
        uint256 buyoutFeePercentage;  
        
         
        uint256 buyoutPriceIncreasePercentage;
    }
    
     
    struct GameState {
         
        bool gameStarted;
    
         
        uint256 gameStartTimestamp;
    
         
        mapping (uint256 => address) identifierToOwner;
        
         
        mapping (uint256 => uint256) identifierToTimeoutTimestamp;
        
         
        mapping (uint256 => uint256) identifierToBuyoutPrice;
        
         
        mapping (address => uint256) addressToNumberOfTiles;
        
         
        uint256 numberOfTileFlips;
        
         
        uint256 lastTile;
        
         
        uint256 penultimateTileTimeout;
        
         
        uint256 prizePool;
    }
    
     
    mapping (uint256 => GameState) public gameStates;
    
     
    uint256 public gameIndex = 0;
    
     
    GameSettings public gameSettings;
    
     
    GameSettings public nextGameSettings;
    
     
     
    uint256[] public activeTimesFrom;
    uint256[] public activeTimesTo;
    
     
    bool public allowStart;
    
    function BurnupGameBase() public {
         
        setNextGameSettings(
            4,  
            5,  
            300,  
            150,  
            5,  
            30,  
            0.01 ether,  
            750,  
            40000,  
            10000,  
            5000,  
            2500,  
            150000  
        );
    }
    
     
     
     
    function validCoordinate(uint256 x, uint256 y) public view returns(bool) {
        return x < gameSettings.cols && y < gameSettings.rows;
    }
    
     
     
     
    function coordinateToIdentifier(uint256 x, uint256 y) public view returns(uint256) {
        require(validCoordinate(x, y));
        
        return (y * gameSettings.cols) + x + 1;
    }
    
     
     
     
    function identifierToCoordinate(uint256 identifier) public view returns(uint256 x, uint256 y) {
        y = (identifier - 1) / gameSettings.cols;
        x = (identifier - 1) - (y * gameSettings.cols);
    }
    
     
    function setNextGameSettings(
        uint256 rows,
        uint256 cols,
        uint256 initialActivityTimer,
        uint256 finalActivityTimer,
        uint256 numberOfFlipsToFinalActivityTimer,
        uint256 timeoutBonusTime,
        uint256 unclaimedTilePrice,
        uint256 buyoutReferralBonusPercentage,
        uint256 firstBuyoutPrizePoolPercentage,
        uint256 buyoutPrizePoolPercentage,
        uint256 buyoutDividendPercentage,
        uint256 buyoutFeePercentage,
        uint256 buyoutPriceIncreasePercentage
    )
        public
        onlyCFO
    {
         
         
        require(2000 <= buyoutDividendPercentage && buyoutDividendPercentage <= 12500);
        
         
        require(buyoutFeePercentage <= 5000);
        
        if (numberOfFlipsToFinalActivityTimer == 0) {
            require(initialActivityTimer == finalActivityTimer);
        }
        
        nextGameSettings = GameSettings({
            rows: rows,
            cols: cols,
            initialActivityTimer: initialActivityTimer,
            finalActivityTimer: finalActivityTimer,
            numberOfFlipsToFinalActivityTimer: numberOfFlipsToFinalActivityTimer,
            timeoutBonusTime: timeoutBonusTime,
            unclaimedTilePrice: unclaimedTilePrice,
            buyoutReferralBonusPercentage: buyoutReferralBonusPercentage,
            firstBuyoutPrizePoolPercentage: firstBuyoutPrizePoolPercentage,
            buyoutPrizePoolPercentage: buyoutPrizePoolPercentage,
            buyoutDividendPercentage: buyoutDividendPercentage,
            buyoutFeePercentage: buyoutFeePercentage,
            buyoutPriceIncreasePercentage: buyoutPriceIncreasePercentage
        });
        
        NextGame(
            rows,
            cols,
            initialActivityTimer,
            finalActivityTimer,
            numberOfFlipsToFinalActivityTimer,
            timeoutBonusTime,
            unclaimedTilePrice,
            buyoutReferralBonusPercentage, 
            firstBuyoutPrizePoolPercentage,
            buyoutPrizePoolPercentage,
            buyoutDividendPercentage,
            buyoutFeePercentage,
            buyoutPriceIncreasePercentage
        );
    }
    
     
    function setActiveTimes(uint256[] _from, uint256[] _to) external onlyCFO {
        require(_from.length == _to.length);
    
        activeTimesFrom = _from;
        activeTimesTo = _to;
        
         
        ActiveTimes(_from, _to);
    }
    
     
    function setAllowStart(bool _allowStart) external onlyCFO {
        allowStart = _allowStart;
        
         
        AllowStart(_allowStart);
    }
    
     
     
    function canStart() public view returns (bool) {
         
         
         
         

         
        uint256 timeOfWeek = (block.timestamp - 345600) % 604800;
        
        uint256 windows = activeTimesFrom.length;
        
        if (windows == 0) {
             
            return true;
        }
        
        for (uint256 i = 0; i < windows; i++) {
            if (timeOfWeek >= activeTimesFrom[i] && timeOfWeek <= activeTimesTo[i]) {
                return true;
            }
        }
        
        return false;
    }
    
     
    function calculateBaseTimeout() public view returns(uint256) {
        uint256 _numberOfTileFlips = gameStates[gameIndex].numberOfTileFlips;
    
        if (_numberOfTileFlips >= gameSettings.numberOfFlipsToFinalActivityTimer || gameSettings.numberOfFlipsToFinalActivityTimer == 0) {
            return gameSettings.finalActivityTimer;
        } else {
            if (gameSettings.finalActivityTimer <= gameSettings.initialActivityTimer) {
                 
            
                 
                 
                uint256 difference = gameSettings.initialActivityTimer - gameSettings.finalActivityTimer;
                
                 
                uint256 decrease = difference.mul(_numberOfTileFlips).div(gameSettings.numberOfFlipsToFinalActivityTimer);
                
                 
                return (gameSettings.initialActivityTimer - decrease);
            } else {
                 
            
                 
                 
                difference = gameSettings.finalActivityTimer - gameSettings.initialActivityTimer;
                
                 
                uint256 increase = difference.mul(_numberOfTileFlips).div(gameSettings.numberOfFlipsToFinalActivityTimer);
                
                 
                return (gameSettings.initialActivityTimer + increase);
            }
        }
    }
    
     
     
     
    function tileTimeoutTimestamp(uint256 identifier, address player) public view returns (uint256) {
        uint256 bonusTime = gameSettings.timeoutBonusTime.mul(gameStates[gameIndex].addressToNumberOfTiles[player]);
        uint256 timeoutTimestamp = block.timestamp.add(calculateBaseTimeout()).add(bonusTime);
        
        uint256 currentTimeoutTimestamp = gameStates[gameIndex].identifierToTimeoutTimestamp[identifier];
        if (currentTimeoutTimestamp == 0) {
             
            currentTimeoutTimestamp = gameStates[gameIndex].gameStartTimestamp.add(gameSettings.initialActivityTimer);
        }
        
        if (timeoutTimestamp >= currentTimeoutTimestamp) {
            return timeoutTimestamp;
        } else {
            return currentTimeoutTimestamp;
        }
    }
    
     
    function _setGameSettings() internal {
        if (gameSettings.rows != nextGameSettings.rows) {
            gameSettings.rows = nextGameSettings.rows;
        }
        
        if (gameSettings.cols != nextGameSettings.cols) {
            gameSettings.cols = nextGameSettings.cols;
        }
        
        if (gameSettings.initialActivityTimer != nextGameSettings.initialActivityTimer) {
            gameSettings.initialActivityTimer = nextGameSettings.initialActivityTimer;
        }
        
        if (gameSettings.finalActivityTimer != nextGameSettings.finalActivityTimer) {
            gameSettings.finalActivityTimer = nextGameSettings.finalActivityTimer;
        }
        
        if (gameSettings.numberOfFlipsToFinalActivityTimer != nextGameSettings.numberOfFlipsToFinalActivityTimer) {
            gameSettings.numberOfFlipsToFinalActivityTimer = nextGameSettings.numberOfFlipsToFinalActivityTimer;
        }
        
        if (gameSettings.timeoutBonusTime != nextGameSettings.timeoutBonusTime) {
            gameSettings.timeoutBonusTime = nextGameSettings.timeoutBonusTime;
        }
        
        if (gameSettings.unclaimedTilePrice != nextGameSettings.unclaimedTilePrice) {
            gameSettings.unclaimedTilePrice = nextGameSettings.unclaimedTilePrice;
        }
        
        if (gameSettings.buyoutReferralBonusPercentage != nextGameSettings.buyoutReferralBonusPercentage) {
            gameSettings.buyoutReferralBonusPercentage = nextGameSettings.buyoutReferralBonusPercentage;
        }
        
        if (gameSettings.firstBuyoutPrizePoolPercentage != nextGameSettings.firstBuyoutPrizePoolPercentage) {
            gameSettings.firstBuyoutPrizePoolPercentage = nextGameSettings.firstBuyoutPrizePoolPercentage;
        }
        
        if (gameSettings.buyoutPrizePoolPercentage != nextGameSettings.buyoutPrizePoolPercentage) {
            gameSettings.buyoutPrizePoolPercentage = nextGameSettings.buyoutPrizePoolPercentage;
        }
        
        if (gameSettings.buyoutDividendPercentage != nextGameSettings.buyoutDividendPercentage) {
            gameSettings.buyoutDividendPercentage = nextGameSettings.buyoutDividendPercentage;
        }
        
        if (gameSettings.buyoutFeePercentage != nextGameSettings.buyoutFeePercentage) {
            gameSettings.buyoutFeePercentage = nextGameSettings.buyoutFeePercentage;
        }
        
        if (gameSettings.buyoutPriceIncreasePercentage != nextGameSettings.buyoutPriceIncreasePercentage) {
            gameSettings.buyoutPriceIncreasePercentage = nextGameSettings.buyoutPriceIncreasePercentage;
        }
    }
}


 
contract BurnupGameOwnership is BurnupGameBase {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed deedId);
    
     
    function name() public pure returns (string _deedName) {
        _deedName = "Burnup Tiles";
    }
    
     
    function symbol() public pure returns (string _deedSymbol) {
        _deedSymbol = "BURN";
    }
    
     
     
     
    function _owns(address _owner, uint256 _identifier) internal view returns (bool) {
        return gameStates[gameIndex].identifierToOwner[_identifier] == _owner;
    }
    
     
     
     
     
    function _transfer(address _from, address _to, uint256 _identifier) internal {
         
        gameStates[gameIndex].identifierToOwner[_identifier] = _to;
        
        if (_from != 0x0) {
            gameStates[gameIndex].addressToNumberOfTiles[_from] = gameStates[gameIndex].addressToNumberOfTiles[_from].sub(1);
        }
        
        gameStates[gameIndex].addressToNumberOfTiles[_to] = gameStates[gameIndex].addressToNumberOfTiles[_to].add(1);
        
         
        Transfer(_from, _to, _identifier);
    }
    
     
     
    function ownerOf(uint256 _identifier) external view returns (address _owner) {
        _owner = gameStates[gameIndex].identifierToOwner[_identifier];

        require(_owner != address(0));
    }
    
     
     
     
     
     
     
    function transfer(address _to, uint256 _identifier) external whenNotPaused {
         
        require(_owns(msg.sender, _identifier));
        
         
        _transfer(msg.sender, _to, _identifier);
    }
}


 
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

   
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

   
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}


 
contract BurnupHoldingAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;
    
     
    mapping (address => bool) burnupGame;

    function BurnupHoldingAccessControl() public {
         
        cfoAddress = msg.sender;
    }
    
     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
     
    modifier onlyBurnupGame() {
         
        require(burnupGame[msg.sender]);
        _;
    }

     
     
    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
     
     
    function addBurnupGame(address addr) external onlyOwner {
        burnupGame[addr] = true;
    }
    
     
     
    function removeBurnupGame(address addr) external onlyOwner {
        delete burnupGame[addr];
    }
}


 
contract BurnupHoldingReferral is BurnupHoldingAccessControl {

    event SetReferrer(address indexed referral, address indexed referrer);

     
    mapping (address => address) addressToReferrerAddress;
    
     
     
    function referrerOf(address player) public view returns (address) {
        return addressToReferrerAddress[player];
    }
    
     
     
     
    function _setReferrer(address playerAddr, address referrerAddr) internal {
        addressToReferrerAddress[playerAddr] = referrerAddr;
        
         
        SetReferrer(playerAddr, referrerAddr);
    }
}


 
contract BurnupHoldingCore is BurnupHoldingReferral, PullPayment {
    using SafeMath for uint256;
    
    address public beneficiary1;
    address public beneficiary2;
    
    function BurnupHoldingCore(address _beneficiary1, address _beneficiary2) public {
         
        cfoAddress = msg.sender;
        
         
        beneficiary1 = _beneficiary1;
        beneficiary2 = _beneficiary2;
    }
    
     
     
    function payBeneficiaries() external payable {
        uint256 paymentHalve = msg.value.div(2);
        
         
        uint256 otherPaymentHalve = msg.value.sub(paymentHalve);
        
         
        asyncSend(beneficiary1, paymentHalve);
        asyncSend(beneficiary2, otherPaymentHalve);
    }
    
     
     
    function setBeneficiary1(address addr) external onlyCFO {
        beneficiary1 = addr;
    }
    
     
     
    function setBeneficiary2(address addr) external onlyCFO {
        beneficiary2 = addr;
    }
    
     
     
     
    function setReferrer(address playerAddr, address referrerAddr) external onlyBurnupGame whenNotPaused returns(bool) {
        if (referrerOf(playerAddr) == address(0x0) && playerAddr != referrerAddr) {
             
             
            _setReferrer(playerAddr, referrerAddr);
            
             
            return true;
        }
        
         
        return false;
    }
}


 
contract BurnupGameFinance is BurnupGameOwnership, PullPayment {
     
    BurnupHoldingCore burnupHolding;
    
    function BurnupGameFinance(address burnupHoldingAddress) public {
        burnupHolding = BurnupHoldingCore(burnupHoldingAddress);
    }
    
     
     
    function _claimedSurroundingTiles(uint256 _deedId) internal view returns (uint256[] memory) {
        var (x, y) = identifierToCoordinate(_deedId);
        
         
        uint256 claimed = 0;
        
         
        uint256[] memory _tiles = new uint256[](8);
        
         
        for (int256 dx = -1; dx <= 1; dx++) {
            for (int256 dy = -1; dy <= 1; dy++) {
                if (dx == 0 && dy == 0) {
                     
                    continue;
                }
                
                uint256 nx = uint256(int256(x) + dx);
                uint256 ny = uint256(int256(y) + dy);
                
                if (nx >= gameSettings.cols || ny >= gameSettings.rows) {
                     
                    continue;
                }
                
                 
                uint256 neighborIdentifier = coordinateToIdentifier(
                    nx,
                    ny
                );
                
                if (gameStates[gameIndex].identifierToOwner[neighborIdentifier] != address(0x0)) {
                    _tiles[claimed] = neighborIdentifier;
                    claimed++;
                }
            }
        }
        
         
         
        uint256[] memory tiles = new uint256[](claimed);
        
        for (uint256 i = 0; i < claimed; i++) {
            tiles[i] = _tiles[i];
        }
        
        return tiles;
    }
    
     
     
    function nextBuyoutPrice(uint256 price) public view returns (uint256) {
        if (price < 0.02 ether) {
            return price.mul(200).div(100);  
        } else {
            return price.mul(gameSettings.buyoutPriceIncreasePercentage).div(100000);
        }
    }
    
     
    function _assignBuyoutProceeds(
        address currentOwner,
        uint256[] memory claimedSurroundingTiles,
        uint256 fee,
        uint256 currentOwnerWinnings,
        uint256 totalDividendPerBeneficiary,
        uint256 referralBonus,
        uint256 prizePoolFunds
    )
        internal
    {
    
        if (currentOwner != 0x0) {
             
            _sendFunds(currentOwner, currentOwnerWinnings);
        } else {
             
            uint256 prizePoolPart = currentOwnerWinnings.mul(gameSettings.firstBuyoutPrizePoolPercentage).div(100000);
            
            prizePoolFunds = prizePoolFunds.add(prizePoolPart);
            fee = fee.add(currentOwnerWinnings.sub(prizePoolPart));
        }
        
         
        for (uint256 i = 0; i < claimedSurroundingTiles.length; i++) {
            address beneficiary = gameStates[gameIndex].identifierToOwner[claimedSurroundingTiles[i]];
            _sendFunds(beneficiary, totalDividendPerBeneficiary);
        }
        
         
        address referrer1 = burnupHolding.referrerOf(msg.sender);
        if (referrer1 != 0x0) {
            _sendFunds(referrer1, referralBonus);
        
            address referrer2 = burnupHolding.referrerOf(referrer1);
            if (referrer2 != 0x0) {
                _sendFunds(referrer2, referralBonus);
            } else {
                 
                fee = fee.add(referralBonus);
            }
        } else {
             
            fee = fee.add(referralBonus.mul(2));
        }
        
         
        burnupHolding.payBeneficiaries.value(fee)();
        
         
        gameStates[gameIndex].prizePool = gameStates[gameIndex].prizePool.add(prizePoolFunds);
    }
    
     
     
    function currentPrice(uint256 _deedId) public view returns (uint256 price) {
        address currentOwner = gameStates[gameIndex].identifierToOwner[_deedId];
    
        if (currentOwner == 0x0) {
            price = gameSettings.unclaimedTilePrice;
        } else {
            price = gameStates[gameIndex].identifierToBuyoutPrice[_deedId];
        }
    }
    
     
     
     
     
    function _calculateAndAssignBuyoutProceeds(address currentOwner, uint256 price, uint256[] memory claimedSurroundingTiles)
        internal
    {
         
         
        uint256 variableDividends = price.mul(gameSettings.buyoutDividendPercentage).div(100000);
        
         
        uint256 fee            = price.mul(gameSettings.buyoutFeePercentage).div(100000);
        uint256 referralBonus  = price.mul(gameSettings.buyoutReferralBonusPercentage).div(100000);
        uint256 prizePoolFunds = price.mul(gameSettings.buyoutPrizePoolPercentage).div(100000);
        
         
        uint256 currentOwnerWinnings = price.sub(fee).sub(referralBonus.mul(2)).sub(prizePoolFunds);
        
        uint256 totalDividendPerBeneficiary;
        if (claimedSurroundingTiles.length > 0) {
             
             
             
            totalDividendPerBeneficiary = variableDividends / claimedSurroundingTiles.length;
            
             
            currentOwnerWinnings = currentOwnerWinnings.sub(totalDividendPerBeneficiary * claimedSurroundingTiles.length);
        }
        
        _assignBuyoutProceeds(
            currentOwner,
            claimedSurroundingTiles,
            fee,
            currentOwnerWinnings,
            totalDividendPerBeneficiary,
            referralBonus,
            prizePoolFunds
        );
    }
    
     
     
     
     
    function _sendFunds(address beneficiary, uint256 amount) internal {
        if (!beneficiary.send(amount)) {
             
             
             
             
             
            asyncSend(beneficiary, amount);
        }
    }
}

 
contract BurnupGameCore is BurnupGameFinance {
    
    function BurnupGameCore(address burnupHoldingAddress) public BurnupGameFinance(burnupHoldingAddress) {}
    
     
     
     
     
     
    function buyout(uint256 _gameIndex, bool startNewGameIfIdle, uint256 x, uint256 y) public payable {
         
        _processGameEnd();
        
        if (!gameStates[gameIndex].gameStarted) {
             
            require(!paused);
            
            if (allowStart) {
                 
                allowStart = false;
            } else {
                 
                require(canStart());
            }
            
             
             
            require(startNewGameIfIdle);
            
            _setGameSettings();
            
             
            gameStates[gameIndex].gameStarted = true;
            
             
            gameStates[gameIndex].gameStartTimestamp = block.timestamp;
            
             
            gameStates[gameIndex].penultimateTileTimeout = block.timestamp + gameSettings.initialActivityTimer;
            
            Start(
                gameIndex,
                msg.sender,
                block.timestamp,
                gameStates[gameIndex].prizePool
            );
            
            PenultimateTileTimeout(gameIndex, gameStates[gameIndex].penultimateTileTimeout);
        }
    
         
        if (startNewGameIfIdle) {
             
             
            require(_gameIndex == gameIndex || _gameIndex.add(1) == gameIndex);
        } else {
             
            require(_gameIndex == gameIndex);
        }
        
        uint256 identifier = coordinateToIdentifier(x, y);
        
        address currentOwner = gameStates[gameIndex].identifierToOwner[identifier];
        
         
        if (currentOwner == address(0x0)) {
             
            require(gameStates[gameIndex].gameStartTimestamp.add(gameSettings.initialActivityTimer) >= block.timestamp);
        } else {
             
            require(gameStates[gameIndex].identifierToTimeoutTimestamp[identifier] >= block.timestamp);
        }
        
         
        uint256 price = currentPrice(identifier);
        require(msg.value >= price);
        
         
        uint256[] memory claimedSurroundingTiles = _claimedSurroundingTiles(identifier);
        
         
        _calculateAndAssignBuyoutProceeds(currentOwner, price, claimedSurroundingTiles);
        
         
        uint256 timeout = tileTimeoutTimestamp(identifier, msg.sender);
        gameStates[gameIndex].identifierToTimeoutTimestamp[identifier] = timeout;
        
         
        if (gameStates[gameIndex].lastTile == 0 || timeout >= gameStates[gameIndex].identifierToTimeoutTimestamp[gameStates[gameIndex].lastTile]) {
            if (gameStates[gameIndex].lastTile != identifier) {
                if (gameStates[gameIndex].lastTile != 0) {
                     
                    gameStates[gameIndex].penultimateTileTimeout = gameStates[gameIndex].identifierToTimeoutTimestamp[gameStates[gameIndex].lastTile];
                    PenultimateTileTimeout(gameIndex, gameStates[gameIndex].penultimateTileTimeout);
                }
            
                gameStates[gameIndex].lastTile = identifier;
                LastTile(gameIndex, identifier, x, y);
            }
        } else if (timeout > gameStates[gameIndex].penultimateTileTimeout) {
            gameStates[gameIndex].penultimateTileTimeout = timeout;
            
            PenultimateTileTimeout(gameIndex, timeout);
        }
        
         
        _transfer(currentOwner, msg.sender, identifier);
        
         
        gameStates[gameIndex].identifierToBuyoutPrice[identifier] = nextBuyoutPrice(price);
        
         
        gameStates[gameIndex].numberOfTileFlips++;
        
         
        Buyout(gameIndex, msg.sender, identifier, x, y, block.timestamp, timeout, gameStates[gameIndex].identifierToBuyoutPrice[identifier], gameStates[gameIndex].prizePool);
        
         
         
         
        uint256 excess = msg.value - price;
        
        if (excess > 0) {
             
             
            msg.sender.transfer(excess);
        }
    }
    
     
     
     
     
     
    function buyoutAndSetReferrer(uint256 _gameIndex, bool startNewGameIfIdle, uint256 x, uint256 y, address referrerAddress) external payable {
         
        burnupHolding.setReferrer(msg.sender, referrerAddress);
    
         
        buyout(_gameIndex, startNewGameIfIdle, x, y);
    }
    
     
     
     
    function spiceUp(uint256 _gameIndex, string message) external payable {
         
        _processGameEnd();
        
         
        require(_gameIndex == gameIndex);
    
         
        require(gameStates[gameIndex].gameStarted || !paused);
        
         
        require(msg.value > 0);
        
         
        gameStates[gameIndex].prizePool = gameStates[gameIndex].prizePool.add(msg.value);
        
         
        SpiceUpPrizePool(gameIndex, msg.sender, msg.value, message, gameStates[gameIndex].prizePool);
    }
    
     
    function endGame() external {
        require(_processGameEnd());
    }
    
     
    function _processGameEnd() internal returns(bool) {
         
        if (!gameStates[gameIndex].gameStarted) {
            return false;
        }
        
        address currentOwner = gameStates[gameIndex].identifierToOwner[gameStates[gameIndex].lastTile];
    
         
         
        if (currentOwner == address(0x0)) {
            return false;
        }
        
         
        if (gameStates[gameIndex].penultimateTileTimeout >= block.timestamp) {
            return false;
        }
        
         
        if (gameStates[gameIndex].prizePool > 0) {
            _sendFunds(currentOwner, gameStates[gameIndex].prizePool);
        }
        
         
        var (x, y) = identifierToCoordinate(gameStates[gameIndex].lastTile);
        
         
        End(gameIndex, currentOwner, gameStates[gameIndex].lastTile, x, y, gameStates[gameIndex].identifierToTimeoutTimestamp[gameStates[gameIndex].lastTile], gameStates[gameIndex].prizePool);
        
         
        gameIndex++;
        
         
        return true;
    }
}