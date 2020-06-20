pragma solidity ^0.4.21;


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}







 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




 
library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Crowdsale {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    address public fundWallet;
    
     
    address public admin;

     
    uint256 public rate = 10000;

     
    uint256 public amountRaised;

     
    bool public crowdsaleOpen;

     
    uint256 public cap;

   
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

   
    function Crowdsale(ERC20 _token, address _fundWallet) public {
        require(_token != address(0));
        require(_fundWallet != address(0));

        fundWallet = _fundWallet;
        admin = msg.sender;
        token = _token;
        crowdsaleOpen = true;
        cap = 20000 * 1 ether;
    }

   
   
   

   
    function () external payable {
        buyTokens();
    }

   
    function buyTokens() public payable {

         
        require(crowdsaleOpen);
        require(msg.sender != address(0));
        require(msg.value != 0);
        require(amountRaised.add(msg.value) <= cap);
        
         
        uint256 tokens = (msg.value).mul(rate);

         
        amountRaised = amountRaised.add(msg.value);

         
        token.transfer(msg.sender, tokens);

         
        fundWallet.transfer(msg.value);

        emit TokenPurchase (msg.sender, msg.value, tokens);
    }

    function lockRemainingTokens() onlyAdmin public {
        token.transfer(admin, token.balanceOf(address(this)));
    }

    function setRate(uint256 _newRate) onlyAdmin public {
        rate = _newRate;    
    }
    
    function setFundWallet(address _fundWallet) onlyAdmin public {
        require(_fundWallet != address(0));
        fundWallet = _fundWallet; 
    }

    function setCrowdsaleOpen(bool _crowdsaleOpen) onlyAdmin public {
        crowdsaleOpen = _crowdsaleOpen;
    }

    function getEtherRaised() view public returns (uint256){
        return amountRaised / 1 ether;
    }

    function capReached() public view returns (bool) {
        return amountRaised >= cap;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }  

}