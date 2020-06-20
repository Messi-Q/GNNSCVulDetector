pragma solidity ^0.4.17;

 

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
     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Util{

    function Util() public{}

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function toString(address x) internal pure returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
        b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }
}

contract SmartVows is Ownable, Util {

     
    string public partner1_name;
    string public partner2_name;
    
     
    address public partner1_address;
    address public partner2_address;
    
     
    string public partner1_vows;
    string public partner2_vows;

     
    string public marriageDate;

     
    string public maritalStatus;

     
    bytes public coupleImageIPFShash;

     
    bytes public marriageLicenceImageIPFShash;

     
    string public prenupAgreement;
    
     
    string public partner1_will;
    string public partner2_will;

     
    bool public partner1_signed;
    bool public partner2_signed;
    
     
    bool public partner1_voted_update_prenup;
    bool public partner2_voted_update_prenup;
    
     
    bool public partner1_voted_update_marriage_status;
    bool public partner2_voted_update_marriage_status;
    
     
     bool public is_signed;
    
     
    string public officiant;

     
    string public witnesses;

     
    string public location;
    
    Event[] public lifeEvents;

    struct Event {
        uint date;
        string name;
        string description;
        string mesg;
    }
    
    uint public eventcount; 

     
    event LifeEvent(string name, string description, string mesg);

    contractEvent[] public contractEvents;

    struct contractEvent {
        uint ce_date;
        string ce_description;
        string ce_mesg;
    }
    
    uint public contracteventcount; 

     
    event ContractEvent(string ce_description, string ce_mesg);

    function SmartVows(string _partner1, address _partner1_address, string _partner2, address _partner2_address, string _marriageDate, string _maritalStatus, string _officiant, string _witnesses, string _location, string coupleImageIPFShash, string marriageLicenceImageIPFShash) public{        
        partner1_name = _partner1;
        partner2_name = _partner2;  
        partner1_address=_partner1_address;
        partner2_address=_partner2_address;
        marriageDate =_marriageDate;
        maritalStatus = _maritalStatus;
        officiant=_officiant;
        witnesses=_witnesses;
        location=_location;
         
         

         
        saveContractEvent("Blockchain marriage smart contract created","Marriage smart contract added to the blockchain");
        
    }

     
    function addLifeEvent(string name, string description, string mesg) public{
        require(msg.sender == owner || msg.sender == partner1_address || msg.sender == partner2_address);
        saveLifeEvent(name, description, mesg);
    }

    function saveLifeEvent(string name, string description, string mesg) private {
        lifeEvents.push(Event(block.timestamp, name, description, mesg));
        LifeEvent(name, description, mesg);
        eventcount++;
    }
    
    
    function saveContractEvent(string description, string mesg) private {
        contractEvents.push(contractEvent(block.timestamp, description, mesg));
        ContractEvent(description, mesg);
        contracteventcount++;
    }

    
     
    function updatePartner1_vows(string _partner1_vows) public {
        require((msg.sender == owner || msg.sender == partner1_address) && (bytes(partner1_vows).length == 0));
        partner1_vows = _partner1_vows;
    }

     
    function updatePartner2_vows(string _partner2_vows) public {
        require((msg.sender == owner || msg.sender == partner2_address) && (bytes(partner2_vows).length == 0));
        partner2_vows = _partner2_vows;
    }

     
    function updateMaritalStatus(string _maritalStatus) public {
        require((msg.sender == owner || msg.sender == partner1_address || msg.sender == partner2_address) && (partner1_voted_update_marriage_status == true)&&(partner2_voted_update_marriage_status == true));
        saveContractEvent("Marital status updated", strConcat("Marital status changed from ", maritalStatus , " to ", _maritalStatus));
        maritalStatus = _maritalStatus;
        partner1_voted_update_marriage_status = false;
        partner2_voted_update_marriage_status = false;
    }

     
    function sign() public {
        require(msg.sender == partner1_address || msg.sender == partner2_address);
        if(msg.sender == partner1_address){
            partner1_signed = true;
            saveContractEvent("Marriage signed", "Smart Contract signed by Partner 1");
        }else {
            partner2_signed = true;
            saveContractEvent("Marriage signed", "Smart Contract signed by Partner 2");
        }
        
        if(partner1_signed && partner2_signed){ 
            is_signed = true;
        }
    }
    
     
        function voteToUpdateMaritalStatus() public {
        if(msg.sender == partner1_address){
            partner1_voted_update_marriage_status = true;
            saveContractEvent("Vote - Change Marital Status", "Partner 1 voted to updated Marital Status");
        }
        if(msg.sender == partner2_address){
            partner2_voted_update_marriage_status = true;
            saveContractEvent("Vote - Change Marital Status", "Partner 2 voted to updated Marital Status");
        }
    }
    
     
    function voteToUpdatePrenup() public {
        if(msg.sender == partner1_address){
            partner1_voted_update_prenup = true;
            saveContractEvent("Vote - Update Prenup", "Partner 1 voted to updated Prenuptial Aggreement");
        }
        if(msg.sender == partner2_address){
            partner2_voted_update_prenup = true;
            saveContractEvent("Vote - Update Prenup", "Partner 2 voted to updated Prenuptial Aggreement");
        }
    }

     
    function updateCoupleImageIPFShash(bytes _coupleImageIPFShash) public{
        require(msg.sender == owner || msg.sender == partner1_address || msg.sender == partner2_address);
        coupleImageIPFShash = _coupleImageIPFShash;
    }

     
    function updateMarriageLicenceImageIPFShash(bytes _marriageLicenceImageIPFShash) public{
        require(msg.sender == owner || msg.sender == partner1_address || msg.sender == partner2_address);
        marriageLicenceImageIPFShash = _marriageLicenceImageIPFShash;
    }

     
    function updatePrenup(string _prenupAgreement) public{
        require((msg.sender == owner || msg.sender == partner1_address || msg.sender == partner2_address) && (partner1_voted_update_prenup == true)&&(partner2_voted_update_prenup == true));
        prenupAgreement = _prenupAgreement;
        saveContractEvent("Update - Prenup", "Prenuptial Agreement Updated");
        partner1_voted_update_prenup = false;
        partner2_voted_update_prenup = false;
    }
     
     
    function updatePartner1_will(string _partner1_will) public {
        require(msg.sender == partner1_address);
        partner1_will = _partner1_will;
        saveContractEvent("Update - Will", "Partner 1 Will Updated");
    }
  
     
    function updatePartner2_will(string _partner2_will) public {
        require(msg.sender == partner2_address);
        partner2_will = _partner2_will;
        saveContractEvent("Update - Will", "Partner 2 Will Updated");
    }
    
}