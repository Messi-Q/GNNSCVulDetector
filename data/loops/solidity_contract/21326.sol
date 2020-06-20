pragma solidity 0.4.18;

contract FHFTokenInterface {
     
    string public standard = 'Token 0.1';
    string public name = 'Forever Has Fallen';
    string public symbol = 'FC';
    uint8 public decimals = 18;

    function approveCrowdsale(address _crowdsaleAddress) external;
    function balanceOf(address _address) public constant returns (uint256 balance);
    function vestedBalanceOf(address _address) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _currentValue, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract CrowdsaleParameters {
     
     
     

    struct AddressTokenAllocation {
        address addr;
        uint256 amount;
    }

    uint256 public maximumICOCap = 350e6;

     
     
     
    uint256 public generalSaleStartDate = 1525777200;
    uint256 public generalSaleEndDate = 1529406000;

     
     
    uint32 internal vestingTeam = 1592564400;
     
    uint32 internal vestingBounty = 1529406000;

     
     
     


     
     
     

    AddressTokenAllocation internal generalSaleWallet = AddressTokenAllocation(0x265Fb686cdd2f9a853c519592078cC4d1718C15a, 350e6);
    AddressTokenAllocation internal communityReserve =  AddressTokenAllocation(0x76d472C73681E3DF8a7fB3ca79E5f8915f9C5bA5, 450e6);
    AddressTokenAllocation internal team =              AddressTokenAllocation(0x05d46150ceDF59ED60a86d5623baf522E0EB46a2, 170e6);
    AddressTokenAllocation internal advisors =          AddressTokenAllocation(0x3d5fa25a3C0EB68690075eD810A10170e441413e, 48e5);
    AddressTokenAllocation internal bounty =            AddressTokenAllocation(0xAc2099D2705434f75adA370420A8Dd397Bf7CCA1, 176e5);
    AddressTokenAllocation internal administrative =    AddressTokenAllocation(0x438aB07D5EC30Dd9B0F370e0FE0455F93C95002e, 76e5);

    address internal playersReserve = 0x8A40B0Cf87DaF12C689ADB5C74a1B2f23B3a33e1;
}


contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract FHFTokenCrowdsale is Owned, CrowdsaleParameters {
     
    FHFTokenInterface private token;
    address private saleWalletAddress;
    uint private tokenMultiplier = 10;
    uint public totalCollected = 0;
    uint public saleGoal;
    bool public goalReached = false;

     
    event TokenSale(address indexed tokenReceiver, uint indexed etherAmount, uint indexed tokenAmount, uint tokensPerEther);
    event FundTransfer(address indexed from, address indexed to, uint indexed amount);

     
    function FHFTokenCrowdsale(address _tokenAddress) public {
        token = FHFTokenInterface(_tokenAddress);
        tokenMultiplier = tokenMultiplier ** token.decimals();
        saleWalletAddress = CrowdsaleParameters.generalSaleWallet.addr;

         
        saleGoal = CrowdsaleParameters.generalSaleWallet.amount;
    }

     
    function isICOActive() public constant returns (bool active) {
        active = ((generalSaleStartDate <= now) && (now < generalSaleEndDate) && (!goalReached));
        return active;
    }

     
    function processPayment(address backerAddress, uint amount) internal {
        require(isICOActive());

         
         
        assert(msg.value > 0 finney);

         
        FundTransfer(backerAddress, address(this), amount);

         
        uint tokensPerEth = 10000;

         
        uint tokenAmount = amount * tokensPerEth;

         
         
        uint remainingTokenBalance = token.balanceOf(saleWalletAddress);
        if (remainingTokenBalance <= tokenAmount) {
            tokenAmount = remainingTokenBalance;
            goalReached = true;
        }

         
         
        uint acceptedAmount = tokenAmount / tokensPerEth;

         
        totalCollected += acceptedAmount;

         
        token.transferFrom(saleWalletAddress, backerAddress, tokenAmount);

        TokenSale(backerAddress, amount, tokenAmount, tokensPerEth);

         
        uint change = amount - acceptedAmount;
        if (change > 0) {
            if (backerAddress.send(change)) {
                FundTransfer(address(this), backerAddress, change);
            }
            else revert();
        }
    }

     
    function safeWithdrawal(uint amount) external onlyOwner {
        require(this.balance >= amount);
        require(!isICOActive());

        if (owner.send(amount)) {
            FundTransfer(address(this), msg.sender, amount);
        }
    }

     
    function () external payable {
        processPayment(msg.sender, msg.value);
    }

     
    function closeMainSaleICO() external onlyOwner {
        require(!isICOActive());
        require(generalSaleStartDate < now);

        var amountToMove = token.balanceOf(generalSaleWallet.addr);
        token.transferFrom(generalSaleWallet.addr, playersReserve, amountToMove);
        generalSaleEndDate = now;
    }

     
    function kill() external onlyOwner {
        require(!isICOActive());
        if (now < generalSaleStartDate) {
            selfdestruct(owner);
        } else if (token.balanceOf(generalSaleWallet.addr) == 0) {
            FundTransfer(address(this), msg.sender, this.balance);
            selfdestruct(owner);
        } else {
            revert();
        }
    }
}