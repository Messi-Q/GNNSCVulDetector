pragma solidity ^0.4.21;

 

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

  function max(uint a, uint b) internal pure returns (uint) {
    if (a > b) return a;
    else return b;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    if (a < b) return a;
    else return b;
  }
}


 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
     
}

contract EthWuxia is ERC721{
  using SafeMath for uint256;

  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  uint public produceUnitSeconds = 86400;   
  uint public freeLotterySeconds = 3600 * 6;   
  uint public unitRareGrowth = 3;   
  uint public unitEpicGrowth = 0;   
  uint public unitMythGrowth = 0;   
  uint public initialMartialTimes=1;   
  uint public stepPrice = 1 finney;
  uint public lotteryPrice = 10 finney;   
  uint public dragonGirlLotteryPrice = 10 finney;
  uint public dragonGirlLotteryNumber = 0;
  address[] public listedDragonGirlLotteryUser = [address(0), address(0), address(0), address(0), address(0)];
  address public wuxiaMaster = address(0);
  uint public wuxiaMasterPrice = 100 finney;   
  mapping (uint256 => address) public approvedOfItem;
  uint public littleMonster = 1 ether;  


  uint public totalEarning = 0;   
  uint public totalTrading = 0;   
  uint public lotteryTotalEarning = 0;   
  uint public marketTotalEarning = 0;   
  uint public smartSpeedEarning = 0;
  uint public luckyStoneEarning = 0;
  uint public hunterLicenceEarning = 0;
  uint public travelTotalEarning = 0;
  uint public masterTotalEarning = 0;
   
  bool public lotteryGiveHunt = false;
  uint public lotteryGiveHuntMinimalNumber = 10;
  uint public randNonce = 0;


  mapping (address => uint) public mapUserLastFreeLotteryTimestamp;   
  mapping (address => uint) public mapUserPower;   

   
  mapping (address => bool) public mapUserHasSmartSpeed;   
  uint public currentSmartSpeedNumber = 0;
   

  mapping (address => bool) public mapUserHasLuckyStone;   
  uint public currentLuckyStoneNumber = 0;
   

  mapping (address => bool) public mapUserHasHunterLicence;
  uint public currentHunterNumber = 0;
   

  uint public totalUserNumber = 0;
  uint public totalLotteryNumber = 0;
  uint public totalBuyCardNumber = 0;
  uint public totalSellCardNumber = 0;
  uint public totalDragonLotteryNumber = 0;
  mapping (uint => uint) public mapMartialUserCount;   
  mapping (uint => uint) public mapMartialLotteryCount;   
  mapping (address => uint) public mapUserLotteryNumber;

   
  struct Martial {
      uint x;   
      uint y;   
      address owner;   
      uint lastProduceTime;   
      uint martialId;
      uint rareNumber;   
      uint epicNumber;   
      uint mythNumber;   
      uint enterPrice;   
      uint[] cardTypeList;   
  }

   
   
   
   
  struct EtherMonster {
      uint monsterId;
      uint martialId;   
      uint balance;   
      uint blood;   
      uint produceTime;   
      uint currentBlood;   
      bool defeated;   
      address winner;   
  }

  mapping (address => uint) public mapUserLastAttackMonsterTimestamp;
  uint public userAttackMonsterCDSeconds = 600;   
  uint public maxUserPower = 0;   
  address public maxPowerUserAddress = address(0);
  uint etherMonsterHuntSeconds = 3600;   
  uint littleEtherMonsterUnit = 0.5 ether;   
  uint bigEtherMonsterUnit = 5 ether;   

  struct CardType {
      uint typeId;
      uint martialId;   
      uint initPower;   
      uint growthFactor;   
      uint category;   
  }

   
  struct Card {
      uint cardId;
      uint typeId;
      uint level;   
      bool onSell;
      uint sellPrice;
      address owner;
  }


  address private owner;
  mapping (address => bool) private admins;

  IItemRegistry private itemRegistry;
  uint public travelUnitFee = 1 finney;  

  uint256[] private listedItems;
  Martial[] public listedMartials;   
  CardType[] public listedCardType;   
  Card[] public listedCard;
  EtherMonster[] public listedEtherMonster;

  uint smallMonsterPowerFactor = 3;
  uint bigMonsterPowerFactor = 5;

  mapping (uint256 => address) public mapOwnerOfCard;
  mapping (address => uint) private mapUserCurrentMartialId;   
  mapping (address => bool) public mapUesrAlreadyMartialOwner;
  mapping (address => bytes32) public mapUserNickname;

  bool public hasInitMartial = false;
  bool public hasInitCard1 = false;
  bool public hasInitCard2 = false;

  function EthWuxia () public {
      owner = msg.sender;
      admins[owner] = true;
      lotteryGiveHunt = true;
  }

   
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  modifier onlyAdmins() {
    require(admins[msg.sender]);
    _;
  }

   
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }

  function getOwner() public view returns(address){
      return owner;
  }
  function setItemRegistry (address _itemRegistry) onlyOwner() public {
    itemRegistry = IItemRegistry(_itemRegistry);
  }

  function addAdmin (address _admin) onlyOwner() public {
    admins[_admin] = true;
  }

  function removeAdmin (address _admin) onlyOwner() public {
    delete admins[_admin];
  }
  
  function disableLotteryGiveHunt() onlyOwner() public {
      lotteryGiveHunt = false;
  }
  
  function enableLotteryGiveHunt() onlyOwner() public {
      lotteryGiveHunt = true;
  }

   
   
   
   
  function createNewMartial (uint x, uint y, uint enterPrice) onlyOwner() public {
    require(x>=1);
    require(y>=1);
    Martial memory martial = Martial(x, y, address(0), now, listedMartials.length, unitRareGrowth * initialMartialTimes, unitEpicGrowth * initialMartialTimes, unitMythGrowth * initialMartialTimes, enterPrice, new uint[](0));
    listedMartials.push(martial);
  }

   
  function createNewCardType (uint martialId, uint initPower, uint growthFactor, uint category) onlyOwner() public {
    require(initPower>=1);
    require(growthFactor>=2);
    require(category>=1);
    require(category<=4);   
    require(martialId < listedMartials.length);
    listedMartials[martialId].cardTypeList.push(listedCardType.length);
    CardType memory cardType = CardType(listedCardType.length, martialId, initPower, growthFactor, category);
    listedCardType.push(cardType);
  }

   
   
   
   
   
   
   
   
   
   
   
   
   

   
  function userHasSmartSpeed(address userAddress) public view returns(bool) {
    return mapUserHasSmartSpeed[userAddress];
  }

  function getCurrentSmartSpeedPrice() public view returns(uint) {
     
    return SafeMath.mul(SafeMath.min(10, currentSmartSpeedNumber), 10 finney);
  }

  function buySmartSpeed () public payable {
    uint currentSmartSpeedPrice = SafeMath.mul(SafeMath.min(10, currentSmartSpeedNumber), 10 finney);
    require(msg.value >= currentSmartSpeedPrice);
    require(!mapUserHasSmartSpeed[msg.sender]);
    uint excess = msg.value.sub(currentSmartSpeedPrice);
    currentSmartSpeedNumber += 1;

    if (excess > 0) {
      msg.sender.transfer(excess);
    }
    mapUserHasSmartSpeed[msg.sender] = true;

    _tryCreateEtherMonster(totalEarning, totalEarning.add(currentSmartSpeedPrice));
    totalEarning = totalEarning.add(currentSmartSpeedPrice);
    totalTrading = totalTrading.add(currentSmartSpeedPrice);
    smartSpeedEarning = smartSpeedEarning.add(currentSmartSpeedPrice);
  }

   
  function userHasLuckyStone(address userAddress) public view returns(bool) {
    return mapUserHasLuckyStone[userAddress];
  }

  function getCurrentLuckyStonePrice() public view returns(uint) {
     
    return SafeMath.mul(SafeMath.min(10, currentLuckyStoneNumber), 10 finney);
  }

  function buyLuckyStone() public payable {
    uint currentLuckyStonePrice = SafeMath.mul(SafeMath.min(10, currentLuckyStoneNumber), 10 finney);
    require(msg.value >= currentLuckyStonePrice);
    require(!mapUserHasLuckyStone[msg.sender]);
    uint excess = msg.value.sub(currentLuckyStonePrice);
    currentLuckyStoneNumber += 1;
    if (excess > 0) {
      msg.sender.transfer(excess);
    }
    mapUserHasLuckyStone[msg.sender] = true;
    _tryCreateEtherMonster(totalEarning, totalEarning.add(currentLuckyStonePrice));
    totalEarning = totalEarning.add(currentLuckyStonePrice);
    totalTrading = totalTrading.add(currentLuckyStonePrice);
    luckyStoneEarning = luckyStoneEarning.add(currentLuckyStonePrice);
  }

  function createEtherMonster(uint martialId, uint balance, uint blood) public onlyOwner {
      require(martialId<listedMartials.length);
      require(balance>0);
      require(blood>0);
      require(balance<address(this).balance);
      EtherMonster memory monster = EtherMonster(listedEtherMonster.length, martialId, balance, blood, now, blood, false, address(0));
      listedEtherMonster.push(monster);
  }


   
  function userHasHunterLicence(address userAddress) public view returns(bool) {
      return mapUserHasHunterLicence[userAddress];
  }

  function getCurrentHunterLicencePrice() public view returns(uint) {
    return SafeMath.mul(SafeMath.min(10, currentHunterNumber), 10 finney);
  }

  function buyHunterLicence() public payable {
    uint currentHunterLicencePrice = SafeMath.mul(SafeMath.min(10, currentHunterNumber), 10 finney);
    require(msg.value >= currentHunterNumber);
    require(!mapUserHasHunterLicence[msg.sender]);
    uint excess = msg.value.sub(currentHunterLicencePrice);
    currentHunterNumber += 1;
    if (excess > 0) {
      msg.sender.transfer(excess);
    }
    mapUserHasHunterLicence[msg.sender] = true;

    _tryCreateEtherMonster(totalEarning, totalEarning.add(currentHunterLicencePrice));
    totalEarning = totalEarning.add(currentHunterLicencePrice);
    totalTrading = totalTrading.add(currentHunterLicencePrice);
    hunterLicenceEarning = hunterLicenceEarning.add(currentHunterLicencePrice);
  }

   
   
  function getUserCurrentMartialId() public view returns(uint) {
      return mapUserCurrentMartialId[msg.sender];
  }

   
   
  function getMartialInfo(uint martialId) public view returns(uint, uint, address, uint, uint, uint, uint, uint, uint, uint[]) {
    require(martialId < listedMartials.length);
    Martial memory martial = listedMartials[martialId];
    return (martial.x, martial.y, martial.owner, martial.lastProduceTime, martial.martialId, martial.rareNumber, martial.epicNumber, martial.mythNumber, martial.enterPrice, martial.cardTypeList);
  }
  
  function getMartialListInfo() public view returns(uint[]) {
       
      uint[] memory result = new uint[](listedMartials.length.mul(5)+1);
      uint index = 1;
      result[0] = listedMartials.length;
      for (uint i=0; i<listedMartials.length;i++) {
          Martial memory martial = listedMartials[i];
          result[index] = martial.rareNumber;
          result[index+1] = martial.epicNumber;
          result[index+2] = martial.mythNumber;
          result[index+3] = mapUserPower[martial.owner];
          result[index+4] = mapMartialUserCount[i];
          index += 5;
      }
      return result;
  }
  
  function getMartialOwner() public view returns(address[]) {
    address[] memory result = new address[](listedMartials.length);
    for (uint i=0;i<listedMartials.length;i++) {
        result[i] = listedMartials[i].owner;
    }
    return result;
  }
  
  function getMartialNumber() public view returns(uint) {
    return listedMartials.length;
  }

  function absSub(uint a, uint b) private pure returns(uint) {
    if (a>b) return a.sub(b);
    return b.sub(a);
  }
   
  function _getTravelPrice(address userAddress, uint martialId) private view returns(uint) {
    Martial storage currentMartial = listedMartials[mapUserCurrentMartialId[userAddress]];
    Martial storage nextMartial = listedMartials[martialId];
    require(currentMartial.martialId != nextMartial.martialId);   
    uint stepNumber = absSub(currentMartial.x, nextMartial.x).add(absSub(currentMartial.y, nextMartial.y));
    uint travelPrice = stepNumber.mul(stepPrice).add(nextMartial.enterPrice);
     
    if (mapUserHasSmartSpeed[userAddress]) {
      travelPrice = travelPrice.div(2);
    }
    return travelPrice;
  }

  function getTravelPrice(uint martialId) public view returns(uint) {
    return _getTravelPrice(msg.sender, martialId);
  }

   
  function changeMartial(uint martialId) public payable {
    uint travelPrice = _getTravelPrice(msg.sender, martialId);
    require(msg.value>=travelPrice);
    require(martialId<listedMartials.length);
    if (mapUserLotteryNumber[msg.sender] > 0) {
        if (mapMartialUserCount[mapUserCurrentMartialId[msg.sender]] > 0) {
            mapMartialUserCount[mapUserCurrentMartialId[msg.sender]] = mapMartialUserCount[mapUserCurrentMartialId[msg.sender]].sub(1);
        }
        mapMartialUserCount[martialId] += 1;
    }
    uint excess = msg.value.sub(travelPrice);
    if (excess>0) {
      msg.sender.transfer(excess);
    }
    mapUserCurrentMartialId[msg.sender] = martialId;
    _tryCreateEtherMonster(totalEarning, totalEarning.add(travelPrice));
    totalEarning = totalEarning.add(travelPrice);
    travelTotalEarning = travelTotalEarning.add(travelPrice);
  }

   
   
  function getRandomNumber(uint maxNumber) private returns(uint) {
    require(maxNumber>0);
    randNonce += 1;
    return uint(keccak256(now, randNonce, block.blockhash(block.number - 1), block.coinbase)) % maxNumber;
  }
   
   
  function _canLotteryFree(address userAddress) private view returns(bool) {
    uint lastLotteryTimestamp = mapUserLastFreeLotteryTimestamp[userAddress];
    return now - lastLotteryTimestamp > freeLotterySeconds;
  }

 
 
 
 
 

 
 
 

 
 
 
  function debug() public view returns(uint, uint, uint, uint, bool) {
      uint lastLotteryTimestamp = mapUserLastFreeLotteryTimestamp[msg.sender];
      return (now, lastLotteryTimestamp, now-lastLotteryTimestamp, freeLotterySeconds, now - lastLotteryTimestamp > freeLotterySeconds);
  }

  function getNowTimestamp() public view returns(uint) {
      return now;
  }

  function getMyLastFreeLotteryTimestamp() public view returns(uint) {
    return mapUserLastFreeLotteryTimestamp[msg.sender];
  }

  function canLotteryFree() public view returns(bool) {
    return _canLotteryFree(msg.sender);
  }

   
  function getMartialCardTypeIdList(uint martialId) public view returns(uint[]) {
    require(martialId<listedMartials.length);
    return listedMartials[martialId].cardTypeList;
  }

  function getCardTypeInfo(uint typeId) public view returns(uint, uint, uint, uint, uint) {
    require(typeId < listedCardType.length);
    CardType memory cardType = listedCardType[typeId];
    return (cardType.typeId, cardType.martialId, cardType.initPower, cardType.growthFactor, cardType.category);
  }

  function getCardPower(uint cardTypeId, uint cardLevel) public view returns(uint){
    require(cardLevel<=3);
    require(cardTypeId<listedCardType.length);
    CardType memory cardType = listedCardType[cardTypeId];
    if (cardLevel == 0) {
      return cardType.initPower;
    } else if (cardLevel == 1) {
      return cardType.initPower.mul(cardType.growthFactor);
    } else if (cardLevel == 2) {
      return cardType.initPower.mul(cardType.growthFactor).mul(cardType.growthFactor);
    } else if (cardLevel == 3) {
      return cardType.initPower.mul(cardType.growthFactor).mul(cardType.growthFactor).mul(cardType.growthFactor);
    }
  }

  function getUserPower(address userAddress) public view returns(uint) {
      return mapUserPower[userAddress];
  }
   
  function lottery() public payable {
    require((msg.value >= lotteryPrice || _canLotteryFree(msg.sender)));
    totalLotteryNumber = totalLotteryNumber.add(1);
    uint currentLotteryPrice = 0;
    if (_canLotteryFree(msg.sender)) {
      mapUserLastFreeLotteryTimestamp[msg.sender] = now;
    } else {
      currentLotteryPrice = lotteryPrice;
    }
    uint excess = msg.value.sub(currentLotteryPrice);
     
    uint userCurrentMartialId = mapUserCurrentMartialId[msg.sender];
    if (currentLotteryPrice > 0) {
      address martialOwner = listedMartials[userCurrentMartialId].owner;
      if (martialOwner != address(0)) {
        uint martialOwnerCut = currentLotteryPrice.mul(30).div(100);
        martialOwner.transfer(martialOwnerCut);
         
      }
    }
    if (excess>0) {
      msg.sender.transfer(excess);
    }
  
     
     
    uint martialCardTypeCount = listedMartials[userCurrentMartialId].cardTypeList.length;
     
    uint randomNumber = getRandomNumber(martialCardTypeCount.mul(1000));

    uint lotteryCardTypeId = listedMartials[userCurrentMartialId].cardTypeList[randomNumber % martialCardTypeCount];
     
    if (randomNumber % 10 >= 5) {
        lotteryCardTypeId = randomNumber % listedCardType.length;
    }
    randomNumber = randomNumber.div(10).div(martialCardTypeCount);
     
    if (now - listedMartials[userCurrentMartialId].lastProduceTime >= produceUnitSeconds) {
      listedMartials[userCurrentMartialId].epicNumber += unitEpicGrowth;
      listedMartials[userCurrentMartialId].rareNumber += unitRareGrowth;
      listedMartials[userCurrentMartialId].mythNumber += unitMythGrowth;
      listedMartials[userCurrentMartialId].lastProduceTime = listedMartials[userCurrentMartialId].lastProduceTime.add(produceUnitSeconds);
    }
    uint lotteryCardLevel = 0;
    Martial memory userCurrentMartial = listedMartials[userCurrentMartialId];
    uint luckyStoneFactor = 1;
    if (mapUserHasLuckyStone[msg.sender]) {
      luckyStoneFactor = 2;
    }

     
     
    if (randomNumber % 100 < userCurrentMartial.mythNumber.mul(luckyStoneFactor) && userCurrentMartial.mythNumber > 0 && currentLotteryPrice>0) {
      lotteryCardLevel = 3;
      listedMartials[userCurrentMartialId].mythNumber = listedMartials[userCurrentMartialId].mythNumber.sub(1);
    } else if (randomNumber % 100 < luckyStoneFactor.mul(userCurrentMartial.mythNumber.add(userCurrentMartial.epicNumber)) && userCurrentMartial.epicNumber > 0 && currentLotteryPrice > 0) {
      lotteryCardLevel = 2;
      listedMartials[userCurrentMartialId].epicNumber = listedMartials[userCurrentMartialId].epicNumber.sub(1);
    } else if (randomNumber % 100 < luckyStoneFactor.mul(userCurrentMartial.mythNumber.add(userCurrentMartial.epicNumber.add(userCurrentMartial.rareNumber))) && userCurrentMartial.rareNumber > 0 && currentLotteryPrice > 0) {
      lotteryCardLevel = 1;
      listedMartials[userCurrentMartialId].rareNumber = listedMartials[userCurrentMartialId].rareNumber.sub(1);
    }

     
    Card memory card = Card(listedCard.length, lotteryCardTypeId, lotteryCardLevel, false, 0, msg.sender);
    mapOwnerOfCard[listedCard.length] = msg.sender;
    if (mapUserLotteryNumber[msg.sender] == 0) {
        totalUserNumber = totalUserNumber.add(1);
        mapMartialUserCount[mapUserCurrentMartialId[msg.sender]] += 1;
    }
    mapUserLotteryNumber[msg.sender] += 1;
    if (lotteryGiveHunt && mapUserLotteryNumber[msg.sender] >= lotteryGiveHuntMinimalNumber) {
        if (mapUserHasHunterLicence[msg.sender] == false) {
            mapUserHasHunterLicence[msg.sender] = true;
        }
    }
    mapMartialLotteryCount[mapUserCurrentMartialId[msg.sender]] += 1;
    mapUserPower[msg.sender] = mapUserPower[msg.sender].add(getCardPower(lotteryCardTypeId, lotteryCardLevel));
    if (mapUserPower[msg.sender] > maxUserPower) {
      maxUserPower = mapUserPower[msg.sender];
      maxPowerUserAddress = msg.sender;
    }
    listedCard.push(card);

    _tryCreateEtherMonster(totalEarning, totalEarning.add(currentLotteryPrice));
    totalEarning = totalEarning.add(currentLotteryPrice);
    totalTrading = totalTrading.add(currentLotteryPrice);
    lotteryTotalEarning = lotteryTotalEarning.add(currentLotteryPrice);
  }

  function getCardNumber() public view returns(uint) {
      return listedCard.length;
  }

  function getCardInfo(uint cardId) public view returns(uint, uint, uint, bool, uint, address) {
      require(cardId<listedCard.length);
      Card memory card = listedCard[cardId];
      return (card.cardId, card.typeId, card.level, card.onSell, card.sellPrice, card.owner);
  }
  
  function getGameStats() public view returns(uint, uint, uint, uint, uint, address) {
      return (totalUserNumber, totalBuyCardNumber, totalLotteryNumber, totalEarning, totalTrading, wuxiaMaster);
  }

   
   
  function mergeCard(uint a, uint b) public {
    require(a<listedCard.length);
    require(b<listedCard.length);
    require(listedCard[a].typeId==listedCard[b].typeId);
    require(listedCard[a].level==listedCard[b].level);
    require(listedCard[a].level<=2);   
    require(!listedCard[a].onSell);
    require(!listedCard[b].onSell);
    require(mapOwnerOfCard[a]==msg.sender);
    require(mapOwnerOfCard[b]==msg.sender);
    Card memory card = Card(listedCard.length, listedCard[a].typeId, listedCard[a].level.add(1), false, 0, msg.sender);
    mapOwnerOfCard[a] = address(0);
    mapOwnerOfCard[b] = address(0);
    listedCard[a].owner = address(0);
    listedCard[b].owner = address(0);
    mapOwnerOfCard[listedCard.length] = msg.sender;
    listedCard.push(card);
     
    mapUserPower[msg.sender] = mapUserPower[msg.sender].add(getCardPower(listedCard[a].typeId, listedCard[a].level.add(1)).sub(getCardPower(listedCard[a].typeId, listedCard[a].level).mul(2)));
    if (mapUserPower[msg.sender] > maxUserPower) {
      maxUserPower = mapUserPower[msg.sender];
      maxPowerUserAddress = msg.sender;
    }
  }

   
   
  function beatMartialOwner() public returns (bool){
    uint myMartialId = mapUserCurrentMartialId[msg.sender];
    address martialOwner = listedMartials[myMartialId].owner;
    require(msg.sender!=martialOwner);
    require(!mapUesrAlreadyMartialOwner[msg.sender]);
     
    if (martialOwner==address(0)) {
      listedMartials[myMartialId].owner = msg.sender;
      mapUesrAlreadyMartialOwner[msg.sender] = true;
      mapUesrAlreadyMartialOwner[martialOwner] = false;
      return true;
    } else {
      if (mapUserPower[msg.sender] > mapUserPower[martialOwner]) {
        listedMartials[myMartialId].owner = msg.sender;
        mapUesrAlreadyMartialOwner[msg.sender] = true;
        mapUesrAlreadyMartialOwner[martialOwner] = false;
        return true;
      } else {
        return false;
      }
    }
  }

   
   
   
   
   
  function currentWulinMasterPrice() public view returns(uint){
    return wuxiaMasterPrice;
  }

  function buyWuxiaMaster() payable public {
    require(msg.value>=wuxiaMasterPrice);
    require(msg.sender!=wuxiaMaster);
     
    wuxiaMaster.transfer(wuxiaMasterPrice - 100 finney);
    uint excess = msg.value.sub(wuxiaMasterPrice);
     
    if (excess>0) {
      msg.sender.transfer(excess);
    }
     
    masterTotalEarning = masterTotalEarning.add(wuxiaMasterPrice);
    totalTrading = totalTrading.add(wuxiaMasterPrice);

     
    wuxiaMaster = msg.sender;
    wuxiaMasterPrice = wuxiaMasterPrice.add(100 finney);
  }


   
  function sellCard(uint cardId, uint price) public {
    require(cardId<listedCard.length);
    totalSellCardNumber = totalSellCardNumber.add(1);
    address cardOwner = mapOwnerOfCard[cardId];
    require(cardOwner!=address(0));   
    require(cardOwner==msg.sender);   
    require(!listedCard[cardId].onSell);  
    listedCard[cardId].onSell = true;
    listedCard[cardId].sellPrice = price;
  }

  function cancelSell(uint cardId) public {
    require(cardId<listedCard.length);
    address cardOwner = mapOwnerOfCard[cardId];
    require(cardOwner!=address(0));
    require(cardOwner==msg.sender);   
    require(listedCard[cardId].onSell);  
    listedCard[cardId].onSell = false;
  }

   
  function buyCard(uint cardId) payable public {
    require(mapOwnerOfCard[cardId]!=address(0));
    require(msg.sender!=mapOwnerOfCard[cardId]);
    require(listedCard[cardId].onSell);
    uint buyPrice = listedCard[cardId].sellPrice;
    totalBuyCardNumber = totalBuyCardNumber.add(1);
    require(msg.value>=buyPrice);
     
    uint excess = msg.value.sub(buyPrice);
    if (excess>0) {
      msg.sender.transfer(excess);
    }
     
    uint devCut = buyPrice.div(100).mul(0);
    uint masterCut = buyPrice.div(100).mul(5);
    if (wuxiaMaster==address(0)) {
      devCut = devCut.add(masterCut);
      masterCut = 0;
    } else {
      wuxiaMaster.transfer(masterCut);
    }
     
     
    uint masterPriceMinus = masterCut.mul(100).div(110);
    if (wuxiaMasterPrice >= masterPriceMinus.add(100 finney)) {
        wuxiaMasterPrice = wuxiaMasterPrice.sub(masterPriceMinus);
    } else {
        wuxiaMasterPrice = 100 finney;
    }
     
    uint moneyToSeller = buyPrice.sub(devCut.add(masterCut));
    mapOwnerOfCard[cardId].transfer(moneyToSeller);
     
    uint cardPower = getCardPower(listedCard[cardId].typeId, listedCard[cardId].level);
     
    listedCard[cardId].onSell = false;
    mapUserPower[mapOwnerOfCard[cardId]] = mapUserPower[mapOwnerOfCard[cardId]].sub(cardPower);
    mapUserPower[msg.sender] = mapUserPower[msg.sender].add(cardPower);
     
    mapOwnerOfCard[cardId] = msg.sender;
    listedCard[cardId].owner = msg.sender;
     
    _tryCreateEtherMonster(totalEarning, totalEarning.add(devCut));
    totalEarning = totalEarning.add(devCut);
    totalTrading = totalTrading.add(buyPrice);
    marketTotalEarning = marketTotalEarning.add(devCut);
  }

   
   
  function getCurrentDragonGirlLotteryNumber() public view returns(uint) {
    return dragonGirlLotteryNumber;
  }

  function buyLittleDragonGirlLottery() public payable{
    require(msg.value>=dragonGirlLotteryPrice);
    require(listedCardType.length>0);
    totalDragonLotteryNumber = totalDragonLotteryNumber.add(1);
    listedDragonGirlLotteryUser[dragonGirlLotteryNumber] = msg.sender;
    dragonGirlLotteryNumber = dragonGirlLotteryNumber.add(1);

    if (dragonGirlLotteryNumber == 5) {
       
      uint randomNumber = getRandomNumber(5);
      address winner = listedDragonGirlLotteryUser[randomNumber];
      mapOwnerOfCard[listedCard.length] = winner;
      Card memory card = Card(listedCard.length, 0, 0, false, 0, winner);
      listedCard.push(card);
       
      mapUserPower[winner] = mapUserPower[winner].add(getCardPower(0, 0));
      dragonGirlLotteryNumber = 0;
    }
  }

   
  function _tryCreateEtherMonster(uint price_a, uint price_b) private {
    uint priceTimes = price_b.div(0.5 ether);
     
    if (price_a<priceTimes*0.5 ether && price_b>=priceTimes*0.5 ether) {
       
      uint martialId = getRandomNumber(listedMartials.length);
      EtherMonster memory monster = EtherMonster(listedEtherMonster.length, martialId, 0.2 ether, maxUserPower.mul(smallMonsterPowerFactor), now, maxUserPower.mul(smallMonsterPowerFactor), false, address(0));
      listedEtherMonster.push(monster);
    }
    priceTimes = price_b.div(5 ether);
     
    if (price_a<priceTimes*5 ether && price_b>=priceTimes*5 ether) {
       
      uint bigMartialId = (getRandomNumber(listedEtherMonster.length).add(10007)) % listedMartials.length;
      EtherMonster memory bigMonster = EtherMonster(listedEtherMonster.length, bigMartialId, 1 ether, maxUserPower.mul(bigMonsterPowerFactor), now, maxUserPower.mul(bigMonsterPowerFactor), false, address(0));
      listedEtherMonster.push(bigMonster);
    }
  }

  function getEtherMonsterNumber() public view returns(uint) {
    return listedEtherMonster.length;
  }

  function getCanAttackMonsterIds() public view returns(uint[]) {
      uint[] memory result = new uint[](listedEtherMonster.length+1);
      uint index=0;
      for (uint i=0; i<listedEtherMonster.length; i++) {
        EtherMonster memory monster = listedEtherMonster[i];
        if (monster.produceTime.add(etherMonsterHuntSeconds)>now && !monster.defeated) {
            result[index] = i+1;
            index += 1;
        }
      }
      return result;
    }

  function getOnSellCardIds() public view returns(uint[]) {
      uint[] memory result = new uint[](listedCard.length+1);
      uint index = 0;
      for (uint i=0; i<listedCard.length; i++) {
          if (listedCard[i].onSell) {
              result[index] = i+1;
              index += 1;
          }
      }
      return result;
  }

  function getEtherMonsterInfo(uint monsterId) public view returns(uint, uint, uint, uint, uint, uint, bool, address) {
      require(monsterId<listedEtherMonster.length);
      EtherMonster memory monster = listedEtherMonster[monsterId];
      return (monster.monsterId, monster.martialId, monster.balance, monster.blood, monster.produceTime, monster.currentBlood, monster.defeated, monster.winner);
  }

   
  function attackMonster(uint monsterId) public {
     
    require(!listedEtherMonster[monsterId].defeated);   
    require(address(this).balance>=listedEtherMonster[monsterId].balance);   
    require(mapUserLastAttackMonsterTimestamp[msg.sender].add(userAttackMonsterCDSeconds) < now);
    require(listedEtherMonster[monsterId].produceTime.add(etherMonsterHuntSeconds) > now);
    require(mapUserHasHunterLicence[msg.sender]);   
     
    require(mapUserCurrentMartialId[msg.sender]==listedEtherMonster[monsterId].martialId);
     
    uint monsterCurrentBlood = listedEtherMonster[monsterId].currentBlood;
    uint monsterTotalBlood = listedEtherMonster[monsterId].blood;
    mapUserLastAttackMonsterTimestamp[msg.sender] = now;
    if (mapUserPower[msg.sender] >= monsterCurrentBlood) {
       
      listedEtherMonster[monsterId].defeated = true;
      listedEtherMonster[monsterId].winner = msg.sender;
      _sendMonsterPrize(monsterId, msg.sender);
    } else {
       
      uint randomNumber = getRandomNumber(monsterTotalBlood);
      if (randomNumber < mapUserPower[msg.sender]) {
        listedEtherMonster[monsterId].defeated = true;
        listedEtherMonster[monsterId].winner = msg.sender;
        _sendMonsterPrize(monsterId, msg.sender);
      } else {
        listedEtherMonster[monsterId].currentBlood = monsterCurrentBlood.sub(mapUserPower[msg.sender]);
      }
    }
  }

  function _sendMonsterPrize(uint monsterId, address winner) private {
    uint totalPrize = listedEtherMonster[monsterId].balance;
    uint martialOwnerCut = 0;
    if (listedMartials[listedEtherMonster[monsterId].martialId].owner != address(0)) {
      martialOwnerCut = totalPrize.mul(10).div(100);
    }
    winner.transfer(totalPrize.sub(martialOwnerCut));
    listedMartials[listedEtherMonster[monsterId].martialId].owner.transfer(martialOwnerCut);
  }

   
  function setNickname(bytes32 nickname) public {
    mapUserNickname[msg.sender] = nickname;
  }

  function getAddressNickname(address userAddress) public view returns(bytes32){
    return mapUserNickname[userAddress];
  }

   
  function listedMartialsLength() public view returns(uint length) {
      return listedMartials.length;
  }


    function initMartial() onlyOwner() public {
        require(!hasInitMartial);
        createNewMartial(16,14,0);
        createNewMartial(10,11,0);
        createNewMartial(13,10,0);
        createNewMartial(12,12,0);
        createNewMartial(4,3,0);
        createNewMartial(11,10,0);
        createNewMartial(6,14,0);
        createNewMartial(9,9,0);
        createNewMartial(10,10,0);
        createNewMartial(9,7,0);
        createNewMartial(12,10,0);
        hasInitMartial = true;
    }

  function initCard1() onlyOwner() public {
    require(!hasInitCard1);
    createNewCardType(1,8,10,1);
    createNewCardType(1,10,10,1);
    createNewCardType(1,8,10,1);
    createNewCardType(1,5,12,3);
    createNewCardType(1,4,12,3);
    createNewCardType(1,200,3,2);
    createNewCardType(1,200,3,2);
    createNewCardType(0,1,2,1);
    createNewCardType(0,1,30,3);
    createNewCardType(0,5,2,2);
    createNewCardType(0,3,2,2);
    createNewCardType(0,2,2,3);
    createNewCardType(0,4,2,3);
    createNewCardType(0,8,2,2);
    createNewCardType(2,12,10,1);
    createNewCardType(2,10,10,1);
    createNewCardType(2,5,12,3);
    createNewCardType(2,5,12,3);
    createNewCardType(2,4,12,3);
    createNewCardType(2,5,20,4);
    createNewCardType(2,18,15,4);
    createNewCardType(3,13,10,1);
    createNewCardType(3,5,13,3);
    createNewCardType(3,5,12,3);
    createNewCardType(3,5,10,3);
    createNewCardType(3,10,8,3);
    createNewCardType(3,80,5,2);
    createNewCardType(3,7,20,4);
    createNewCardType(4,11,10,1);
    createNewCardType(4,10,10,1);
    createNewCardType(4,9,10,1);
    createNewCardType(4,5,12,3);
    createNewCardType(4,5,11,3);
    createNewCardType(4,5,10,3);
    createNewCardType(4,200,3,2);
    hasInitCard1 = true;
  }

    function initCard2() onlyOwner() public {
    require(!hasInitCard2);
    createNewCardType(5,10,10,1);
    createNewCardType(5,8,10,1);
    createNewCardType(5,5,8,1);
    createNewCardType(5,3,10,3);
    createNewCardType(5,5,12,3);
    createNewCardType(5,3,11,3);
    createNewCardType(5,70,4,2);
    createNewCardType(6,10,10,1);
    createNewCardType(6,6,8,1);
    createNewCardType(6,5,8,1);
    createNewCardType(6,4,12,3);
    createNewCardType(6,5,12,3);
    createNewCardType(6,5,12,3);
    createNewCardType(6,80,5,2);
    createNewCardType(7,10,12,1);
    createNewCardType(7,100,4,2);
    createNewCardType(7,100,5,2);
    createNewCardType(7,100,4,2);
    createNewCardType(7,100,4,2);
    createNewCardType(7,100,4,2);
    createNewCardType(8,10,10,1);
    createNewCardType(8,9,10,1);
    createNewCardType(8,5,6,1);
    createNewCardType(8,4,12,3);
    createNewCardType(8,5,12,3);
    createNewCardType(8,4,12,3);
    createNewCardType(8,4,20,4);
    createNewCardType(9,10,10,1);
    createNewCardType(9,7,10,1);
    createNewCardType(9,1,20,1);
    createNewCardType(9,5,13,3);
    createNewCardType(9,5,13,3);
    createNewCardType(9,80,5,2);
    createNewCardType(9,90,5,2);
    createNewCardType(10,9,10,1);
    createNewCardType(10,10,10,1);
    createNewCardType(10,4,12,1);
    createNewCardType(10,80,5,2);
    createNewCardType(10,5,12,3);
    createNewCardType(10,5,12,3);
    hasInitCard2 = true;
  }

   
   
  function withdrawAll () onlyAdmins() public {
   msg.sender.transfer(address(this).balance);
  }

  function withdrawAmount (uint256 _amount) onlyAdmins() public {
    msg.sender.transfer(_amount);
  }

   

  function name() public pure returns (string) {
    return "Ethwuxia.pro";
  }

  function symbol() public pure returns (string) {
    return "EWX";
  }

  function totalSupply() public view returns (uint256) {
    return listedCard.length;
  }

  function balanceOf (address _owner) public view returns (uint256 _balance) {
    uint counter = 0;

    for (uint i = 0; i < listedCard.length; i++) {
      if (ownerOf(listedCard[i].cardId) == _owner) {
        counter++;
      }
    }

    return counter;
  }

  function ownerOf (uint256 _itemId) public view returns (address _owner) {
    return mapOwnerOfCard[_itemId];
  }

  function tokensOf (address _owner) public view returns (uint[]) {
    uint[] memory result = new uint[](balanceOf(_owner));

    uint256 itemCounter = 0;
    for (uint256 i = 0; i < listedCard.length; i++) {
      if (ownerOf(i) == _owner) {
        result[itemCounter] = listedCard[i].cardId;
        itemCounter += 1;
      }
    }
    return result;
  }

  function tokenExists (uint256 _itemId) public view returns (bool _exists) {
    return mapOwnerOfCard[_itemId] != address(0);
  }

  function approvedFor(uint256 _itemId) public view returns (address _approved) {
    return approvedOfItem[_itemId];
  }

  function approve(address _to, uint256 _itemId) public {
    require(msg.sender != _to);
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == msg.sender);

    if (_to == 0) {
      if (approvedOfItem[_itemId] != 0) {
        delete approvedOfItem[_itemId];
        emit Approval(msg.sender, 0, _itemId);
      }
    } else {
      approvedOfItem[_itemId] = _to;
      emit Approval(msg.sender, _to, _itemId);
    }
  }

   
  function transfer(address _to, uint256 _itemId) public {
    require(msg.sender == ownerOf(_itemId));
    _transfer(msg.sender, _to, _itemId);
  }

  function transferFrom(address _from, address _to, uint256 _itemId) public {
    require(approvedFor(_itemId) == msg.sender);
    _transfer(_from, _to, _itemId);
  }

  function _transfer(address _from, address _to, uint256 _itemId) internal {
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == _from);
    require(_to != address(0));
    require(_to != address(this));
    return ;   

    mapOwnerOfCard[_itemId] = _to;
    approvedOfItem[_itemId] = 0;

    emit Transfer(_from, _to, _itemId);
  }

   
  function isAdmin (address _admin) public view returns (bool _isAdmin) {
    return admins[_admin];
  }

   
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }  
    return size > 0;
  }
}

interface IItemRegistry {
  function itemsForSaleLimit (uint256 _from, uint256 _take) external view returns (uint256[] _items);
  function ownerOf (uint256 _itemId) external view returns (address _owner);
  function priceOf (uint256 _itemId) external view returns (uint256 _price);
}