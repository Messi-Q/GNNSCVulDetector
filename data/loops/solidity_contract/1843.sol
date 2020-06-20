pragma solidity ^0.4.24;

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract MinimalTokenInterface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function decimals() public returns (uint8);
}

 
 
 
contract SNcoin_CountrySale is Owned {
    MinimalTokenInterface public tokenContract;
    address public spenderAddress;
    address public vaultAddress;
    address public ambassadorAddress;
    bool public fundingEnabled;
    uint public totalCollected;          
    uint public tokenPrice;          
    string public country;


     
     
     
    constructor(address _tokenAddress, address _spenderAddress, address _vaultAddress, address _ambassadorAddress, bool _fundingEnabled, uint _newTokenPrice, string _country) public {
        require (_tokenAddress != 0);
        require (_spenderAddress != 0);
        require (_vaultAddress != 0);
        require (_newTokenPrice > 0);
        require (bytes(_country).length > 0);
        tokenContract = MinimalTokenInterface(_tokenAddress);
        spenderAddress = _spenderAddress;
        vaultAddress = _vaultAddress;
        ambassadorAddress = _ambassadorAddress;
        fundingEnabled = _fundingEnabled;
        tokenPrice = _newTokenPrice;
        country = _country;
    }

    function setSpenderAddress(address _spenderAddress) public onlyOwner {
        require (_spenderAddress != 0);
        spenderAddress = _spenderAddress;
        return;
    }

    function setVaultAddress(address _vaultAddress) public onlyOwner {
        require (_vaultAddress != 0);
        vaultAddress = _vaultAddress;
        return;
    }

    function setAmbassadorAddress(address _ambassadorAddress) public onlyOwner {
        require (_ambassadorAddress != 0);
        ambassadorAddress = _ambassadorAddress;
        return;
    }

    function setFundingEnabled(bool _fundingEnabled) public onlyOwner {
        fundingEnabled = _fundingEnabled;
        return;
    }

    function updateTokenPrice(uint _newTokenPrice) public onlyOwner {
        require(_newTokenPrice > 10**9);
        tokenPrice = _newTokenPrice;
        return;
    }

    function () public payable {
        require (fundingEnabled);
        require (ambassadorAddress != 0);
        require (tokenPrice > 10**9);
        require (msg.value >= tokenPrice);

        totalCollected += msg.value;
        uint ambVal = (20 * msg.value)/100;
        uint tokens = (msg.value * 10**uint256(tokenContract.decimals())) / tokenPrice;

        require (tokenContract.transferFrom(spenderAddress, msg.sender, tokens));

         
        ambassadorAddress.transfer(ambVal);
        vaultAddress.transfer(msg.value - ambVal);

        return;
    }

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        MinimalTokenInterface token = MinimalTokenInterface(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }
    
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}