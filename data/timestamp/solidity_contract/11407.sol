pragma solidity ^0.4.16;

 
library UTF8 {
    function getStringLength(string str) internal pure returns(int256 length) {
        uint256 i = 0;
        bytes memory str_rep = bytes(str);
        while(i < str_rep.length) {
            if (str_rep[i] >> 7 == 0)         i += 1;
            else if (str_rep[i] >> 5 == 0x6)  i += 2;
            else if (str_rep[i] >> 4 == 0xE)  i += 3;
            else if (str_rep[i] >> 3 == 0x1E) i += 4;
            else                              i += 1;
            length++;
        }
    }
}


 
library Math {
    function divide(int256 numerator, int256 denominator, uint256 precision) internal pure returns(int256) {
        int256 _numerator = numerator * int256(10 ** (precision + 1));
        int256 _quotient  = ((_numerator / denominator) + 5) / 10;
        return _quotient;
    }

    function rand(uint256 nonce, int256 min, int256 max) internal view returns(int256) {
        return int256(uint256(keccak256(nonce + block.number + block.timestamp)) % uint256((max - min))) + min;
    }

    function rand16(uint256 nonce, uint16 min, uint16 max) internal view returns(uint16) {
        return uint16(uint256(keccak256(nonce + block.number + block.timestamp)) % uint256(max - min)) + min;
    }

    function rand8(uint256 nonce, uint8 min, uint8 max) internal view returns(uint8) {
        return uint8(uint256(keccak256(nonce + block.number + block.timestamp)) % uint256(max - min)) + min;
    }

    function percent(uint256 value, uint256 per) internal pure returns(uint256) {
        return uint256((divide(int256(value), 100, 4) * int256(per)) / 10000);
    }
}


 
contract Ownable {
    address public owner;
    
    modifier onlyOwner()  { require(msg.sender == owner); _; }

    function Ownable() public { owner = msg.sender; }

    function updateContractOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}


 
