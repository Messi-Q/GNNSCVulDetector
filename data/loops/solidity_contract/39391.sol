pragma solidity ^0.4.8;

 


 


contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract SikobaPresale is Owned {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    uint256 public totalFunding;

     
    uint256 public constant MINIMUM_PARTICIPATION_AMOUNT =   1 ether;
    uint256 public constant MAXIMUM_PARTICIPATION_AMOUNT = 250 ether;

     
    uint256 public constant PRESALE_MINIMUM_FUNDING = 4000 ether;
    uint256 public constant PRESALE_MAXIMUM_FUNDING = 8000 ether;

     
    uint256 public constant TOTAL_PREALLOCATION = 496.46472668 ether;

     
     
     
    uint256 public constant PRESALE_START_DATE = 1493121600;
    uint256 public constant PRESALE_END_DATE = 1494849600;

     
     
     
     
    uint256 public constant OWNER_CLAWBACK_DATE = 1514808000;

     
     
     
     
    mapping (address => uint256) public balanceOf;

     
     
     
    event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);

    function SikobaPresale () payable {
        assertEquals(TOTAL_PREALLOCATION, msg.value);
         
        addBalance(0xe902741cD4666E4023b7E3AB46D3DE2985c996f1, 0.647 ether);
        addBalance(0x98aB52E249646cA2b013aF8F2E411bB90C1c9b4d, 66.98333494 ether);
        addBalance(0x7C6003EDEB99886E8D65b5a3AF81Cd82962266f6, 1.0508692 ether);
        addBalance(0x7C6003EDEB99886E8D65b5a3AF81Cd82962266f6, 1.9491308 ether);
        addBalance(0x99a4f90e16C043197dA52d5d8c9B36A106c27042, 13 ether);
        addBalance(0x452F7faa5423e8D38435FFC5cFBA6Da806F159a5, 0.412 ether);
        addBalance(0x7FEA1962E35D62059768C749bedd96cAB930D378, 127.8142 ether);
        addBalance(0x0bFEc3578B7174997EFBf145b8d5f5b5b66F273f, 10 ether);
        addBalance(0xB4f14EDd0e846727cAe9A4B866854ed1bfE95781, 110 ether);
        addBalance(0xB6500cebED3334DCd9A5484D27a1986703BDcB1A, 0.9748227 ether);
        addBalance(0x8FBCE39aB5f2664506d6C3e3CD39f8A419784f62, 75.1 ether);
        addBalance(0x665A816F54020a5A255b366b7763D5dfE6f87940, 9 ether);
        addBalance(0x665A816F54020a5A255b366b7763D5dfE6f87940, 12 ether);
        addBalance(0x9cB37d0Ae943C8B4256e71F98B2dD0935e89344f, 10 ether);
        addBalance(0x00F87D9949B8E96f7c70F9Dd5a6951258729c5C3, 22.24507475 ether);
        addBalance(0xFf2694cd9Ca6a72C7864749072Fab8DB6090a1Ca, 10 ether);
        addBalance(0xCb5A0bC5EfC931C336fa844C920E070E6fc4e6ee, 0.27371429 ether);
        addBalance(0xd956d333BF4C89Cb4e3A3d833610817D8D4bedA3, 1 ether);
        addBalance(0xBA43Bbd58E0F389B5652a507c8F9d30891750C00, 2 ether);
        addBalance(0x1203c41aE7469B837B340870CE4F2205b035E69F, 5 ether);
        addBalance(0x8efdB5Ee103c2295dAb1410B4e3d1eD7A91584d4, 1 ether);
        addBalance(0xed1B8bbAE30a58Dc1Ce57bCD7DcA51eB75e1fde9, 6.01458 ether);
        addBalance(0x96050f871811344Dd44C2F5b7bc9741Dff296f5e, 10 ether);
        assertEquals(TOTAL_PREALLOCATION, totalFunding);
    }

     
     
     
     
     
     
     
     
    function () payable {
         
        if (now < PRESALE_START_DATE) throw;
         
        if (now > PRESALE_END_DATE) throw;
         
        if (msg.value < MINIMUM_PARTICIPATION_AMOUNT) throw;
         
        if (msg.value > MAXIMUM_PARTICIPATION_AMOUNT) throw;
         
         
        if (safeIncrement(totalFunding, msg.value) > PRESALE_MAXIMUM_FUNDING) throw;
         
        addBalance(msg.sender, msg.value);
    }

     
     
    function ownerWithdraw(uint256 value) external onlyOwner {
         
        if (totalFunding < PRESALE_MINIMUM_FUNDING) throw;
         
        if (!owner.send(value)) throw;
    }

     
     
    function participantWithdrawIfMinimumFundingNotReached(uint256 value) external {
         
        if (now <= PRESALE_END_DATE) throw;
         
        if (totalFunding >= PRESALE_MINIMUM_FUNDING) throw;
         
        if (balanceOf[msg.sender] < value) throw;
         
        balanceOf[msg.sender] = safeDecrement(balanceOf[msg.sender], value);
         
        if (!msg.sender.send(value)) throw;
    }

     
     
     
    function ownerClawback() external onlyOwner {
         
        if (now < OWNER_CLAWBACK_DATE) throw;
         
        if (!owner.send(this.balance)) throw;
    }

     
    function addBalance(address participant, uint256 value) private {
         
        balanceOf[participant] = safeIncrement(balanceOf[participant], value);
         
        totalFunding = safeIncrement(totalFunding, value);
         
        LogParticipation(participant, value, now);
    }

     
    function assertEquals(uint256 expectedValue, uint256 actualValue) private constant {
        if (expectedValue != actualValue) throw;
    }

     
     
    function safeIncrement(uint256 base, uint256 increment) private constant returns (uint256) {
        uint256 result = base + increment;
        if (result < base) throw;
        return result;
    }

     
     
    function safeDecrement(uint256 base, uint256 increment) private constant returns (uint256) {
        uint256 result = base - increment;
        if (result > base) throw;
        return result;
    }
}