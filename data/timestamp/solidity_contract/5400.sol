pragma solidity ^0.4.8;

contract RuletkaIo {
    
     
    
     
     
     
    event partyOver(uint256 roomId, address victim, address[] winners);

     
    event newPlayer(uint256 roomId, address player);
    
     
    event fullRoom(uint256 roomId);
    
     
    event  roomRefunded(uint256 _roomId, address[] refundedPlayers);

     
    address CTO;
    address CEO;
    
     Room[] private allRooms;

    function () public payable {}  

    function RuletkaIo() public {
        CTO = msg.sender;
        CEO = msg.sender;
    }
    
     
     
    modifier onlyCTO() {
        require(msg.sender == CTO);
        _;
    }
    
     
     
    function setCTO(address _newCTO) public onlyCTO {
        require(_newCTO != address(0));
        CTO = _newCTO;
    }
    
     
     
    function setCEO(address _newCEO) public onlyCTO {
        require(_newCEO != address(0));
        CEO = _newCEO;
    }
    
     
      struct Room {
        string name;
        uint256 entryPrice;  
        uint256 balance;
        address[] players;
      }
    
    
     
  function createRoom(string _name, uint256 _entryPrice) public onlyCTO{
    address[] memory players;
    Room memory _room = Room({
      name: _name,
      players: players,
      balance: 0,
      entryPrice: _entryPrice
    });

    allRooms.push(_room);
  }
    
    function enter(uint256 _roomId) public payable {
        Room storage room = allRooms[_roomId-1];  
        
        require(room.players.length < 6);
        require(msg.value >= room.entryPrice);
        
        room.players.push(msg.sender);
        room.balance += room.entryPrice;
        
        emit newPlayer(_roomId, msg.sender);
        
        if(room.players.length == 6){
            executeRoom(_roomId);
        }
    }
    
    function enterWithReferral(uint256 _roomId, address referrer) public payable {
        
        Room storage room = allRooms[_roomId-1];  
        
        require(room.players.length < 6);
        require(msg.value >= room.entryPrice);
        
        uint256 referrerCut = SafeMath.div(room.entryPrice, 100);  
        referrer.transfer(referrerCut);
         
        room.players.push(msg.sender);
        room.balance += room.entryPrice - referrerCut;
        
        emit newPlayer(_roomId, msg.sender);
        
        if(room.players.length == 6){
            emit fullRoom(_roomId);
            executeRoom(_roomId);
        }
    }
    
    function executeRoom(uint256 _roomId) public {
        
        Room storage room = allRooms[_roomId-1];  
        
         
        require(room.players.length == 6);
        
        uint256 halfFee = SafeMath.div(room.entryPrice, 20);
        CTO.transfer(halfFee);
        CEO.transfer(halfFee);
        room.balance -= halfFee * 2;
        
        uint256 deadSeat = random();
        
        distributeFunds(_roomId, deadSeat);
        
        delete room.players;
    }
    
    function distributeFunds(uint256 _roomId, uint256 _deadSeat) private returns(uint256) {
        
        Room storage room = allRooms[_roomId-1];  
        uint256 balanceToDistribute = SafeMath.div(room.balance,5);
        
        address victim = room.players[_deadSeat];
        address[] memory winners = new address[](5);
        uint256 j = 0; 
        for (uint i = 0; i<6; i++) {
            if(i != _deadSeat){
               room.players[i].transfer(balanceToDistribute);
               room.balance -= balanceToDistribute;
               winners[j] = room.players[i];
               j++;
            }
        }
        
        emit partyOver(_roomId, victim, winners);
       
        return address(this).balance;
    }
    
      
     
    function refundPlayersInRoom(uint256 _roomId) public onlyCTO{
        Room storage room = allRooms[_roomId-1];  
        uint256 nbrOfPlayers = room.players.length;
        uint256 balanceToRefund = SafeMath.div(room.balance,nbrOfPlayers);
        for (uint i = 0; i<nbrOfPlayers; i++) {
             room.players[i].transfer(balanceToRefund);
             room.balance -= balanceToRefund;
        }
        
        emit roomRefunded(_roomId, room.players);
        delete room.players;
    }
    
    
     
     
     
     
     
    function random() private view returns (uint256) {
        return uint256(uint256(keccak256(block.timestamp, block.difficulty))%6);
    }
    
    function getRoom(uint256 _roomId) public view returns (
    string name,
    address[] players,
    uint256 entryPrice,
    uint256 balance
  ) {
    Room storage room = allRooms[_roomId-1];
    name = room.name;
    players = room.players;
    entryPrice = room.entryPrice;
    balance = room.balance;
  }
  
  function payout(address _to) public onlyCTO {
    _payout(_to);
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      CTO.transfer(SafeMath.div(address(this).balance, 2));
      CEO.transfer(address(this).balance);
    } else {
      _to.transfer(address(this).balance);
    }
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