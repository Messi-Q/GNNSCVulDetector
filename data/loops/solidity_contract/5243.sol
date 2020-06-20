pragma solidity ^0.4.15;

contract owned {
    function owned() public { owner = msg.sender; }
    address public owner;

     
     
     
     
     
     
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract ERC20 {
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
 
contract ERC721 {
     
    function totalSupply() public returns (uint256 total);
    function balanceOf(address _owner) public returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external returns (bool);
}

contract AutoWallet is owned {
    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    
    function () external payable {
         
         
        owner.transfer(msg.value);
         
        EtherReceived(msg.sender, msg.value);
    }
    
    function sweep() external returns (bool success) {
         
         
        require(this.balance > 0);
        return owner.send(this.balance);
    }
    
    function transferToken(address _tokenContractAddress, address _to, uint256 _amount) external onlyOwner returns (bool success) {
         
        ERC20 token = ERC20(_tokenContractAddress);
        return token.transfer(_to, _amount);
    }
    
    function sweepToken(address _tokenContractAddress) external returns (bool success) {
         
        ERC20 token = ERC20(_tokenContractAddress);
        uint bal = token.balanceOf(this);
        require(bal > 0);
        return token.transfer(owner, bal);
    }
    
    function transferTokenFrom(address _tokenContractAddress, address _from, address _to, uint256 _amount) external onlyOwner returns (bool success) {
        ERC20 token = ERC20(_tokenContractAddress);
        return token.transferFrom(_from, _to, _amount);
    }
    
    function approveTokenTransfer(address _tokenContractAddress, address _spender, uint256 _amount) external onlyOwner returns (bool success) {
        ERC20 token = ERC20(_tokenContractAddress);
        return token.approve(_spender, _amount);
    }
    
    function transferNonFungibleToken(address _tokenContractAddress, address _to, uint256 _tokenId) external onlyOwner {
         
        ERC721 token = ERC721(_tokenContractAddress);
        token.transfer(_to, _tokenId);
    }
    
    function transferNonFungibleTokenFrom(address _tokenContractAddress, address _from, address _to, uint256 _tokenId) external onlyOwner {
        ERC721 token = ERC721(_tokenContractAddress);
        token.transferFrom(_from, _to, _tokenId);
    }
    
    function transferNonFungibleTokenMulti(address _tokenContractAddress, address _to, uint256[] _tokenIds) external onlyOwner {
        ERC721 token = ERC721(_tokenContractAddress);
        for (uint i = 0; i < _tokenIds.length; i++) {
            token.transfer(_to, _tokenIds[i]);
        }
    }
    
    event EtherReceived(address _sender, uint256 _value);
}