pragma solidity ^ 0.4.17;


library SafeMath {
    function mul(uint a, uint b) pure internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) pure internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) pure internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) 
            owner = newOwner;
    }

    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
            _;
    }
}


contract Pausable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        if (stopped) {
            revert();
        }
        _;
    }

    modifier onlyInEmergency {
        if (!stopped) {
            revert();
        }
        _;
    }

     
    function emergencyStop() external onlyOwner() {
        stopped = true;
    }

     
    function release() external onlyOwner() onlyInEmergency {
        stopped = false;
    }
}

contract WhiteList is Ownable {

    function isWhiteListedAndAffiliate(address _user) external view returns (bool, address);
}

 
 
contract Crowdsale is Pausable {

    using SafeMath for uint;

    struct Backer {
        uint weiReceived;  
        uint tokensToSend;  
        bool claimed;
        bool refunded;  
    }

    Token public token;  
    address public multisig;  
    address public team;  
    uint public teamTokens;  
    uint public ethReceivedPresale;  
    uint public ethReceivedMain;  
    uint public totalTokensSent;  
    uint public totalAffiliateTokensSent;
    uint public startBlock;  
    uint public endBlock;  
    uint public maxCap;  
    uint public minCap;  
    uint public minInvestETH;  
    bool public crowdsaleClosed;  
    Step public currentStep;   
    uint public refundCount;   
    uint public totalRefunded;  
    uint public tokenPriceWei;   
    WhiteList public whiteList;  
    uint public numOfBlocksInMinute; 
    uint public claimCount;  
    uint public totalClaimed;  
    

    mapping(address => Backer) public backers;  
    mapping(address => uint) public affiliates;  
    address[] public backersIndex;  
    mapping(address => uint) public claimed;   

    
     
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }

     
    enum Step {
        Unknown,
        FundingPreSale,      
        FundingPublicSale,   
        Refunding,   
        Claiming     
    }

     
    event ReceivedETH(address indexed backer, address indexed affiliate, uint amount, uint tokenAmount, uint affiliateTokenAmount);
    event RefundETH(address backer, uint amount);
    event TokensClaimed(address backer, uint count);


     
     
    function Crowdsale(WhiteList _whiteListAddress) public {
        multisig = 0x49447Ea549CCfFDEF2E9a9290709d6114346df88; 
        team = 0x49447Ea549CCfFDEF2E9a9290709d6114346df88;                                         
        startBlock = 0;  
        endBlock = 0;  
        tokenPriceWei = 108110000000000;
        maxCap = 210000000e18;         
        minCap = 21800000e18;        
        totalTokensSent = 0;   
        setStep(Step.FundingPreSale);
        numOfBlocksInMinute = 416;    
        whiteList = WhiteList(_whiteListAddress);    
        teamTokens = 45000000e18;
    }

     
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, Step, bool, bool) {            
    
        return (startBlock, endBlock, backersIndex.length, ethReceivedPresale.add(ethReceivedMain), maxCap, minCap, totalTokensSent, tokenPriceWei, currentStep, stopped, crowdsaleClosed);
    }

     
     
     
    function updateTokenAddress(Token _tokenAddress) external onlyOwner() returns(bool res) {
        token = _tokenAddress;
        return true;
    }

     
     
    function setStep(Step _step) public onlyOwner() {
        currentStep = _step;
        
        if (currentStep == Step.FundingPreSale) {   
          
            minInvestETH = 1 ether/5;                             
        }else if (currentStep == Step.FundingPublicSale) {  
            minInvestETH = 1 ether/10;               
        }      
    }

     
     
    function () external payable {           
        contribute(msg.sender);
    }

     
    function start(uint _block) external onlyOwner() {   

        require(_block < 335462);   
        startBlock = block.number;
        endBlock = startBlock.add(_block); 
    }

     
     
    function adjustDuration(uint _block) external onlyOwner() {

        require(_block < 389376);   
        require(_block > block.number.sub(startBlock));  
        endBlock = startBlock.add(_block); 
    }

     
     
     
    function contribute(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {

        uint affiliateTokens;

        var(isWhiteListed, affiliate) = whiteList.isWhiteListedAndAffiliate(_backer);

        require(isWhiteListed);       
    
        require(currentStep == Step.FundingPreSale || currentStep == Step.FundingPublicSale);  
        require(msg.value >= minInvestETH);    
          
        uint tokensToSend = determinePurchase();

        if (affiliate != address(0)) {
            affiliateTokens = (tokensToSend * 5) / 100;  
            affiliates[affiliate] += affiliateTokens;
            Backer storage referrer = backers[affiliate];
            referrer.tokensToSend = referrer.tokensToSend.add(affiliateTokens);
        }
        
        require(totalTokensSent.add(tokensToSend.add(affiliateTokens)) < maxCap);  
            
        Backer storage backer = backers[_backer];
    
        if (backer.tokensToSend == 0)      
            backersIndex.push(_backer);
           
        backer.tokensToSend = backer.tokensToSend.add(tokensToSend);  
        backer.weiReceived = backer.weiReceived.add(msg.value);   
        totalTokensSent += tokensToSend + affiliateTokens;      
        totalAffiliateTokensSent += affiliateTokens;
    
        if (Step.FundingPublicSale == currentStep)   
            ethReceivedMain = ethReceivedMain.add(msg.value);
        else
            ethReceivedPresale = ethReceivedPresale.add(msg.value);     
       
        multisig.transfer(this.balance);    
    
        ReceivedETH(_backer, affiliate, msg.value, tokensToSend, affiliateTokens);  
        return true;
    }

     
     
    function determinePurchase() internal view  returns (uint) {
       
        require(msg.value >= minInvestETH);                         
        uint tokenAmount = msg.value.mul(1e18) / tokenPriceWei;     

        uint tokensToSend;  

        if (currentStep == Step.FundingPreSale)
            tokensToSend = calculateNoOfTokensToSend(tokenAmount); 
        else
            tokensToSend = tokenAmount;
                                                                                                       
        return tokensToSend;
    }

     
     
    function calculateNoOfTokensToSend(uint _tokenAmount) internal view  returns (uint) {
              
        if (block.number <= startBlock + (numOfBlocksInMinute * 60 * 24 * 14) / 100)         
            return  _tokenAmount + (_tokenAmount * 40) / 100;   
        else if (block.number <= startBlock + (numOfBlocksInMinute * 60 * 24 * 28) / 100)    
            return  _tokenAmount + (_tokenAmount * 30) / 100;  
        else
            return  _tokenAmount + (_tokenAmount * 20) / 100;    
          
    }

     
     
    function eraseContribution(address _backer) external onlyOwner() {

        Backer storage backer = backers[_backer];        
        backer.refunded = true;
        totalTokensSent = totalTokensSent.sub(backer.tokensToSend);        
    }

     
     
     
    function addManualContributor(address _backer, uint _amountTokens) external onlyOwner() {

        Backer storage backer = backers[_backer];        
        backer.tokensToSend = backer.tokensToSend.add(_amountTokens);
        if (backer.tokensToSend == 0)      
            backersIndex.push(_backer);
        totalTokensSent = totalTokensSent.add(_amountTokens);
    }


     
     
    function claimTokens() external {
        claimTokensForUser(msg.sender);
    }

     
     
    function adminClaimTokenForUser(address _backer) external onlyOwner() {
        claimTokensForUser(_backer);
    }

     
     
    function prepareRefund() public payable onlyOwner() {
        
        require(msg.value == ethReceivedMain + ethReceivedPresale);  
        currentStep == Step.Refunding;
    }

     
     
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }
 
     
     
     
    function claimTokensForUser(address _backer) internal returns(bool) {       

        require(currentStep == Step.Claiming);
                  
        Backer storage backer = backers[_backer];

        require(!backer.refunded);       
        require(!backer.claimed);        
        require(backer.tokensToSend != 0);    

        claimCount++;
        claimed[_backer] = backer.tokensToSend;   
        backer.claimed = true;
        totalClaimed += backer.tokensToSend;
        
        if (!token.transfer(_backer, backer.tokensToSend)) 
            revert();  

        TokensClaimed(_backer, backer.tokensToSend);  
    }


     
     
     
    function finalize() external onlyOwner() {

        require(!crowdsaleClosed);        
         
         
        require(block.number >= endBlock || totalTokensSent >= maxCap.sub(1000));                 
        require(totalTokensSent >= minCap);   

        crowdsaleClosed = true;  
        
        if (!token.transfer(team, teamTokens))  
            revert();

        if (!token.burn(this, maxCap - totalTokensSent))  
            revert();  
        token.unlock();                      
    }

     
    function drain() external onlyOwner() {
        multisig.transfer(this.balance);               
    }

     
    function tokenDrian() external onlyOwner() {
        if (block.number > endBlock) {
            if (!token.transfer(team, token.balanceOf(this))) 
                revert();
        }
    }
    
     
    function refund() external stopInEmergency returns (bool) {

        require(currentStep == Step.Refunding);         
       
        require(this.balance > 0);   
                                     

        Backer storage backer = backers[msg.sender];

        require(backer.weiReceived > 0);   
        require(!backer.refunded);          
        require(!backer.claimed);        
       
        backer.refunded = true;   
    
        refundCount++;
        totalRefunded = totalRefunded.add(backer.weiReceived);
        msg.sender.transfer(backer.weiReceived);   
        RefundETH(msg.sender, backer.weiReceived);
        return true;
    }
}


contract ERC20 {
    uint public totalSupply;
   
    function transfer(address to, uint value) public returns(bool ok);  
}


 
contract Token is ERC20, Ownable {

    function returnTokens(address _member, uint256 _value) public returns(bool);
    function unlock() public;
    function balanceOf(address _owner) public view returns(uint balance);
    function burn( address _member, uint256 _value) public returns(bool);
}