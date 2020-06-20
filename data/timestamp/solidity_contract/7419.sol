pragma solidity ^0.4.0;

contract SponsoredItemGooRaffle {
    
    Goo goo = Goo(0x57b116da40f21f91aec57329ecb763d29c1b2355);
    
    address owner;
    
     
    mapping(address => TicketPurchases) private ticketsBoughtByPlayer;
    mapping(uint256 => address[]) private rafflePlayers;

     
    uint256 private constant RAFFLE_TICKET_BASE_GOO_PRICE = 1000;
    uint256 private raffleEndTime;
    uint256 private raffleTicketsBought;
    uint256 private raffleId;
    address private raffleWinner;
    bool private raffleWinningTicketSelected;
    uint256 private raffleTicketThatWon;
    
    
     
    struct TicketPurchases {
        TicketPurchase[] ticketsBought;
        uint256 numPurchases;  
        uint256 raffleId;
    }
    
     
    struct TicketPurchase {
        uint256 startId;
        uint256 endId;
    }
    
    function SponsoredItemGooRaffle() public {
        owner = msg.sender;
    }
    
    function startTokenRaffle(uint256 endTime, address tokenContract, uint256 id, bool hasItemAlready) external {
        require(msg.sender == owner);
        require(block.timestamp < endTime);
        
        if (raffleId != 0) {  
            require(raffleWinner != 0);
        }
        
         
        raffleWinningTicketSelected = false;
        raffleTicketThatWon = 0;
        raffleWinner = 0;
        raffleTicketsBought = 0;
        
         
        raffleEndTime = endTime;
        raffleId++;
    }
    

    function buyRaffleTicket(uint256 amount) external {
        require(raffleEndTime >= block.timestamp);
        require(amount > 0);
        
        uint256 ticketsCost = SafeMath.mul(RAFFLE_TICKET_BASE_GOO_PRICE, amount);
        goo.transferFrom(msg.sender, this, ticketsCost);
         
        goo.transfer(address(0), (ticketsCost * 95) / 100);
        
         
        TicketPurchases storage purchases = ticketsBoughtByPlayer[msg.sender];
        
         
        if (purchases.raffleId != raffleId) {
            purchases.numPurchases = 0;
            purchases.raffleId = raffleId;
            rafflePlayers[raffleId].push(msg.sender);  
        }
        
         
        if (purchases.numPurchases == purchases.ticketsBought.length) {
            purchases.ticketsBought.length += 1;
        }
        purchases.ticketsBought[purchases.numPurchases++] = TicketPurchase(raffleTicketsBought, raffleTicketsBought + (amount - 1));  
        
         
        raffleTicketsBought += amount;
    }
    
    function awardRafflePrize(address checkWinner, uint256 checkIndex) external {
        require(raffleEndTime < block.timestamp);
        require(raffleWinner == 0);
        
        if (!raffleWinningTicketSelected) {
            drawRandomWinner();  
        }
        
         
        if (checkWinner != 0) {
            TicketPurchases storage tickets = ticketsBoughtByPlayer[checkWinner];
            if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.raffleId == raffleId) {
                TicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
                if (raffleTicketThatWon >= checkTicket.startId && raffleTicketThatWon <= checkTicket.endId) {
                    assignRaffleWinner(checkWinner);  
                    return;
                }
            }
        }
        
         
        for (uint256 i = 0; i < rafflePlayers[raffleId].length; i++) {
            address player = rafflePlayers[raffleId][i];
            TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
            
            uint256 endIndex = playersTickets.numPurchases - 1;
             
            if (raffleTicketThatWon >= playersTickets.ticketsBought[0].startId && raffleTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
                for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
                    TicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
                    if (raffleTicketThatWon >= playerTicket.startId && raffleTicketThatWon <= playerTicket.endId) {
                        assignRaffleWinner(player);  
                        return;
                    }
                }
            }
        }
    }
    
    function assignRaffleWinner(address winner) internal {
        raffleWinner = winner;
    }
    
     
    function drawRandomWinner() public {
        require(msg.sender == owner);
        require(raffleEndTime < block.timestamp);
        require(!raffleWinningTicketSelected);
        
        uint256 seed = raffleTicketsBought + block.timestamp;
        raffleTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, (raffleTicketsBought + 1));
        raffleWinningTicketSelected = true;
    }
    
     
    function transferGoo(address recipient, uint256 amount) external {
        require(msg.sender == owner);
        goo.transfer(recipient, amount);
    }
    
      
    function getLatestRaffleInfo() external constant returns (uint256, uint256, uint256, address, uint256) {
        return (raffleEndTime, raffleId, raffleTicketsBought, raffleWinner, raffleTicketThatWon);
    }
    
     
    function getRafflePlayers(uint256 raffle) external constant returns (address[]) {
        return (rafflePlayers[raffle]);
    }
    
      
    function getPlayersTickets(address player) external constant returns (uint256[], uint256[]) {
        TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
        
        if (playersTickets.raffleId == raffleId) {
            uint256[] memory startIds = new uint256[](playersTickets.numPurchases);
            uint256[] memory endIds = new uint256[](playersTickets.numPurchases);
            
            for (uint256 i = 0; i < playersTickets.numPurchases; i++) {
                startIds[i] = playersTickets.ticketsBought[i].startId;
                endIds[i] = playersTickets.ticketsBought[i].endId;
            }
        }
        
        return (startIds, endIds);
    }
}


interface Goo {
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
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