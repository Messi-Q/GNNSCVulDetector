pragma solidity ^0.4.0;

 
contract TokenInterface {

        
     
    uint totalSupply;

    
                                    
    function balanceOf(address owner) constant returns (uint256 balance);
    
    function transfer(address to, uint256 value) returns (bool success);

    function transferFrom(address from, address to, uint256 value) returns (bool success);

     
    function approve(address spender, uint256 value) returns (bool success);

     
    function allowance(address owner, address spender) constant returns (uint256 remaining);

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is TokenInterface {


     
    mapping (address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) allowed;
    
    
    
    function StandardToken(){
    }
    
    
         
    function transfer(address to, uint256 value) returns (bool success) {
        
        
        if (balances[msg.sender] >= value && value > 0) {

             
            balances[msg.sender] -= value;
            balances[to]         += value;
            
             
            Transfer(msg.sender, to, value);
            return true;
        } else {
            
            return false; 
        }
    }
    
    

    
     
    function transferFrom(address from, address to, uint256 value) returns (bool success) {
    
        if ( balances[from] >= value && 
             allowed[from][msg.sender] >= value && 
             value > 0) {
                                          
    
             
            balances[from] -= value;    
            balances[to] =+ value;            
            

             
             
            allowed[from][msg.sender] -= value;
            
             
            Transfer(from, to, value);
            return true;
        } else { 
            
            return false; 
        }
    }

    

    
                                    
    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }

    
    
     
    function approve(address spender, uint256 value) returns (bool success) {
        
         
         
        allowed[msg.sender][spender] = value;
        
         
        Approval(msg.sender, spender, value);
        
        return true;
    }

     
    function allowance(address owner, address spender) constant returns (uint256 remaining) {
      return allowed[owner][spender];
    }

}


 
contract HackerGold is StandardToken {

     
    string public name = "HackerGold";

     
    uint8  public decimals = 3;
     
    string public symbol = "HKG";
    
     
    uint BASE_PRICE = 200;
     
    uint MID_PRICE = 150;
     
    uint FIN_PRICE = 100;
     
    uint SAFETY_LIMIT = 4000000 ether;
     
    uint DECIMAL_ZEROS = 1000;
    
     
    uint totalValue;
    
     
    address wallet;

     
    struct milestones_struct {
      uint p1;
      uint p2; 
      uint p3;
      uint p4;
      uint p5;
      uint p6;
    }
     
    milestones_struct milestones;
    
     
    function HackerGold(address multisig) {
        
        wallet = multisig;

         
        milestones = milestones_struct(
        
          1476972000,   
          1478181600,   
          1479391200,   
                        
          1480600800,   
          1481810400,   
          1482415200    
        );
                
    }
    
    
     
    function () payable {
        createHKG(msg.sender);
    }
    
     
    function createHKG(address holder) payable {
        
        if (now < milestones.p1) throw;
        if (now >= milestones.p6) throw;
        if (msg.value == 0) throw;
    
         
        if (getTotalValue() + msg.value > SAFETY_LIMIT) throw; 
    
        uint tokens = msg.value * getPrice() * DECIMAL_ZEROS / 1 ether;

        totalSupply += tokens;
        balances[holder] += tokens;
        totalValue += msg.value;
        
        if (!wallet.send(msg.value)) throw;
    }
    
     
    function getPrice() constant returns (uint result) {
        
        if (now < milestones.p1) return 0;
        
        if (now >= milestones.p1 && now < milestones.p2) {
        
            return BASE_PRICE;
        }
        
        if (now >= milestones.p2 && now < milestones.p3) {
            
            uint days_in = 1 + (now - milestones.p2) / 1 days; 
            return BASE_PRICE - days_in * 25 / 7;   
        }

        if (now >= milestones.p3 && now < milestones.p4) {
        
            return MID_PRICE;
        }
        
        if (now >= milestones.p4 && now < milestones.p5) {
            
            days_in = 1 + (now - milestones.p4) / 1 days; 
            return MID_PRICE - days_in * 25 / 7;   
        }

        if (now >= milestones.p5 && now < milestones.p6) {
        
            return FIN_PRICE;
        }
        
        if (now >= milestones.p6){

            return 0;
        }

     }
    
     
    function getTotalSupply() constant returns (uint result) {
        return totalSupply;
    } 

     
    function getNow() constant returns (uint result) {
        return now;
    }

     
    function getTotalValue() constant returns (uint result) {
        return totalValue;  
    }
}