contract Priced is Ownable {
    uint256 private price       = 500000000000000000;   
    uint16  private zMax        = 1600;                 
    uint256 private zPrice      = 25000000000000000;    
    uint8   private commission  = 10;                   

    function setPriceData(uint256 _price, uint16 _zMax, uint256 _zPrice, uint8 _commission) external onlyOwner {
        price       = _price;
        zMax        = _zMax;
        zPrice      = _zPrice;
        commission  = _commission;
    }

    function getCreatePrice(uint16 z, uint256 zCount) internal view returns(uint256) {
        return ((price * uint256(Math.divide(int256(z), int256(zMax), 4))) / 10000) + (zPrice * zCount);
    }

    function getCommission(uint256 starPrice) internal view returns(uint256) {
        return Math.percent(starPrice, commission);
    }
}


 
contract Control is Ownable {
     
    function withdrawBalance(address recipient, uint256 value) external onlyOwner {
        require(value > 0);
        require(value < address(this).balance);
        recipient.transfer(value);
    }
}


 
contract Storage {
    struct Star {
        address owner;    
        uint8   gid;      
        uint8   zIndex;   
        uint16  box;      
        uint8   inbox;    
        uint8   stype;    
        uint8   color;    
        uint256 price;    
        uint256 sell;     
        bool    deleted;  
        string  name;     
        string  message;  
    }

     
    Star[] internal stars;

     
    mapping(uint8 => mapping(uint8 => uint16)) internal zCount;    

     
    mapping(uint8 => mapping(uint8 => mapping(uint16 => uint256))) private positions;    


     
    function addStar(address owner, uint8 gid, uint8 zIndex, uint16 box, uint8 inbox, uint8 stype, uint8 color, uint256 price) internal returns(uint256) {
        Star memory _star = Star({
            owner: owner,
            gid: gid, zIndex: zIndex, box: box, inbox: inbox,
            stype: stype, color: color,
            price: price, sell: 0, deleted: false, name: "", message: ""
        });
        uint256 starId = stars.push(_star) - 1;
        placeStar(gid, zIndex, box, starId);
        return starId;
    }

    function placeStar(uint8 gid, uint8 zIndex, uint16 box, uint256 starId) private {
        zCount[gid][zIndex]         = zCount[gid][zIndex] + 1;
        positions[gid][zIndex][box] = starId;
    }

    function setStarNameMessage(uint256 starId, string name, string message) internal {
        stars[starId].name    = name;
        stars[starId].message = message;
    }

    function setStarNewOwner(uint256 starId, address newOwner) internal {
        stars[starId].owner = newOwner;
    }

    function setStarSellPrice(uint256 starId, uint256 sellPrice) internal {
        stars[starId].sell = sellPrice;
    }

    function setStarDeleted(uint256 starId) internal {
        stars[starId].deleted = true;
        setStarSellPrice(starId, 0);
        setStarNameMessage(starId, "", "");
        setStarNewOwner(starId, address(0));

        Star storage _star = stars[starId];
        zCount[_star.gid][_star.zIndex]               = zCount[_star.gid][_star.zIndex] - 1;
        positions[_star.gid][_star.zIndex][_star.box] = 0;
    }


     
    function getStar(uint256 starId) external view returns(address owner, uint8 gid, uint8 zIndex, uint16 box, uint8 inbox,
                                                           uint8 stype, uint8 color,
                                                           uint256 price, uint256 sell, bool deleted,
                                                           string name, string message) {
        Star storage _star = stars[starId];
        owner      = _star.owner;
        gid        = _star.gid;
        zIndex     = _star.zIndex;
        box        = _star.box;
        inbox      = _star.inbox;
        stype      = _star.stype;
        color      = _star.color;
        price      = _star.price;
        sell       = _star.sell;
        deleted    = _star.deleted;
        name       = _star.name;
        message    = _star.message;
    }

    function getStarIdAtPosition(uint8 gid, uint8 zIndex, uint16 box) internal view returns(uint256) {
        return positions[gid][zIndex][box];
    }

    function starExists(uint256 starId) internal view returns(bool) {
        return starId > 0 && starId < stars.length && stars[starId].deleted == false;
    }

    function isStarOwner(uint256 starId, address owner) internal view returns(bool) {
        return stars[starId].owner == owner;
    }
}


 
contract Validation is Priced, Storage {
    uint8   private gidMax     = 5;
    uint16  private zMin       = 100;
    uint16  private zMax       = 1600;
    uint8   private lName      = 25;
    uint8   private lMessage   = 140;
    uint8   private maxCT      = 255;  
    uint256 private nonce      = 1;
    uint8   private maxIRandom = 4;
    uint16  private boxSize    = 20;   
    uint8   private inboxXY    = 100;

     
    mapping(uint8 => uint16) private boxes;


     
    function setValidationData(uint16 _zMin, uint16 _zMax, uint8 _lName, uint8 _lMessage, uint8 _maxCT, uint8 _maxIR, uint16 _boxSize) external onlyOwner {
        zMin       = _zMin;
        zMax       = _zMax;
        lName      = _lName;
        lMessage   = _lMessage;
        maxCT      = _maxCT;
        maxIRandom = _maxIR;
        boxSize    = _boxSize;
        inboxXY    = uint8((boxSize * boxSize) / 4);
    }

    function setGidMax(uint8 _gidMax) external onlyOwner {
        gidMax = _gidMax;
    }


     
    function setBoxCount(uint16 z, uint16 count) external onlyOwner {
        require(isValidZ(z));
        boxes[getZIndex(z)] = count;
    }

    function getBoxCount(uint16 z) external view returns(uint16 count) {
        require(isValidZ(z));
        return boxes[getZIndex(z)];
    }

    function getBoxCountZIndex(uint8 zIndex) private view returns(uint16 count) {
        return boxes[zIndex];
    }


     
    function getZIndex(uint16 z) internal view returns(uint8 zIndex) {
        return uint8(z / boxSize);
    }

    function getZCount(uint8 gid, uint8 zIndex) public view returns(uint16 count) {
        return zCount[gid][zIndex];
    }

    
     
    function isValidGid(uint8 gid) internal view returns(bool) {
        return gid > 0 && gid <= gidMax;
    }

    function isValidZ(uint16 z) internal view returns(bool) {
        return z >= zMin && z <= zMax;
    }

    function isValidBox(uint8 gid, uint8 zIndex, uint16 box) internal view returns(bool) {
        return getStarIdAtPosition(gid, zIndex, box) == 0;
    }


     
    function isValidNameLength(string name) internal view returns(bool) {
        return UTF8.getStringLength(name) <= lName;
    }

    function isValidMessageLength(string message) internal view returns(bool) {
        return UTF8.getStringLength(message) <= lMessage;
    }


     
    function isValidMsgValue(uint256 price) internal returns(bool) {
        if (msg.value < price) return false;
        if (msg.value > price)
            msg.sender.transfer(msg.value - price);
        return true;
    }


     
    function getRandom16(uint16 min, uint16 max) private returns(uint16) {
        nonce++;
        return Math.rand16(nonce, min, max);
    }

    function getRandom8(uint8 min, uint8 max) private returns(uint8) {
        nonce++;
        return Math.rand8(nonce, min, max);
    }

    function getRandomColorType() internal returns(uint8) {
        return getRandom8(0, maxCT);
    }


     
    function getRandomPosition(uint8 gid, uint8 zIndex) internal returns(uint16 box, uint8 inbox) {
        uint16 boxCount = getBoxCountZIndex(zIndex);
        uint16 randBox  = 0;
        if (boxCount == 0) revert();

        uint8 ii   = maxIRandom;
        bool valid = false;
        while (!valid && ii > 0) {
            randBox = getRandom16(0, boxCount);
            valid   = isValidBox(gid, zIndex, randBox);
            ii--;
        }

        if (!valid) revert();
        return(randBox, getRandom8(0, inboxXY));
    }
}


 
contract Stars is Control, Validation {
     
    event StarCreated(uint256 starId);
    event StarUpdated(uint256 starId, uint8 reason);
    event StarDeleted(uint256 starId, address owner);
    event StarSold   (uint256 starId, address seller, address buyer, uint256 price);
    event StarGifted (uint256 starId, address sender, address recipient);


     
    function Stars() public {
         
        uint256 starId = addStar(address(0), 0, 0, 0, 0, 0, 0, 0);
        setStarNameMessage(starId, "Universe", "Big Bang!");
    }


     
    function createStar(uint8 gid, uint16 z, string name, string message) external payable {
         
        require(isValidGid(gid));
        require(isValidZ(z));
        require(isValidNameLength(name));
        require(isValidMessageLength(message));

         
        uint8   zIndex    = getZIndex(z);
        uint256 starPrice = getCreatePrice(z, getZCount(gid, zIndex));
        require(isValidMsgValue(starPrice));

         
        uint256 starId = newStar(gid, zIndex, starPrice);
        setStarNameMessage(starId, name, message);

         
        emit StarCreated(starId);
    }

    function newStar(uint8 gid, uint8 zIndex, uint256 price) private returns(uint256 starId) {
        uint16 box; uint8 inbox;
        uint8   stype  = getRandomColorType();
        uint8   color  = getRandomColorType();
        (box, inbox)   = getRandomPosition(gid, zIndex);
        starId         = addStar(msg.sender, gid, zIndex, box, inbox, stype, color, price);
    }


     
    function updateStar(uint256 starId, string name, string message) external payable {
         
        require(starExists(starId));
        require(isStarOwner(starId, msg.sender));

         
        require(isValidNameLength(name));
        require(isValidMessageLength(message));        

         
        uint256 commission = getCommission(stars[starId].price);
        require(isValidMsgValue(commission));

         
        setStarNameMessage(starId, name, message);
        emit StarUpdated(starId, 1);
    }    


     
    function deleteStar(uint256 starId) external payable {
         
        require(starExists(starId));
        require(isStarOwner(starId, msg.sender));

         
        uint256 commission = getCommission(stars[starId].price);
        require(isValidMsgValue(commission));

         
        setStarDeleted(starId);
        emit StarDeleted(starId, msg.sender);
    }    


     
    function sellStar(uint256 starId, uint256 sellPrice) external {
         
        require(starExists(starId));
        require(isStarOwner(starId, msg.sender));
        require(sellPrice < 10**28);

         
        setStarSellPrice(starId, sellPrice);
        emit StarUpdated(starId, 2);
    }    


     
    function giftStar(uint256 starId, address recipient) external payable {
         
        require(starExists(starId));
        require(recipient != address(0));
        require(isStarOwner(starId, msg.sender));
        require(!isStarOwner(starId, recipient));

         
        uint256 commission = getCommission(stars[starId].price);
        require(isValidMsgValue(commission));

         
        setStarNewOwner(starId, recipient);
        setStarSellPrice(starId, 0);
        emit StarGifted(starId, msg.sender, recipient);
        emit StarUpdated(starId, 3);
    }    


     
    function buyStar(uint256 starId, string name, string message) external payable {
         
        require(starExists(starId));
        require(!isStarOwner(starId, msg.sender));
        require(stars[starId].sell > 0);

         
        uint256 commission = getCommission(stars[starId].price);
        uint256 starPrice  = stars[starId].sell;
        uint256 totalPrice = starPrice + commission;
        require(isValidMsgValue(totalPrice));

         
        address seller = stars[starId].owner;
        seller.transfer(starPrice);

         
        setStarNewOwner(starId, msg.sender);
        setStarSellPrice(starId, 0);
        setStarNameMessage(starId, name, message);
        emit StarSold(starId, seller, msg.sender, starPrice);
        emit StarUpdated(starId, 4);
    }        
}