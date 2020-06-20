pragma solidity ^0.4.4;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
contract ERC20Partial {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint _value);
     
}

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
 

contract TokenSeller is Owned {

    address public asset;        
    uint256 public sellPrice;    
    uint256 public units;        

    bool public sellsTokens;     

    event ActivatedEvent(bool sells);
    event MakerWithdrewAsset(uint256 tokens);
    event MakerTransferredAsset(address toTokenSeller, uint256 tokens);
    event MakerWithdrewERC20Token(address tokenAddress, uint256 tokens);
    event MakerWithdrewEther(uint256 ethers);
    event TakerBoughtAsset(address indexed buyer, uint256 ethersSent,
        uint256 ethersReturned, uint256 tokensBought);

     
    function TokenSeller (
        address _asset,
        uint256 _sellPrice,
        uint256 _units,
        bool    _sellsTokens
    ) {
        asset       = _asset;
        sellPrice   = _sellPrice;
        units       = _units;
        sellsTokens = _sellsTokens;
        ActivatedEvent(sellsTokens);
    }

     
     
     
     
     
     
    function activate (
        bool _sellsTokens
    ) onlyOwner {
        sellsTokens = _sellsTokens;
        ActivatedEvent(sellsTokens);
    }

     
     
     
     
     
     
     
     
     
    function makerWithdrawAsset(uint256 tokens) onlyOwner returns (bool ok) {
        MakerWithdrewAsset(tokens);
        return ERC20Partial(asset).transfer(owner, tokens);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function makerTransferAsset(
        TokenSeller toTokenSeller,
        uint256 tokens
    ) onlyOwner returns (bool ok) {
        if (owner != toTokenSeller.owner() || asset != toTokenSeller.asset()) {
            throw;
        }
        MakerTransferredAsset(toTokenSeller, tokens);
        return ERC20Partial(asset).transfer(toTokenSeller, tokens);
    }

     
     
     
     
     
     
     
     
     
     
     
    function makerWithdrawERC20Token(
        address tokenAddress,
        uint256 tokens
    ) onlyOwner returns (bool ok) {
        MakerWithdrewERC20Token(tokenAddress, tokens);
        return ERC20Partial(tokenAddress).transfer(owner, tokens);
    }

     
     
     
     
     
     
    function makerWithdrawEther(uint256 ethers) onlyOwner returns (bool ok) {
        if (this.balance >= ethers) {
            MakerWithdrewEther(ethers);
            return owner.send(ethers);
        }
    }

     
     
     
     
     
     
     
     
     
     
    function takerBuyAsset() payable {
        if (sellsTokens || msg.sender == owner) {
             
            uint order    = msg.value / sellPrice;
             
            uint can_sell = ERC20Partial(asset).balanceOf(address(this)) / units;
            uint256 change = 0;
            if (msg.value > (can_sell * sellPrice)) {
                change  = msg.value - (can_sell * sellPrice);
                order = can_sell;
            }
            if (change > 0) {
                if (!msg.sender.send(change)) throw;
            }
            if (order > 0) {
                if (!ERC20Partial(asset).transfer(msg.sender, order * units)) throw;
            }
            TakerBoughtAsset(msg.sender, msg.value, change, order * units);
        }
         
        else if (!msg.sender.send(msg.value)) throw;
    }

     
    function () payable {
        takerBuyAsset();
    }
}

 
contract TokenSellerFactory is Owned {

    event TradeListing(address indexed ownerAddress, address indexed tokenSellerAddress,
        address indexed asset, uint256 sellPrice, uint256 units, bool sellsTokens);
    event OwnerWithdrewERC20Token(address indexed tokenAddress, uint256 tokens);

    mapping(address => bool) _verify;

     
     
     
     
     
     
     
     
     
     
     
     
    function verify(address tradeContract) constant returns (
        bool    valid,
        address owner,
        address asset,
        uint256 sellPrice,
        uint256 units,
        bool    sellsTokens
    ) {
        valid = _verify[tradeContract];
        if (valid) {
            TokenSeller t = TokenSeller(tradeContract);
            owner         = t.owner();
            asset         = t.asset();
            sellPrice     = t.sellPrice();
            units         = t.units();
            sellsTokens   = t.sellsTokens();
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function createSaleContract(
        address asset,
        uint256 sellPrice,
        uint256 units,
        bool    sellsTokens
    ) returns (address seller) {
         
        if (asset == 0x0) throw;
         
        if (sellPrice <= 0) throw;
         
        if (units <= 0) throw;
        seller = new TokenSeller(
            asset,
            sellPrice,
            units,
            sellsTokens);
         
        _verify[seller] = true;
         
        TokenSeller(seller).transferOwnership(msg.sender);
        TradeListing(msg.sender, seller, asset, sellPrice, units, sellsTokens);
    }

     
     
     
     
     
     
     
     
     
    function ownerWithdrawERC20Token(address tokenAddress, uint256 tokens) onlyOwner returns (bool ok) {
        OwnerWithdrewERC20Token(tokenAddress, tokens);
        return ERC20Partial(tokenAddress).transfer(owner, tokens);
    }

     
    function () {
        throw;
    }
}