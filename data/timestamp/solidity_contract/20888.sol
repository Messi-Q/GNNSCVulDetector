pragma solidity ^0.4.21;
 
 

contract GameState{
     
    uint256[3] RoundTimes = [(5 minutes), (20 minutes), (10 minutes)];  
    uint256[3] NextRound = [1,2,0];  
    

     
 
  
   
   
    
    
    uint256 public CurrentGame = 0;
   
    
    uint256 public Timestamp = 0;

    function() payable{

    }
    
    function Timer() internal view returns (bool){
        if (block.timestamp < Timestamp){
        
            return (true);
        }
        return false;
    }
    
     
     
    function Start() internal {
        Timestamp = block.timestamp + RoundTimes[CurrentGame];
    }
    
    function Next(bool StartNow) internal {
        uint256 NextRoundBuffer = NextRound[CurrentGame];
        if (StartNow){
             
            
            Timestamp = Timestamp + RoundTimes[NextRoundBuffer];
        }
        else{
            
        }
        CurrentGame = NextRoundBuffer;
    }
    
  
   
   
    
    
    
     
     
     
    
    


}

contract ServiceStation is GameState{
  
    uint256 public Votes = 0;
    uint256 public constant VotesNecessary = 6;  
    uint256 public constant devFee = 500;  
    
    address owner;
     
     
     
     
     
     
     
     
    address constant fee_address = 0x3323075B8D3c471631A004CcC5DAD0EEAbc5B4D1; 
    
    
    event NewVote(uint256 AllVotes);
    event VoteStarted();
    event ItemBought(uint256 ItemID, address OldOwner, address NewOwner, uint256 NewPrice, uint256 FlipAmount);
    event JackpotChange(uint256 HighJP, uint256 LowJP);
    event OutGassed(bool HighGame, uint256 NewGas, address WhoGassed, address NewGasser);
    event Paid(address Paid, uint256 Amount);
    
    
    modifier OnlyDev(){
        require(msg.sender==owner);
        _;
    }
    
    modifier OnlyState(uint256 id){
        require (CurrentGame == id);
        _;
    }
    
     
    modifier OnlyStateOR(uint256 id, uint256 id2){
        require (CurrentGame == id || CurrentGame == id2);
        _;
    }
    
     
     
    modifier NoContract(){
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0);
        _;
    }
    
    function ServiceStation() public {
        owner = msg.sender;
    }
    
     
     
    
    function Vote() public NoContract OnlyStateOR(0,2) {
        bool StillOpen;
        if (CurrentGame == 2){
            StillOpen = Timer();
            if (StillOpen){
                revert();  
            }
            else{
                Next(false);  
            }
        }
        StillOpen = Timer();
        if (!StillOpen){
            emit VoteStarted();
            Start();
            Votes=0;
        }
        if ((Votes+1)>= VotesNecessary){
            GameStart();
        }
        else{
            Votes++;
        }
        emit NewVote(Votes);
    }
    
    function DevForceOpen() public NoContract OnlyState(0) OnlyDev {
        emit NewVote(VotesNecessary);
        Timestamp = now;  
        GameStart();
    }
    
     
     
    
    function GameStart() internal OnlyState(0){
        RoundNumber++;
        Votes = 0;
         
        Withdraw();
        Next(true);
        TotalPot = address(this).balance;
    }

    
    uint256 RoundNumber = 0;
    uint256 constant MaxItems = 11;  
    uint256 constant StartPrice = (0.005 ether);
    uint256 constant PriceIncrease = 9750;
    uint256 constant PotPaidTotal = 8000;
    uint256 constant PotPaidHigh = 9000;
    uint256 constant PreviousPaid = 6500;
    uint256 public TotalPot;
    
     
     
    mapping(address => bool) LowJackpot;
    mapping(address => uint256) HighJackpot;
    mapping(address => uint256) CurrentRound;
    
    address public LowJackpotHolder;
    address public HighJackpotHolder;
    
    uint256 CurrTimeHigh; 
    uint256 CurrTimeLow;
    
    uint256 public LowGasAmount;
    uint256 public HighGasAmount;
    
    
    struct Item{
        address holder;
        uint256 price;
    }
    
    mapping(uint256 => Item) Market;
    

     
    function GetJackpots() public view returns (uint256, uint256){
        uint256 PotPaidRound = (TotalPot * PotPaidTotal)/10000;
        uint256 HighJP = (PotPaidRound * PotPaidHigh)/10000;
        uint256 LowJP = (PotPaidRound * (10000 - PotPaidHigh))/10000;
        return (HighJP, LowJP);
    }
    
    function GetItemInfo(uint256 ID) public view returns (uint256, address){
        Item memory targetItem = Market[ID];
        return (targetItem.price, targetItem.holder);
    }
    

    function BuyItem(uint256 ID) public payable NoContract OnlyState(1){
        require(ID <= MaxItems);
        bool StillOpen = Timer();
        if (!StillOpen){
            revert();
             
             
             
        }
        uint256 price = Market[ID].price;
        if (price == 0){
            price = StartPrice;
        }
        require(msg.value >= price);
         
        if (msg.value > price){
            msg.sender.transfer(msg.value-price);
        }
       
        
         
        
        uint256 Fee = (price * (devFee))/10000;
        uint256 Left = price - Fee;
        
         
        fee_address.transfer(Fee);
        
        if (price != StartPrice){
             
            address target = Market[ID].holder;
            uint256 payment = (price * PreviousPaid)/10000;
            target.transfer (payment);
            
            if (target != msg.sender){
                if (HighJackpot[target] >= 1){
                     
                     
                     
                    HighJackpot[target] = HighJackpot[target] - 1;
                }
            }

             
            TotalPot = TotalPot + Left - payment;
            
            emit ItemBought(ID, target, msg.sender, (price * (PriceIncrease + 10000))/10000, payment);
        }
        else{
             
             
            TotalPot = TotalPot + Left;
            emit ItemBought(ID, address(0x0), msg.sender, (price * (PriceIncrease + 10000))/10000, 0);
        }
        
        uint256 PotPaidRound = (TotalPot * PotPaidTotal)/10000;
        emit JackpotChange((PotPaidRound * PotPaidHigh)/10000, (PotPaidRound * (10000 - PotPaidHigh))/10000);
        
        
        
         
        LowJackpot[msg.sender] = true;
        
         
        
        price = (price * (PriceIncrease + 10000))/10000;
        
         
        if (CurrentRound[msg.sender] != RoundNumber){
             
            if (HighJackpot[msg.sender] != 1){
                HighJackpot[msg.sender] = 1;
            }
            CurrentRound[msg.sender] = RoundNumber;
            
        }
        else{
            HighJackpot[msg.sender] = HighJackpot[msg.sender] + 1;
        }

        Market[ID].holder = msg.sender;
        Market[ID].price = price;
    }
    
    
    
    
     
    
     
    function GetGameType(address targ) public view returns (bool, bool){
        if (CurrentRound[targ] != RoundNumber){
             
            return (false,false);
        }
        else{
            
            if (HighJackpot[targ] > 0){
                 
                return (true, true);
            }
            else{
                if (LowJackpot[targ]){
                     
                    return (true, false);
                }
            }
            
            
        }
         
        return (false, false);
    }
    
    
    
     
    function BurnGas() public NoContract OnlyStateOR(2,1) {
        bool StillOpen;
       if (CurrentGame == 1){
           StillOpen = Timer();
           if (!StillOpen){
               Next(true);  
           }
           else{
               revert();  
           }
       } 
       StillOpen = Timer();
       if (!StillOpen){
           Next(true);
           Withdraw();
           return;
       }
       bool CanPlay;
       bool IsPremium;
       (CanPlay, IsPremium) = GetGameType(msg.sender);
       require(CanPlay); 
       
       uint256 AllPot = (TotalPot * PotPaidTotal)/10000;
       uint256 PotTarget;
       

       
       uint256 timespent;
       uint256 payment;
       
       if (IsPremium){
           PotTarget = (AllPot * PotPaidHigh)/10000;
           if (HighGasAmount == 0 || tx.gasprice < HighGasAmount){
               if (HighGasAmount == 0){
                   emit OutGassed(true, tx.gasprice, address(0x0), msg.sender);
               }
               else{
                   timespent = now - CurrTimeHigh;
                   payment = (PotTarget * timespent) / RoundTimes[2];  
                   HighJackpotHolder.transfer(payment);
                   emit OutGassed(true, tx.gasprice, HighJackpotHolder, msg.sender);
                   emit Paid(HighJackpotHolder, payment);
               }
               HighGasAmount = tx.gasprice;
               CurrTimeHigh = now;
               HighJackpotHolder = msg.sender;
           }
       }
       else{
           PotTarget = (AllPot * (10000 - PotPaidHigh)) / 10000;
           
            if (LowGasAmount == 0 || tx.gasprice < LowGasAmount){
               if (LowGasAmount == 0){
                    emit OutGassed(false, tx.gasprice, address(0x0), msg.sender);
               }
               else{
                   timespent = now - CurrTimeLow;
                   payment = (PotTarget * timespent) / RoundTimes[2];  
                   LowJackpotHolder.transfer(payment);
                   emit OutGassed(false, tx.gasprice, LowJackpotHolder, msg.sender);
                   emit Paid(LowJackpotHolder, payment);
               }
               LowGasAmount = tx.gasprice;
               CurrTimeLow = now;
               LowJackpotHolder = msg.sender;
            }
       }
       
      
       
  
    }
    
    function Withdraw() public NoContract OnlyStateOR(0,2){
        bool gonext = false;
        if (CurrentGame == 2){
            bool StillOpen;
            StillOpen = Timer();
            if (!StillOpen){
                gonext = true;
            }
            else{
                revert();  
            }
        }
        uint256 timespent;
        uint256 payment;
        uint256 AllPot = (TotalPot * PotPaidTotal)/10000;
        uint256 PotTarget;
        if (LowGasAmount != 0){
            PotTarget = (AllPot * (10000 - PotPaidHigh))/10000;
            timespent = Timestamp - CurrTimeLow;
            payment = (PotTarget * timespent) / RoundTimes[2];  
            LowJackpotHolder.transfer(payment);     
            emit Paid(LowJackpotHolder, payment);
        }
        if (HighGasAmount != 0){
            PotTarget = (AllPot * PotPaidHigh)/10000;
            timespent = Timestamp - CurrTimeHigh;
            payment = (PotTarget * timespent) / RoundTimes[2];  
            HighJackpotHolder.transfer(payment);
            emit Paid(HighJackpotHolder, payment);
        }
         
        LowGasAmount = 0;
        HighGasAmount = 0;
        
         
        uint8 id; 
        for (id=0; id<MaxItems; id++){
            Market[id].price=0;
        }
        
        if (gonext){
            Next(true);
        }
    }
    
    

    
     
     
     

    
    
    
    
    
    
}