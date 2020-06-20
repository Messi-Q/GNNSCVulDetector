pragma solidity 0.4.24;

interface token {
    function transfer(address receiver, uint amount) external;
    function burn(uint amount) external returns(bool success);
}

contract InterbetCoinCrowdsale {

     
    uint constant ibcTokenDecimals = 18;  

    token public tokenReward = token(0xCBbb6861423440170680b538d136FfE17A4b661a);  
    address public beneficiary = 0x560b989db52368696bDC1db587eA52787Fdc3406;  
    address public admin = 0x8dd4866a5BaB83e1e2433e6e74B8385D12b838A3;  

     
    event FundTransfer(SaleStage indexed saleStage, address indexed contributor, uint amount, bool isContribution);
    event CrowdsaleClosed(address recipient, uint totalAmountRaised);
    event TokenClaimed(address indexed contributor, uint tokenAmount);

     
    enum SaleStage {
        NotStarted,
        Presale,
        Break,
        ICO,
        Closed
    }

    SaleStage public currentSaleStage;

    uint public minFundInEther = 10 * 1 finney;  

    uint public presalePrice = 10000;  
    uint public presaleFundingTargetInEther = 3000 * 1 ether;  

    uint public breakDurationBetweenPresaleAndICO = 1 weeks;  
    uint public icoPhaseTimeInterval = 1 weeks;  

    uint public icoStart;  
    uint public icoTimeBonusPhase1End;  
    uint public icoTimeBonusPhase2End;  
    uint public icoEnd;  
    uint public icoPrice = 5000;  
    uint public totalFundingGoalInIBC = 630000000 * (10 ** ibcTokenDecimals);  
    uint public fundingRatePredictionBonusPoolInIBC = 70000000 * (10 ** ibcTokenDecimals);  

    uint public icoReferralBonusInPercentage = 5;  
    uint public icoPhase1TimeBonusInPercentage = 20;  
    uint public icoPhase2TimeBonusInPercentage = 10;  
    uint public icoPhase3TimeBonusInPercentage = 0;  
    uint public icoFundingRatePredictionBonusInPercentage = 25;  

    uint public fundingRatePredictionBonusClaimWindow = 4 weeks;  

    uint public etherRaised = 0;  
    uint public ibcFunded = 0;  
    uint public ibcDistributed = 0;  
    uint public contributionCount = 0;  

    mapping(address => uint256) public balanceOf;  
    mapping(address => uint256) public ibcVaultBalanceOf;  
    mapping(address => uint256) public baseRewardTokenBalanceOf;  

    mapping(address => uint256) public fundingRatePredictionOf;  
    mapping(address => bool) public fundingRatePredictionBingoOf;  

    constructor() public {
        currentSaleStage = SaleStage.Presale;
    }

     
    function () external payable {
        require(currentSaleStage == SaleStage.Presale || currentSaleStage == SaleStage.Break || currentSaleStage == SaleStage.ICO);

        if (currentSaleStage == SaleStage.Presale) {
            participatePresaleNow();
        } else if (currentSaleStage == SaleStage.Break || currentSaleStage == SaleStage.ICO) {
            participateICONow(address(0), 0);
        }
    }

     
    function participatePresale() external payable {
        participatePresaleNow();
    }

    function participatePresaleNow() private {
        require(currentSaleStage == SaleStage.Presale);
        require(etherRaised < presaleFundingTargetInEther);

        require(msg.value >= minFundInEther);

        uint amount = msg.value;

        uint price = presalePrice;

        uint tokenAmount = mul(amount, price);
        require(add(ibcFunded, tokenAmount) <= totalFundingGoalInIBC);

        if (add(etherRaised, amount) >= presaleFundingTargetInEther) {
            updateSaleStage(SaleStage.Break);
        }

        balanceOf[msg.sender] = add(balanceOf[msg.sender], amount);

        etherRaised = add(etherRaised, amount);

        contributionCount++;

        ibcFunded = add(ibcFunded, tokenAmount);

        ibcVaultBalanceOf[msg.sender] = add(ibcVaultBalanceOf[msg.sender], tokenAmount);

        emit FundTransfer(SaleStage.Presale, msg.sender, amount, true);
    }    

     
    function participateICO(address referrer, uint fundingRatePrediction) external payable {
        participateICONow(referrer, fundingRatePrediction);
    }

    function participateICONow(address referrer, uint fundingRatePrediction) private {
        require(currentSaleStage == SaleStage.Break || currentSaleStage == SaleStage.ICO);
        if (currentSaleStage == SaleStage.Break) {
            if (now >= icoStart && now < icoEnd) {
                updateSaleStage(SaleStage.ICO);
            } else {
                revert();
            }
        } else if (currentSaleStage == SaleStage.ICO) {
            require(now >= icoStart && now < icoEnd);
        }

        require(referrer != msg.sender);
        require(fundingRatePrediction >= 1 && fundingRatePrediction <= 100);

        uint amount = msg.value;

        uint price = icoPrice;

        uint baseRewardTokenAmount = mul(amount, price);
        uint tokenAmount = add(baseRewardTokenAmount, calculateInstantBonusAmount(baseRewardTokenAmount, referrer));
        
        uint referrerReferralBonus = 0;
        if (referrer != address(0)) {
            referrerReferralBonus = mul(baseRewardTokenAmount, icoReferralBonusInPercentage) / 100;
        }

        if (add(add(ibcFunded, tokenAmount), referrerReferralBonus) < totalFundingGoalInIBC) {
            require(msg.value >= minFundInEther);
        } else {
            require(add(add(ibcFunded, tokenAmount), referrerReferralBonus) == totalFundingGoalInIBC);
        }

        if (add(add(ibcFunded, tokenAmount), referrerReferralBonus) == totalFundingGoalInIBC) {
            updateSaleStage(SaleStage.Closed);
        }

        balanceOf[msg.sender] = add(balanceOf[msg.sender], amount);

        baseRewardTokenBalanceOf[msg.sender] = add(baseRewardTokenBalanceOf[msg.sender], baseRewardTokenAmount);
        fundingRatePredictionOf[msg.sender] = fundingRatePrediction;

        etherRaised = add(etherRaised, amount);

        contributionCount++;

        ibcFunded = add(ibcFunded, tokenAmount);

        ibcVaultBalanceOf[msg.sender] = add(ibcVaultBalanceOf[msg.sender], tokenAmount);

        if (referrerReferralBonus != 0) {
            ibcFunded = add(ibcFunded, referrerReferralBonus);
            ibcVaultBalanceOf[referrer] = add(ibcVaultBalanceOf[referrer], referrerReferralBonus);
        }

        emit FundTransfer(SaleStage.ICO, msg.sender, amount, true);
    }

     
    function calculateInstantBonusAmount(uint baseRewardTokenAmount, address referrer) internal view returns(uint) {
        uint timeBonus = 0;
        uint timeBonusInPercentage = checkTimeBonusPercentage();
        if (timeBonusInPercentage != 0) {
            timeBonus = mul(baseRewardTokenAmount, timeBonusInPercentage) / 100;
        }

        uint referralBonus = 0;
        if (referrer != address(0)) {
            referralBonus = mul(baseRewardTokenAmount, icoReferralBonusInPercentage) / 100;
        }

        uint instantBonus = add(timeBonus, referralBonus);

        return instantBonus;
    }

     
    function checkTimeBonusPercentage() internal view returns(uint) {
        uint timeBonusInPercentage = 0;

        if (now < icoTimeBonusPhase1End) {
            timeBonusInPercentage = icoPhase1TimeBonusInPercentage;
        } else if (now < icoTimeBonusPhase2End) {
            timeBonusInPercentage = icoPhase2TimeBonusInPercentage;
        }

        return timeBonusInPercentage;
    }

     
    function claimToken() external {
        require(currentSaleStage == SaleStage.ICO || currentSaleStage == SaleStage.Closed);
        if (currentSaleStage == SaleStage.ICO) {
            if (ibcFunded == totalFundingGoalInIBC || now >= icoEnd) {
                updateSaleStage(SaleStage.Closed);
            } else {
                revert();
            }
        }

        require(ibcVaultBalanceOf[msg.sender] > 0);

        uint tokenAmount = ibcVaultBalanceOf[msg.sender];

        if (now < icoEnd + fundingRatePredictionBonusClaimWindow) {
            if (fundingRatePredictionBonusPoolInIBC > 0) {
                uint finalFundingRate = mul(ibcFunded, 100) / totalFundingGoalInIBC;
                if (finalFundingRate > 100) {
                    finalFundingRate = 100;
                }

                if (fundingRatePredictionOf[msg.sender] == finalFundingRate) {
                    if (!fundingRatePredictionBingoOf[msg.sender]) {
                        fundingRatePredictionBingoOf[msg.sender] = true;

                        uint fundingRatePredictionBingoBonus = mul(baseRewardTokenBalanceOf[msg.sender], icoFundingRatePredictionBonusInPercentage) / 100;

                        if (fundingRatePredictionBingoBonus > fundingRatePredictionBonusPoolInIBC) {
                            fundingRatePredictionBingoBonus = fundingRatePredictionBonusPoolInIBC;
                        }

                        fundingRatePredictionBonusPoolInIBC = sub(fundingRatePredictionBonusPoolInIBC, fundingRatePredictionBingoBonus);

                        tokenAmount = add(tokenAmount, fundingRatePredictionBingoBonus);
                    }
                }
            }
        }

        ibcVaultBalanceOf[msg.sender] = 0;

        ibcDistributed = add(ibcDistributed, tokenAmount);

        tokenReward.transfer(msg.sender, tokenAmount);

        emit TokenClaimed(msg.sender, tokenAmount);
    }    

    function updateSaleStage(SaleStage saleStage) private {
        currentSaleStage = saleStage;

        if (saleStage == SaleStage.Break) {
            icoStart = now + breakDurationBetweenPresaleAndICO;
            icoTimeBonusPhase1End = icoStart + icoPhaseTimeInterval;
            icoTimeBonusPhase2End = icoTimeBonusPhase1End + icoPhaseTimeInterval;
            icoEnd = icoTimeBonusPhase2End + icoPhaseTimeInterval;
        } else if (saleStage == SaleStage.Closed) {
            if (now < icoEnd) {
                icoEnd = now;
            }

            if (ibcFunded < totalFundingGoalInIBC) {
                fundingRatePredictionBonusPoolInIBC = add(fundingRatePredictionBonusPoolInIBC, sub(totalFundingGoalInIBC, ibcFunded));
            }

            emit CrowdsaleClosed(beneficiary, etherRaised);
        }
    }

     
    function updateSaleStageManually(uint saleStage) external {
        require(msg.sender == admin);

        require(saleStage >= 1 && saleStage <= 4);

        require(saleStage > uint(currentSaleStage));

        updateSaleStage(SaleStage(saleStage));
    }

     
    function withdrawEther(uint amount) external {
        require(msg.sender == beneficiary);

        if (beneficiary.send(amount)) {
           emit FundTransfer(SaleStage.Closed, beneficiary, amount, false);
        }
    }

     
    function burnAllRemainingIBC() external {
        require(currentSaleStage == SaleStage.Closed);

        require(now >= icoEnd + fundingRatePredictionBonusClaimWindow);

        require(msg.sender == admin);

        require(fundingRatePredictionBonusPoolInIBC > 0);

        uint currentFundingRatePredictionBonusPoolInIBC = fundingRatePredictionBonusPoolInIBC;
        fundingRatePredictionBonusPoolInIBC = 0;

        if (!tokenReward.burn(currentFundingRatePredictionBonusPoolInIBC)) {
            fundingRatePredictionBonusPoolInIBC = currentFundingRatePredictionBonusPoolInIBC;
        }
    }

     
    function mul(uint256 _a, uint256 _b) private pure returns(uint256 c) {
        if (_a == 0) {
          return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function sub(uint256 _a, uint256 _b) private pure returns(uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) private pure returns(uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }

}