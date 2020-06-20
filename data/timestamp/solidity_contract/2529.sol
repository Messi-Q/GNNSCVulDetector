pragma solidity ^0.4.18;


contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract DefconPro is Ownable {
  event Defcon(uint64 blockNumber, uint16 defconLevel);

  uint16 public defcon = 5; 

   
  modifier defcon4() { 
    require(defcon > 4);
    _;
  }

   
  modifier defcon3() {
    require(defcon > 3);
    _;
  }
  
   
   modifier defcon2() {
    require(defcon > 2);
    _;
  }
  
   
  modifier defcon1() { 
    require(defcon > 1);
    _;
  }

   
  function setDefconLevel(uint16 _defcon) onlyOwner public {
    defcon = _defcon;
    Defcon(uint64(block.number), _defcon);
  }

}


contract bigBankLittleBank is DefconPro {
    
    using SafeMath for uint;
    
    uint public houseFee = 2;  
    uint public houseCommission = 0;  
    uint public bookKeeper = 0;  
    
    bytes32 emptyBet = 0x0000000000000000000000000000000000000000000000000000000000000000;
    
     
    event BigBankBet(uint blockNumber, address indexed winner, address indexed loser, uint winningBetId1, uint losingBetId2, uint total);
     
    event Deposit(address indexed user, uint amount);
     
    event Withdraw(address indexed user, uint amount);
    
     
    BetBank[] private betBanks;
    
     
    struct BetBank {
        bytes32 bet;
        address owner;
    }
 
     
    function userBalance() public view returns(uint) {
        return userBank[msg.sender];
    }
    
     
    mapping (address => uint) public userBank;

     
    function depositBank() public defcon4 payable {
        if(userBank[msg.sender] == 0) { 
            userBank[msg.sender] = msg.value; 
        } else {
            userBank[msg.sender] = (userBank[msg.sender]).add(msg.value); 
        }
        bookKeeper = bookKeeper.add(msg.value); 
        Deposit(msg.sender, msg.value); 
    }
    
     
    function withdrawBank(uint amount) public defcon2 returns(bool) {
        require(userBank[msg.sender] >= amount); 
        bookKeeper = bookKeeper.sub(amount); 
        userBank[msg.sender] = userBank[msg.sender].sub(amount); 
        Withdraw(msg.sender, amount); 
        (msg.sender).transfer(amount); 
        return true;
    }
    
     
    function startBet(uint _bet) public defcon3 returns(uint betId) {
        require(userBank[msg.sender] >= _bet); 
        require(_bet > 0);
        userBank[msg.sender] = (userBank[msg.sender]).sub(_bet); 
        uint convertedAddr = uint(msg.sender);
        uint combinedBet = convertedAddr.add(_bet)*7;
        BetBank memory betBank = BetBank({ 
            bet: bytes32(combinedBet), 
            owner: msg.sender
        });
         
        betId = betBanks.push(betBank).sub(1); 
    }
   
     
    function _endBetListing(uint betId) private returns(bool){
        delete betBanks[betId]; 
    }
    
     
    function betAgainstUser(uint _betId1, uint _betId2) public defcon3 returns(bool){
        require(betBanks[_betId1].bet != emptyBet && betBanks[_betId2].bet != emptyBet); 
        require(betBanks[_betId1].owner == msg.sender || betBanks[_betId2].owner == msg.sender);  
        require(betBanks[_betId1].owner != betBanks[_betId2].owner); 
        require(_betId1 != _betId2); 
    
         
        uint bet1ConvertedAddr = uint(betBanks[_betId1].owner);
        uint bet1 = (uint(betBanks[_betId1].bet)/7).sub(bet1ConvertedAddr);
        uint bet2ConvertedAddr = uint(betBanks[_betId2].owner);
        uint bet2 = (uint(betBanks[_betId2].bet)/7).sub(bet2ConvertedAddr);  
        
        uint take = (bet1).add(bet2); 
        uint fee = (take.mul(houseFee)).div(100); 
        houseCommission = houseCommission.add(fee); 
        if(bet1 != bet2) { 
            if(bet1 > bet2) { 
                _payoutWinner(_betId1, _betId2, take, fee); 
            } else {
                _payoutWinner(_betId2, _betId1, take, fee); 
            }
        } else { 
            if(_random() == 0) { 
                _payoutWinner(_betId1, _betId2, take, fee); 
            } else {
                _payoutWinner(_betId2, _betId1, take, fee); 
            }
        }
        return true;
    }

     
    function _payoutWinner(uint winner, uint loser, uint take, uint fee) private returns(bool) {
        BigBankBet(block.number, betBanks[winner].owner, betBanks[loser].owner, winner, loser, take.sub(fee)); 
        address winnerAddr = betBanks[winner].owner; 
        _endBetListing(winner); 
        _endBetListing(loser); 
        userBank[winnerAddr] = (userBank[winnerAddr]).add(take.sub(fee)); 
        return true;
    }
    
     
    function setHouseFee(uint newFee)public onlyOwner returns(bool) {
        require(msg.sender == owner); 
        houseFee = newFee; 
        return true;
    }
    
     
    function withdrawCommission()public onlyOwner returns(bool) {
        require(msg.sender == owner); 
        bookKeeper = bookKeeper.sub(houseCommission); 
        uint holding = houseCommission; 
        houseCommission = 0; 
        owner.transfer(holding); 
        return true;
    }
    
     
    function _random() private view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty))%2);
    }
    
     
    function _totalActiveBets() private view returns(uint total) {
        total = 0;
        for(uint i=0; i<betBanks.length; i++) { 
            if(betBanks[i].bet != emptyBet && betBanks[i].owner != msg.sender) { 
                total++; 
            }
        }
    }
    
     
    function listActiveBets() public view returns(uint[]) {
        uint256 total = _totalActiveBets();
        if (total == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](total);
            uint rc = 0;
            for (uint idx=0; idx < betBanks.length; idx++) { 
                if(betBanks[idx].bet != emptyBet && betBanks[idx].owner != msg.sender) { 
                    result[rc] = idx; 
                    rc++;
                }
            }
        }
        return result;
    }
    
     
    function _totalUsersBets() private view returns(uint total) {
        total = 0;
        for(uint i=0; i<betBanks.length; i++) { 
            if(betBanks[i].owner == msg.sender && betBanks[i].bet != emptyBet) { 
                total++; 
            }
        }
    }
    
     
    function listUsersBets() public view returns(uint[]) {
        uint256 total = _totalUsersBets();
        if (total == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](total);
            uint rc = 0;
            for (uint idx=0; idx < betBanks.length; idx++) { 
                if(betBanks[idx].owner == msg.sender && betBanks[idx].bet != emptyBet) { 
                    result[rc] = idx; 
                    rc++;
                }
            }
        }
        return result;
    }
    
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