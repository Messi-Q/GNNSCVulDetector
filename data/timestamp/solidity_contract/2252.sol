pragma solidity ^0.4.18;
 
 
 
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

contract AccessAdmin is Ownable {

   
  mapping (address => bool) adminContracts;

   
  mapping (address => bool) actionContracts;

  function setAdminContract(address _addr, bool _useful) public onlyOwner {
    require(_addr != address(0));
    adminContracts[_addr] = _useful;
  }

  modifier onlyAdmin {
    require(adminContracts[msg.sender]); 
    _;
  }

  function setActionContract(address _actionAddr, bool _useful) public onlyAdmin {
    actionContracts[_actionAddr] = _useful;
  }

  modifier onlyAccess() {
    require(actionContracts[msg.sender]);
    _;
  }
}

interface CardsInterface {
  function balanceOf(address player) public constant returns(uint256);
  function updatePlayersCoinByOut(address player) external;
  function updatePlayersCoinByPurchase(address player, uint256 purchaseCost) public;
  function removeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external;
  function upgradeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external;
}
interface RareInterface {
  function getRareItemsOwner(uint256 rareId) external view returns (address);
  function getRareItemsPrice(uint256 rareId) external view returns (uint256);
    function getRareInfo(uint256 _tokenId) external view returns (
    uint256 sellingPrice,
    address owner,
    uint256 nextPrice,
    uint256 rareClass,
    uint256 cardId,
    uint256 rareValue
  ); 
  function transferToken(address _from, address _to, uint256 _tokenId) external;
  function transferTokenByContract(uint256 _tokenId,address _to) external;
  function setRarePrice(uint256 _rareId, uint256 _price) external;
  function rareStartPrice() external view returns (uint256);
}
contract CardsRaffle is AccessAdmin {
  using SafeMath for SafeMath;

  function CardsRaffle() public {
    setAdminContract(msg.sender,true);
    setActionContract(msg.sender,true);
  }
   
  CardsInterface public cards ;
  RareInterface public rare;

  function setCardsAddress(address _address) external onlyOwner {
    cards = CardsInterface(_address);
  }

   
  function setRareAddress(address _address) external onlyOwner {
    rare = RareInterface(_address);
  }

  function getRareAddress() public view returns (address) {
    return rare;
  }

   
  event UnitBought(address player, uint256 unitId, uint256 amount);
  event RaffleSuccessful(address winner);

   
  struct TicketPurchases {
    TicketPurchase[] ticketsBought;
    uint256 numPurchases;  
    uint256 raffleRareId;
  }
    
   
  struct TicketPurchase {
    uint256 startId;
    uint256 endId;
  }
    
   
  mapping(address => TicketPurchases) private ticketsBoughtByPlayer;
  mapping(uint256 => address[]) private rafflePlayers;  

  uint256 private constant RAFFLE_TICKET_BASE_PRICE = 10000;
  uint256 private constant MAX_LIMIT = 1000;

   
  uint256 private raffleEndTime;
  uint256 private raffleRareId;
  uint256 private raffleTicketsBought;
  address private raffleWinner;  
  bool private raffleWinningTicketSelected;
  uint256 private raffleTicketThatWon;

   
  function buyRaffleTicket(uint256 amount) external {
    require(raffleEndTime >= block.timestamp);   
    require(amount > 0 && amount<=MAX_LIMIT);
        
    uint256 ticketsCost = SafeMath.mul(RAFFLE_TICKET_BASE_PRICE, amount);
    require(cards.balanceOf(msg.sender) >= ticketsCost);
        
     
    cards.updatePlayersCoinByPurchase(msg.sender, ticketsCost);
        
     
    TicketPurchases storage purchases = ticketsBoughtByPlayer[msg.sender];
        
     
    if (purchases.raffleRareId != raffleRareId) {
      purchases.numPurchases = 0;
      purchases.raffleRareId = raffleRareId;
      rafflePlayers[raffleRareId].push(msg.sender);  
    }
        
     
    if (purchases.numPurchases == purchases.ticketsBought.length) {
      purchases.ticketsBought.length = SafeMath.add(purchases.ticketsBought.length,1);
    }
    purchases.ticketsBought[purchases.numPurchases++] = TicketPurchase(raffleTicketsBought, raffleTicketsBought + (amount - 1));  
        
     
    raffleTicketsBought = SafeMath.add(raffleTicketsBought,amount);
     
    UnitBought(msg.sender,raffleRareId,amount);
  } 

   
  function startRareRaffle(uint256 endTime, uint256 rareId) external onlyAdmin {
    require(rareId>0);
    require(rare.getRareItemsOwner(rareId) == getRareAddress());
    require(block.timestamp < endTime);  

    if (raffleRareId != 0) {  
      require(raffleWinner != 0);
    }

     
    raffleWinningTicketSelected = false;
    raffleTicketThatWon = 0;
    raffleWinner = 0;
    raffleTicketsBought = 0;
        
     
    raffleEndTime = endTime;
    raffleRareId = rareId;
  }

  function awardRafflePrize(address checkWinner, uint256 checkIndex) external { 
    require(raffleEndTime < block.timestamp);   
    require(raffleWinner == 0);
    require(rare.getRareItemsOwner(raffleRareId) == getRareAddress());
        
    if (!raffleWinningTicketSelected) {
      drawRandomWinner();  
    }
        
   
    if (checkWinner != 0) {
      TicketPurchases storage tickets = ticketsBoughtByPlayer[checkWinner];
      if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.raffleRareId == raffleRareId) {
        TicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
        if (raffleTicketThatWon >= checkTicket.startId && raffleTicketThatWon <= checkTicket.endId) {
          assignRafflePrize(checkWinner);  
          return;
        }
      }
    }
        
   
    for (uint256 i = 0; i < rafflePlayers[raffleRareId].length; i++) {
      address player = rafflePlayers[raffleRareId][i];
      TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
            
      uint256 endIndex = playersTickets.numPurchases - 1;
       
      if (raffleTicketThatWon >= playersTickets.ticketsBought[0].startId && raffleTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
        for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
          TicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
          if (raffleTicketThatWon >= playerTicket.startId && raffleTicketThatWon <= playerTicket.endId) {
            assignRafflePrize(player);  
            return;
          }
        }
      }
    }
  }

  function assignRafflePrize(address winner) internal {
    raffleWinner = winner;
    uint256 newPrice = (rare.rareStartPrice() * 25) / 20;
    rare.transferTokenByContract(raffleRareId,winner);
    rare.setRarePrice(raffleRareId,newPrice);
       
    cards.updatePlayersCoinByOut(winner);
    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    (,,,,upgradeClass, unitId, upgradeValue) = rare.getRareInfo(raffleRareId);
    
    cards.upgradeUnitMultipliers(winner, upgradeClass, unitId, upgradeValue);
     
    RaffleSuccessful(winner);
  }
  
   
  function drawRandomWinner() public onlyAdmin {
    require(raffleEndTime < block.timestamp);  
    require(!raffleWinningTicketSelected);
        
    uint256 seed = SafeMath.add(raffleTicketsBought , block.timestamp);
    raffleTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, raffleTicketsBought);
    raffleWinningTicketSelected = true;
  }  

   
  function getRafflePlayers(uint256 raffleId) external constant returns (address[]) {
    return (rafflePlayers[raffleId]);
  }

     
  function getPlayersTickets(address player) external constant returns (uint256[], uint256[]) {
    TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
        
    if (playersTickets.raffleRareId == raffleRareId) {
      uint256[] memory startIds = new uint256[](playersTickets.numPurchases);
      uint256[] memory endIds = new uint256[](playersTickets.numPurchases);
            
      for (uint256 i = 0; i < playersTickets.numPurchases; i++) {
        startIds[i] = playersTickets.ticketsBought[i].startId;
        endIds[i] = playersTickets.ticketsBought[i].endId;
      }
    }
        
    return (startIds, endIds);
  }


   
  function getLatestRaffleInfo() external constant returns (uint256, uint256, uint256, address, uint256) {
    return (raffleEndTime, raffleRareId, raffleTicketsBought, raffleWinner, raffleTicketThatWon);
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