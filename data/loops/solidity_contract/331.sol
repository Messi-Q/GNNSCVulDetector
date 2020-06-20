pragma solidity ^0.4.24;

pragma solidity ^0.4.24;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) return 0;
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


 
contract _1010_Mining_ {
    using SafeMath for uint256;
    
     
     
     
    
    struct Member {
        uint256 share;                                
        uint256 unpaid;                               
    }                                              
    mapping (address => Member) public members;       
    
    uint16    public memberCount;                     
    address[] public memberIndex;                     
    
    
     
     
     
    
    function _addMember (address _member, uint256 _share) private {
        emit AddMember(_member, _share);
        members[_member].share = _share;
        members[_member].unpaid = 1;
        memberIndex.push(_member);
        memberCount++;
    }
    
    
     
     
     
    
    constructor () public {
         
        _addMember(0xd2Ce719a0d00f4f8751297aD61B0E936970282E1, 50);
        _addMember(0xE517CB63e4dD36533C26b1ffF5deB893E63c3afA, 25);
        _addMember(0x430e1dd1ab2E68F201B53056EF25B9e116979D9b, 25);
    }
    
    
     
     
     
    
    event AddMember(address indexed member, uint256 share);
    event Withdraw(address indexed member, uint256 value);
    event Deposit(address indexed from, uint256 value);
    
    
     
     
     
    
    function () external payable {
         
        for (uint i=0; i<memberIndex.length; i++) {
            members[memberIndex[i]].unpaid = 
                 
                members[memberIndex[i]].unpaid.add(
                     
                    members[memberIndex[i]].share.mul(msg.value).div(100)
                );
        }
        
         
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw () external { 
         
        require(members[msg.sender].unpaid > 1, "No unpaid balance or not a member account");
        
         
        uint256 unpaid = members[msg.sender].unpaid.sub(1);
        members[msg.sender].unpaid = 1;
        
         
        emit Withdraw(msg.sender, unpaid);
        
         
        msg.sender.transfer(unpaid);
    }
    
    function unpaid () public view returns (uint256) {
         
        return members[msg.sender].unpaid.sub(1);
    }
    
    function member () public view returns (bool) {
         
        return members[msg.sender].unpaid >= 1;
    }
    
    
}