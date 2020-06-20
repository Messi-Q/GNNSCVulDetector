pragma solidity ^0.4.18;


contract StandardToken  {
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract owned {
    address public owner;

    function owned() public{
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract JPPreICO is owned{
    
    StandardToken token;
    address walletAddress;
    uint256 tokenPerEth;
    uint256 startBlock;
    uint256 endBlock;
    uint256 minInvestmentInWei;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Buy(address indexed buyer, uint256 eth, uint256 JPT);
    
    function JPPreICO() public{
        token = StandardToken(0xce4d20b74fAf8C1Ab15e2B0Fd3F1CCCfe6f6d419);  
        walletAddress=0x18aB7d43e9062d8656AE42EE9E473E05dE0DD3B9;  
        tokenPerEth=0;  
        startBlock=5362919;  
        endBlock=5483879;  
        minInvestmentInWei=22121283624351108;  
    }

    function () public payable {
        require(msg.value>=minInvestmentInWei);
        require(msg.data.length==0);
        require((msg.value*tokenPerEth)/(10**16)<=token.balanceOf(this)); 
        require(isICOUp()); 
        uint256 coins = (msg.value * tokenPerEth)/(10**16);
        walletAddress.transfer(msg.value);
        token.transfer(msg.sender, coins);
         
        Transfer(this,msg.sender,coins);
        Buy(msg.sender, msg.value, coins);
    }
    
    
    function getMaxEtherToInvest() public view returns (uint256){
        return (token.balanceOf(this)/tokenPerEth);
    }
    
    function setMinInvestmentInWei(uint256 _minInvestmentInWei) public onlyOwner {
        minInvestmentInWei=_minInvestmentInWei;
    }
    
    function isICOUp() public view returns(bool){
        return (block.number>=startBlock && block.number<=endBlock);
    }
    
    function setTokenPerEth (uint256 _change) public onlyOwner{
    	tokenPerEth = _change;
    }
    
    
     
    function getWalletAddress() public view returns(address){
        return walletAddress;
    }
    
    function getTokenPerEth() public view returns(uint256){
        return tokenPerEth;
    }
    
    function getTokenBalance() public view returns(uint256){
        return token.balanceOf(this);
    }
    
    function setEndBlock(uint256 _endBlock) public onlyOwner{
        endBlock=_endBlock;
    }
    
    function setStartBlock(uint256 _startBlock) public onlyOwner{
        startBlock=_startBlock;
    }
    
    function sendBackTokens() public onlyOwner{
        require(!isICOUp());
        token.transfer(walletAddress,token.balanceOf(this));
    }
 
}