contract DSTContract is StandardToken{

     
    uint DECIMAL_ZEROS = 1000;
     
    uint PROPOSAL_LIFETIME = 10 days;
     
    uint PROPOSAL_FUNDS_TH = 20;

    address   executive; 
        
    EventInfo eventInfo;
    
     
    address virtualExchangeAddress;
    
    HackerGold hackerGold;
        
    mapping (address => uint256) votingRights;


     
    uint hkgPrice;
    
     
    uint etherPrice;
    
    string public name = "...";                   
    uint8  public decimals = 3;                 
    string public symbol = "...";
    
    bool ableToIssueTokens = true; 
    
    uint preferedQtySold;

    uint collectedHKG; 
    uint collectedEther;    
    
     
    mapping (bytes32 => Proposal) proposals;

    enum ProposalCurrency { HKG, ETHER }
    ProposalCurrency enumDeclaration;
                  
       
    struct Proposal{
        
        bytes32 id;
        uint value;

        string urlDetails;

        uint votindEndTS;
                
        uint votesObjecting;
        
        address submitter;
        bool redeemed;

        ProposalCurrency proposalCurrency;
        
        mapping (address => bool) voted;
    }
    uint counterProposals;
    uint timeOfLastProposal;
    
    Proposal[] listProposals;
    

         
    struct ImpeachmentProposal{
        
        string urlDetails;
        
        address newExecutive;

        uint votindEndTS;        
        uint votesSupporting;
        
        mapping (address => bool) voted;        
    }
    ImpeachmentProposal lastImpeachmentProposal;

        
      
    function DSTContract(EventInfo eventInfoAddr, HackerGold hackerGoldAddr, string dstName, string dstSymbol){
    
      executive   = msg.sender;  
      name        = dstName;
      symbol      = dstSymbol;

      hackerGold = HackerGold(hackerGoldAddr);
      eventInfo  = EventInfo(eventInfoAddr);
    }
    

    function() payable
               onlyAfterEnd {
        
         
        if (etherPrice == 0) throw;
        
        uint tokens = msg.value * etherPrice * DECIMAL_ZEROS / (1 ether);
        
         
         
        uint retEther = 0;
        if (balances[this] < tokens) {
            
            tokens = balances[this];
            retEther = msg.value - tokens / etherPrice * (1 finney);
        
             
            if (!msg.sender.send(retEther)) throw;
        }
        
        
         
        balances[msg.sender] += tokens;
        balances[this] -= tokens;
        
         
        collectedEther += msg.value - retEther; 
        
         
        BuyForEtherTransaction(msg.sender, collectedEther, totalSupply, etherPrice, tokens);
        
    }

    
    
         
     function setHKGPrice(uint qtyForOneHKG) onlyExecutive  {
         
         hkgPrice = qtyForOneHKG;
         PriceHKGChange(qtyForOneHKG, preferedQtySold, totalSupply);
     }
     
     
    
     
    function issuePreferedTokens(uint qtyForOneHKG, 
                                 uint qtyToEmit) onlyExecutive 
                                                 onlyIfAbleToIssueTokens
                                                 onlyBeforeEnd
                                                 onlyAfterTradingStart {
                
         
         
        if (virtualExchangeAddress == 0x0) throw;
            
        totalSupply    += qtyToEmit;
        balances[this] += qtyToEmit;
        hkgPrice = qtyForOneHKG;
        
        
         
         
        allowed[this][virtualExchangeAddress] += qtyToEmit;
        
         
        Approval(this, virtualExchangeAddress, qtyToEmit);
        
         
        DstTokensIssued(hkgPrice, preferedQtySold, totalSupply, qtyToEmit);
    }

    
    
    
     
    function buyForHackerGold(uint hkgValue) onlyBeforeEnd 
                                             returns (bool success) {
    
       
      if (msg.sender != virtualExchangeAddress) throw;
      
      
       
      address sender = tx.origin;
      uint tokensQty = hkgValue * hkgPrice;

       
      votingRights[sender] +=tokensQty;
      preferedQtySold += tokensQty;
      collectedHKG += hkgValue;

       
      transferFrom(this, 
                   virtualExchangeAddress, tokensQty);
      transfer(sender, tokensQty);        
            
       
      BuyForHKGTransaction(sender, preferedQtySold, totalSupply, hkgPrice, tokensQty);
        
      return true;
    }
        
    
     
    function issueTokens(uint qtyForOneEther, 
                         uint qtyToEmit) onlyAfterEnd 
                                         onlyExecutive
                                         onlyIfAbleToIssueTokens {
         
         balances[this] += qtyToEmit;
         etherPrice = qtyForOneEther;
         totalSupply    += qtyToEmit;
         
          
         DstTokensIssued(qtyForOneEther, totalSupply, totalSupply, qtyToEmit);
    }
     
    
          
    function setEtherPrice(uint qtyForOneEther) onlyAfterEnd
                                                onlyExecutive {
         etherPrice = qtyForOneEther; 

          
         NewEtherPrice(qtyForOneEther);
    }    
    

     
    function disableTokenIssuance() onlyExecutive {
        ableToIssueTokens = false;
        
        DisableTokenIssuance();
    }

    
     
    function burnRemainToken() onlyExecutive {
    
        totalSupply -= balances[this];
        balances[this] = 0;
        
         
        BurnedAllRemainedTokens();
    }
    
      
    function submitEtherProposal(uint requestValue, string url) onlyAfterEnd 
                                                                onlyExecutive returns (bytes32 resultId, bool resultSucces) {       
    
         
        if (ableToIssueTokens) throw;
            
         
        if (balanceOf(this) > 0) throw;

         
        if (now < (timeOfLastProposal + 2 weeks)) throw;
            
        uint percent = collectedEther / 100;
            
        if (requestValue > PROPOSAL_FUNDS_TH * percent) throw;

         
        if (requestValue > this.balance) 
            requestValue = this.balance;    
            
         
         
        bytes32 id = sha3(msg.data, now);
        uint timeEnds = now + PROPOSAL_LIFETIME; 
            
        Proposal memory newProposal = Proposal(id, requestValue, url, timeEnds, 0, msg.sender, false, ProposalCurrency.ETHER);
        proposals[id] = newProposal;
        listProposals.push(newProposal);
            
        timeOfLastProposal = now;                        
        ProposalRequestSubmitted(id, requestValue, timeEnds, url, msg.sender);
        
        return (id, true);
    }
    
    
     
     
    function submitHKGProposal(uint requestValue, string url) onlyAfterEnd
                                                              onlyExecutive returns (bytes32 resultId, bool resultSucces){
        

         
         
         
        if (now < (eventInfo.getEventEnd() + 8 weeks)) {
            throw;
        }

         
        if (now < (timeOfLastProposal + 2 weeks)) throw;

        uint percent = preferedQtySold / 100;
        
         
         
        if (counterProposals <= 5 && 
            requestValue     >  PROPOSAL_FUNDS_TH * percent) throw;
                
         
         
        if (requestValue > getHKGOwned()) 
            requestValue = getHKGOwned();
        
        
         
         
        bytes32 id = sha3(msg.data, now);
        uint timeEnds = now + PROPOSAL_LIFETIME; 
        
        Proposal memory newProposal = Proposal(id, requestValue, url, timeEnds, 0, msg.sender, false, ProposalCurrency.HKG);
        proposals[id] = newProposal;
        listProposals.push(newProposal);
        
        ++counterProposals;
        timeOfLastProposal = now;                
                
        ProposalRequestSubmitted(id, requestValue, timeEnds, url, msg.sender);
        
        return (id, true);        
    }  
    
    
    
     
     function objectProposal(bytes32 id){
         
        Proposal memory proposal = proposals[id];
         
         
        if (proposals[id].id == 0) throw;

         
        if (proposals[id].redeemed) throw;
         
         
        if (now >= proposals[id].votindEndTS) throw;
         
         
        if (proposals[id].voted[msg.sender]) throw;
         
          
         uint votes = votingRights[msg.sender];
         proposals[id].votesObjecting += votes;
         
          
         proposals[id].voted[msg.sender] = true; 
         
         uint idx = getIndexByProposalId(id);
         listProposals[idx] = proposals[id];   

         ObjectedVote(id, msg.sender, votes);         
     }
     
     
     function getIndexByProposalId(bytes32 id) returns (uint result){
         
         for (uint i = 0; i < listProposals.length; ++i){
             if (id == listProposals[i].id) return i;
         }
     }
    
    
   
     
    function redeemProposalFunds(bytes32 id) onlyExecutive {

        if (proposals[id].id == 0) throw;
        if (proposals[id].submitter != msg.sender) throw;

         
        if (now < proposals[id].votindEndTS) throw;
                           
    
             
        if (proposals[id].redeemed) throw;

         
        uint objectionThreshold = preferedQtySold / 100 * 55;
        if (proposals[id].votesObjecting  > objectionThreshold) throw;
    
    
        if (proposals[id].proposalCurrency == ProposalCurrency.HKG){
            
             
            hackerGold.transfer(proposals[id].submitter, proposals[id].value);      
                        
        } else {
                        
            
           bool success = proposals[id].submitter.send(proposals[id].value); 

            
           EtherRedeemAccepted(proposals[id].submitter, proposals[id].value);                              
        }
        
         
        proposals[id].redeemed = true; 
    }
    
    
                  
    function getAllTheFunds() onlyExecutive {
        
         
         
        if (now < (eventInfo.getEventEnd() + 24 weeks)) {
            throw;
        }  
        
         
        bool success = msg.sender.send(this.balance);        
        
         
        hackerGold.transfer(msg.sender, getHKGOwned());              
    }
    
    
                  
     function submitImpeachmentProposal(string urlDetails, address newExecutive){
         
         
         
        if (votingRights[msg.sender] == 0) throw;
         
         
         
         
        if (now < (eventInfo.getEventEnd() + 12 weeks)) throw;
        
                
         
        if (lastImpeachmentProposal.votindEndTS != 0 && 
            lastImpeachmentProposal.votindEndTS +  2 weeks > now) throw;


         
         
         
        lastImpeachmentProposal = ImpeachmentProposal(urlDetails, newExecutive, now + 2 weeks, votingRights[msg.sender]);
        lastImpeachmentProposal.voted[msg.sender] = true;
         
         
        ImpeachmentProposed(msg.sender, urlDetails, now + 2 weeks, newExecutive);
     }
    
    
     
    function supportImpeachment(){

         
        if (lastImpeachmentProposal.newExecutive == 0x0) throw;
    
         
         
        if (votingRights[msg.sender] == 0) throw;
        
         
        if (lastImpeachmentProposal.voted[msg.sender]) throw;
        
         
        if (lastImpeachmentProposal.votindEndTS + 2 weeks <= now) throw;
                
         
        lastImpeachmentProposal.voted[msg.sender] = true;
        lastImpeachmentProposal.votesSupporting += votingRights[msg.sender];

         
        ImpeachmentSupport(msg.sender, votingRights[msg.sender]);
        
         
        uint percent = preferedQtySold / 100; 
        
        if (lastImpeachmentProposal.votesSupporting >= 70 * percent){
            executive = lastImpeachmentProposal.newExecutive;
            
             
            ImpeachmentAccepted(executive);
        }
        
    } 
    
      
    
     
     
     
    
    function votingRightsOf(address _owner) constant returns (uint256 result) {
        result = votingRights[_owner];
    }
    
    function getPreferedQtySold() constant returns (uint result){
        return preferedQtySold;
    }
    
    function setVirtualExchange(address virtualExchangeAddr){
        if (virtualExchangeAddress != 0x0) throw;
        virtualExchangeAddress = virtualExchangeAddr;
    }

    function getHKGOwned() constant returns (uint result){
        return hackerGold.balanceOf(this);
    }
    
    function getEtherValue() constant returns (uint result){
        return this.balance;
    }
    
    function getExecutive() constant returns (address result){
        return executive;
    }
    
    function getHKGPrice() constant returns (uint result){
        return hkgPrice;
    }

    function getEtherPrice() constant returns (uint result){
        return etherPrice;
    }
    
    function getDSTName() constant returns(string result){
        return name;
    }    
    
    function getDSTNameBytes() constant returns(bytes32 result){
        return convert(name);
    }    

    function getDSTSymbol() constant returns(string result){
        return symbol;
    }    
    
    function getDSTSymbolBytes() constant returns(bytes32 result){
        return convert(symbol);
    }    

    function getAddress() constant returns (address result) {
        return this;
    }
    
    function getTotalSupply() constant returns (uint result) {
        return totalSupply;
    } 
        
    function getCollectedEther() constant returns (uint results) {        
        return collectedEther;
    }
    
    function getCounterProposals() constant returns (uint result){
        return counterProposals;
    }
        
    function getProposalIdByIndex(uint i) constant returns (bytes32 result){
        return listProposals[i].id;
    }    

    function getProposalObjectionByIndex(uint i) constant returns (uint result){
        return listProposals[i].votesObjecting;
    }

    function getProposalValueByIndex(uint i) constant returns (uint result){
        return listProposals[i].value;
    }                  
    
    function getCurrentImpeachmentUrlDetails() constant returns (string result){
        return lastImpeachmentProposal.urlDetails;
    }
    
    
    function getCurrentImpeachmentVotesSupporting() constant returns (uint result){
        return lastImpeachmentProposal.votesSupporting;
    }
    
    function convert(string key) returns (bytes32 ret) {
            if (bytes(key).length > 32) {
                throw;
            }      

            assembly {
                ret := mload(add(key, 32))
            }
    }    
    
    
    
     
     
     
 
    modifier onlyBeforeEnd() { if (now  >=  eventInfo.getEventEnd()) throw; _; }
    modifier onlyAfterEnd()  { if (now  <   eventInfo.getEventEnd()) throw; _; }
    
    modifier onlyAfterTradingStart()  { if (now  < eventInfo.getTradingStart()) throw; _; }
    
    modifier onlyExecutive()     { if (msg.sender != executive) throw; _; }
                                       
    modifier onlyIfAbleToIssueTokens()  { if (!ableToIssueTokens) throw; _; } 
    

     
     
     

    
    event PriceHKGChange(uint indexed qtyForOneHKG, uint indexed tokensSold, uint indexed totalSupply);
    event BuyForHKGTransaction(address indexed buyer, uint indexed tokensSold, uint indexed totalSupply, uint qtyForOneHKG, uint tokensAmount);
    event BuyForEtherTransaction(address indexed buyer, uint indexed tokensSold, uint indexed totalSupply, uint qtyForOneEther, uint tokensAmount);

    event DstTokensIssued(uint indexed qtyForOneHKG, uint indexed tokensSold, uint indexed totalSupply, uint qtyToEmit);
    
    event ProposalRequestSubmitted(bytes32 id, uint value, uint timeEnds, string url, address sender);
    
    event EtherRedeemAccepted(address sender, uint value);
    
    event ObjectedVote(bytes32 id, address voter, uint votes);
    
    event ImpeachmentProposed(address submitter, string urlDetails, uint votindEndTS, address newExecutive);
    event ImpeachmentSupport(address supportter, uint votes);
    
    event ImpeachmentAccepted(address newExecutive);

    event NewEtherPrice(uint newQtyForOneEther);
    event DisableTokenIssuance();
    
    event BurnedAllRemainedTokens();
    
}


 
contract EventInfo{
    
    
    uint constant HACKATHON_5_WEEKS = 60 * 60 * 24 * 7 * 5;
    uint constant T_1_WEEK = 60 * 60 * 24 * 7;

    uint eventStart = 1479391200;  
    uint eventEnd = eventStart + HACKATHON_5_WEEKS;
    
    
      
    function getEventStart() constant returns (uint result){        
       return eventStart;
    } 
    
      
    function getEventEnd() constant returns (uint result){        
       return eventEnd;
    } 
    
    
      
    function getVotingStart() constant returns (uint result){
        return eventStart+ T_1_WEEK;
    }

      
    function getTradingStart() constant returns (uint result){
        return eventStart+ T_1_WEEK;
    }

     
    function getNow() constant returns (uint result){        
       return now;
    } 
    
}