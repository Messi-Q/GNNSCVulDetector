pragma solidity 0.4.24;

contract Governable {

    event Pause();
    event Unpause();

    address public governor;
    bool public paused = false;

    constructor() public {
        governor = msg.sender;
    }

    function setGovernor(address _gov) public onlyGovernor {
        governor = _gov;
    }

    modifier onlyGovernor {
        require(msg.sender == governor);
        _;
    }

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyGovernor whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyGovernor whenPaused public {
        paused = false;
        emit Unpause();
    }

}

contract CardBase is Governable {


    struct Card {
        uint16 proto;
        uint16 purity;
    }

    function getCard(uint id) public view returns (uint16 proto, uint16 purity) {
        Card memory card = cards[id];
        return (card.proto, card.purity);
    }

    function getShine(uint16 purity) public pure returns (uint8) {
        return uint8(purity / 1000);
    }

    Card[] public cards;
    
}

contract CardProto is CardBase {

    event NewProtoCard(
        uint16 id, uint8 season, uint8 god, 
        Rarity rarity, uint8 mana, uint8 attack, 
        uint8 health, uint8 cardType, uint8 tribe, bool packable
    );

    struct Limit {
        uint64 limit;
        bool exists;
    }

     
    mapping(uint16 => Limit) public limits;

     
    function setLimit(uint16 id, uint64 limit) public onlyGovernor {
        Limit memory l = limits[id];
        require(!l.exists);
        limits[id] = Limit({
            limit: limit,
            exists: true
        });
    }

    function getLimit(uint16 id) public view returns (uint64 limit, bool set) {
        Limit memory l = limits[id];
        return (l.limit, l.exists);
    }

     
     
    mapping(uint8 => bool) public seasonTradable;
    mapping(uint8 => bool) public seasonTradabilityLocked;
    uint8 public currentSeason;

    function makeTradeable(uint8 season) public onlyGovernor {
        seasonTradable[season] = true;
    }

    function makeUntradable(uint8 season) public onlyGovernor {
        require(!seasonTradabilityLocked[season]);
        seasonTradable[season] = false;
    }

    function makePermanantlyTradable(uint8 season) public onlyGovernor {
        require(seasonTradable[season]);
        seasonTradabilityLocked[season] = true;
    }

    function isTradable(uint16 proto) public view returns (bool) {
        return seasonTradable[protos[proto].season];
    }

    function nextSeason() public onlyGovernor {
         
        require(currentSeason <= 255); 

        currentSeason++;
        mythic.length = 0;
        legendary.length = 0;
        epic.length = 0;
        rare.length = 0;
        common.length = 0;
    }

    enum Rarity {
        Common,
        Rare,
        Epic,
        Legendary, 
        Mythic
    }

    uint8 constant SPELL = 1;
    uint8 constant MINION = 2;
    uint8 constant WEAPON = 3;
    uint8 constant HERO = 4;

    struct ProtoCard {
        bool exists;
        uint8 god;
        uint8 season;
        uint8 cardType;
        Rarity rarity;
        uint8 mana;
        uint8 attack;
        uint8 health;
        uint8 tribe;
    }

     
     
     
     
     

    uint16 public protoCount;
    
    mapping(uint16 => ProtoCard) protos;

    uint16[] public mythic;
    uint16[] public legendary;
    uint16[] public epic;
    uint16[] public rare;
    uint16[] public common;

    function addProtos(
        uint16[] externalIDs, uint8[] gods, Rarity[] rarities, uint8[] manas, uint8[] attacks, uint8[] healths, uint8[] cardTypes, uint8[] tribes, bool[] packable
    ) public onlyGovernor returns(uint16) {

        for (uint i = 0; i < externalIDs.length; i++) {

            ProtoCard memory card = ProtoCard({
                exists: true,
                god: gods[i],
                season: currentSeason,
                cardType: cardTypes[i],
                rarity: rarities[i],
                mana: manas[i],
                attack: attacks[i],
                health: healths[i],
                tribe: tribes[i]
            });

            _addProto(externalIDs[i], card, packable[i]);
        }
        
    }

    function addProto(
        uint16 externalID, uint8 god, Rarity rarity, uint8 mana, uint8 attack, uint8 health, uint8 cardType, uint8 tribe, bool packable
    ) public onlyGovernor returns(uint16) {
        ProtoCard memory card = ProtoCard({
            exists: true,
            god: god,
            season: currentSeason,
            cardType: cardType,
            rarity: rarity,
            mana: mana,
            attack: attack,
            health: health,
            tribe: tribe
        });

        _addProto(externalID, card, packable);
    }

    function addWeapon(
        uint16 externalID, uint8 god, Rarity rarity, uint8 mana, uint8 attack, uint8 durability, bool packable
    ) public onlyGovernor returns(uint16) {

        ProtoCard memory card = ProtoCard({
            exists: true,
            god: god,
            season: currentSeason,
            cardType: WEAPON,
            rarity: rarity,
            mana: mana,
            attack: attack,
            health: durability,
            tribe: 0
        });

        _addProto(externalID, card, packable);
    }

    function addSpell(uint16 externalID, uint8 god, Rarity rarity, uint8 mana, bool packable) public onlyGovernor returns(uint16) {

        ProtoCard memory card = ProtoCard({
            exists: true,
            god: god,
            season: currentSeason,
            cardType: SPELL,
            rarity: rarity,
            mana: mana,
            attack: 0,
            health: 0,
            tribe: 0
        });

        _addProto(externalID, card, packable);
    }

    function addMinion(
        uint16 externalID, uint8 god, Rarity rarity, uint8 mana, uint8 attack, uint8 health, uint8 tribe, bool packable
    ) public onlyGovernor returns(uint16) {

        ProtoCard memory card = ProtoCard({
            exists: true,
            god: god,
            season: currentSeason,
            cardType: MINION,
            rarity: rarity,
            mana: mana,
            attack: attack,
            health: health,
            tribe: tribe
        });

        _addProto(externalID, card, packable);
    }

    function _addProto(uint16 externalID, ProtoCard memory card, bool packable) internal {

        require(!protos[externalID].exists);

        card.exists = true;

        protos[externalID] = card;

        protoCount++;

        emit NewProtoCard(
            externalID, currentSeason, card.god, 
            card.rarity, card.mana, card.attack, 
            card.health, card.cardType, card.tribe, packable
        );

        if (packable) {
            Rarity rarity = card.rarity;
            if (rarity == Rarity.Common) {
                common.push(externalID);
            } else if (rarity == Rarity.Rare) {
                rare.push(externalID);
            } else if (rarity == Rarity.Epic) {
                epic.push(externalID);
            } else if (rarity == Rarity.Legendary) {
                legendary.push(externalID);
            } else if (rarity == Rarity.Mythic) {
                mythic.push(externalID);
            } else {
                require(false);
            }
        }
    }

    function getProto(uint16 id) public view returns(
        bool exists, uint8 god, uint8 season, uint8 cardType, Rarity rarity, uint8 mana, uint8 attack, uint8 health, uint8 tribe
    ) {
        ProtoCard memory proto = protos[id];
        return (
            proto.exists,
            proto.god,
            proto.season,
            proto.cardType,
            proto.rarity,
            proto.mana,
            proto.attack,
            proto.health,
            proto.tribe
        );
    }

    function getRandomCard(Rarity rarity, uint16 random) public view returns (uint16) {
         
         
        if (rarity == Rarity.Common) {
            return common[random % common.length];
        } else if (rarity == Rarity.Rare) {
            return rare[random % rare.length];
        } else if (rarity == Rarity.Epic) {
            return epic[random % epic.length];
        } else if (rarity == Rarity.Legendary) {
            return legendary[random % legendary.length];
        } else if (rarity == Rarity.Mythic) {
             
            uint16 id;
            uint64 limit;
            bool set;
            for (uint i = 0; i < mythic.length; i++) {
                id = mythic[(random + i) % mythic.length];
                (limit, set) = getLimit(id);
                if (set && limit > 0){
                    return id;
                }
            }
             
            return legendary[random % legendary.length];
        }
        require(false);
        return 0;
    }

     
     
     
    function replaceProto(
        uint16 index, uint8 god, uint8 cardType, uint8 mana, uint8 attack, uint8 health, uint8 tribe
    ) public onlyGovernor {
        ProtoCard memory pc = protos[index];
        require(!seasonTradable[pc.season]);
        protos[index] = ProtoCard({
            exists: true,
            god: god,
            season: pc.season,
            cardType: cardType,
            rarity: pc.rarity,
            mana: mana,
            attack: attack,
            health: health,
            tribe: tribe
        });
    }

}

interface ERC721Metadata   {
     
    function name() external pure returns (string _name);

     
    function symbol() external pure returns (string _symbol);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
}

interface ERC721Enumerable   {
     
     
     
    function totalSupply() public view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable;
    function transfer(address _to, uint256 _tokenId) public payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable;
    function approve(address _to, uint256 _tokenId) public payable;
    function setApprovalForAll(address _to, bool _approved) public;
    function getApproved(uint256 _tokenId) public view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract NFT is ERC721, ERC165, ERC721Metadata, ERC721Enumerable {}

contract CardOwnership is NFT, CardProto {

     
     
     
     
    mapping(uint => address) owners;
    mapping(uint => address) approved;
     
    mapping(address => mapping(address => bool)) operators;

     
    mapping(address => uint40[]) public ownedTokens;

    mapping(uint => string) uris;

     
    uint24[] indices;

    uint public burnCount;

     
    function name() public view returns (string) {
        return "Gods Unchained";
    }

       
    function symbol() public view returns (string) {
        return "GODS";
    }

     
    function totalSupply() public view returns (uint) {
        return cards.length - burnCount;
    }

     
    function transfer(address to, uint id) public payable {
        require(owns(msg.sender, id));
        require(isTradable(cards[id].proto));
        require(to != address(0));
        _transfer(msg.sender, to, id);
    }

     
    function _transfer(address from, address to, uint id) internal {
        approved[id] = address(0);
        owners[id] = to;
        _addToken(to, id);
        _removeToken(from, id);
        emit Transfer(from, to, id);
    }

     
    function _create(address to, uint id) internal {
        owners[id] = to;
        _addToken(to, id);
        emit Transfer(address(0), to, id);
    }

     
    function transferAll(address to, uint[] ids) public payable {
        for (uint i = 0; i < ids.length; i++) {
            transfer(to, ids[i]);
        }
    }

     
    function ownsAll(address proposed, uint[] ids) public view returns (bool) {
        for (uint i = 0; i < ids.length; i++) {
            if (!owns(proposed, ids[i])) {
                return false;
            }
        }
        return true;
    }

     
    function owns(address proposed, uint id) public view returns (bool) {
        return ownerOf(id) == proposed;
    }

     
    function ownerOf(uint id) public view returns (address) {
        return owners[id];
    }

     
    function burn(uint id) public {
         
        require(owns(msg.sender, id));
        burnCount++;
         
         
        _transfer(msg.sender, address(0), id);
    }

     
    function burnAll(uint[] ids) public {
        for (uint i = 0; i < ids.length; i++){
            burn(ids[i]);
        }
    }

     
    function approve(address to, uint id) public payable {
        require(owns(msg.sender, id));
        require(isTradable(cards[id].proto));
        approved[id] = to;
        emit Approval(msg.sender, to, id);
    }

     
    function approveAll(address to, uint[] ids) public payable {
        for (uint i = 0; i < ids.length; i++) {
            approve(to, ids[i]);
        }
    }

     
    function getApproved(uint id) public view returns(address) {
        return approved[id];
    }

     
    function balanceOf(address owner) public view returns (uint) {
        return ownedTokens[owner].length;
    }

     
    function exists(uint id) public view returns (bool) {
        return owners[id] != address(0);
    }

     
    function transferFrom(address from, address to, uint id) public payable {
        
        require(to != address(0));
        require(to != address(this));

         
         
        require(ownerOf(id) == from);

        require(isSenderApprovedFor(id));

        require(isTradable(cards[id].proto));

        _transfer(ownerOf(id), to, id);
    }

     
    function transferAllFrom(address to, uint[] ids) public payable {
        for (uint i = 0; i < ids.length; i++) {
            transferFrom(address(0), to, ids[i]);
        }
    }

     
    function getBurnCount() public view returns (uint) {
        return burnCount;
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operators[owner][operator];
    }

    function setApprovalForAll(address to, bool toApprove) public {
        require(to != msg.sender);
        operators[msg.sender][to] = toApprove;
        emit ApprovalForAll(msg.sender, to, toApprove);
    }

    bytes4 constant magic = bytes4(keccak256("onERC721Received(address,uint256,bytes)"));

    function safeTransferFrom(address from, address to, uint id, bytes data) public payable {
        require(to != address(0));
        transferFrom(from, to, id);
        if (_isContract(to)) {
            bytes4 response = ERC721TokenReceiver(to).onERC721Received.gas(50000)(from, id, data);
            require(response == magic);
        }
    }

    function safeTransferFrom(address from, address to, uint id) public payable {
        safeTransferFrom(from, to, id, "");
    }

    function _addToken(address to, uint id) private {
        uint pos = ownedTokens[to].push(uint40(id)) - 1;
        indices.push(uint24(pos));
    }

    function _removeToken(address from, uint id) public payable {
        uint24 index = indices[id];
        uint lastIndex = ownedTokens[from].length - 1;
        uint40 lastId = ownedTokens[from][lastIndex];

        ownedTokens[from][index] = lastId;
        ownedTokens[from][lastIndex] = 0;
        ownedTokens[from].length--;
    }

    function isSenderApprovedFor(uint256 id) internal view returns (bool) {
        return owns(msg.sender, id) || getApproved(id) == msg.sender || isApprovedForAll(ownerOf(id), msg.sender);
    }

    function _isContract(address test) internal view returns (bool) {
        uint size; 
        assembly {
            size := extcodesize(test)
        }
        return (size > 0);
    }

    function tokenURI(uint id) public view returns (string) {
        return uris[id];
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 _tokenId){
        return ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) external view returns (uint256){
        return index;
    }

    function supportsInterface(bytes4 interfaceID) public view returns (bool) {
        return (
            interfaceID == this.supportsInterface.selector ||  
            interfaceID == 0x5b5e139f ||  
            interfaceID == 0x6466353c ||  
            interfaceID == 0x780e9d63
        );  
    }

    function implementsERC721() external pure returns (bool) {
        return true;
    }

    function getOwnedTokens(address user) public view returns (uint40[]) {
        return ownedTokens[user];
    }
    

}

 
interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
	function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}



contract CardIntegration is CardOwnership {
    
    CardPack[] packs;

    event CardCreated(uint indexed id, uint16 proto, uint16 purity, address owner);

    function addPack(CardPack approved) public onlyGovernor {
        packs.push(approved);
    }

    modifier onlyApprovedPacks {
        require(_isApprovedPack());
        _;
    }

    function _isApprovedPack() private view returns (bool) {
        for (uint i = 0; i < packs.length; i++) {
            if (msg.sender == address(packs[i])) {
                return true;
            }
        }
        return false;
    }

    function createCard(address owner, uint16 proto, uint16 purity) public whenNotPaused onlyApprovedPacks returns (uint) {
        ProtoCard memory card = protos[proto];
        require(card.season == currentSeason);
        if (card.rarity == Rarity.Mythic) {
            uint64 limit;
            bool exists;
            (limit, exists) = getLimit(proto);
            require(!exists || limit > 0);
            limits[proto].limit--;
        }
        return _createCard(owner, proto, purity);
    }

    function _createCard(address owner, uint16 proto, uint16 purity) internal returns (uint) {
        Card memory card = Card({
            proto: proto,
            purity: purity
        });

        uint id = cards.push(card) - 1;

        _create(owner, id);
        
        emit CardCreated(id, proto, purity, owner);

        return id;
    }

     


     
     
     
     
     

    

}

contract CardPack {

    CardIntegration public integration;
    uint public creationBlock;

    constructor(CardIntegration _integration) public payable {
        integration = _integration;
        creationBlock = block.number;
    }

    event Referral(address indexed referrer, uint value, address purchaser);

     
    function purchase(uint16 packCount, address referrer) public payable;

     
    function _getPurity(uint16 randOne, uint16 randTwo) internal pure returns (uint16) {
        if (randOne >= 998) {
            return 3000 + randTwo;
        } else if (randOne >= 988) {
            return 2000 + randTwo;
        } else if (randOne >= 938) {
            return 1000 + randTwo;
        } else {
            return randTwo;
        }
    }

}

contract Ownable {

   address public owner;

   constructor() public {
       owner = msg.sender;
   }

   function setOwner(address _owner) public onlyOwner {
       owner = _owner;
   }

   modifier onlyOwner {
       require(msg.sender == owner);
       _;
   }

}

contract Vault is Ownable {

   function () public payable {

   }

   function getBalance() public view returns (uint) {
       return address(this).balance;
   }

   function withdraw(uint amount) public onlyOwner {
       require(address(this).balance >= amount);
       owner.transfer(amount);
   }

   function withdrawAll() public onlyOwner {
       withdraw(address(this).balance);
   }
}

contract CappedVault is Vault { 

    uint public limit;
    uint withdrawn = 0;

    constructor() public {
        limit = 33333 ether;
    }

    function () public payable {
        require(total() + msg.value <= limit);
    }

    function total() public view returns(uint) {
        return getBalance() + withdrawn;
    }

    function withdraw(uint amount) public onlyOwner {
        require(address(this).balance >= amount);
        owner.transfer(amount);
        withdrawn += amount;
    }

}


contract Pausable is Ownable {
    
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract PresalePack is CardPack, Pausable {

    CappedVault public vault;

    Purchase[] purchases;

    struct Purchase {
        uint16 current;
        uint16 count;
        address user;
        uint randomness;
        uint64 commit;
    }

    event PacksPurchased(uint indexed id, address indexed user, uint16 count);
    event PackOpened(uint indexed id, uint16 startIndex, address indexed user, uint[] cardIDs);
    event RandomnessReceived(uint indexed id, address indexed user, uint16 count, uint randomness);

    constructor(CardIntegration integration, CappedVault _vault) public payable CardPack(integration) {
        vault = _vault;
    }

    function basePrice() public returns (uint);
    function getCardDetails(uint16 packIndex, uint8 cardIndex, uint result) public view returns (uint16 proto, uint16 purity);
    
    function packSize() public view returns (uint8) {
        return 5;
    }

    function packsPerClaim() public view returns (uint16) {
        return 15;
    }

     
    function extract(uint num, uint length, uint start) internal pure returns (uint) {
        return (((1 << (length * 8)) - 1) & (num >> ((start * 8) - 1)));
    }

    uint public purchaseCount;
    uint public totalCount;

    function purchase(uint16 packCount, address referrer) whenNotPaused public payable {

        require(packCount > 0);
        require(referrer != msg.sender);

        uint price = calculatePrice(basePrice(), packCount);

        require(msg.value >= price);

        Purchase memory p = Purchase({
            user: msg.sender,
            count: packCount,
            commit: uint64(block.number),
            randomness: 0,
            current: 0
        });

        uint id = purchases.push(p) - 1;

        emit PacksPurchased(id, msg.sender, packCount);

        if (referrer != address(0)) {
            uint commission = price / 10;
            referrer.transfer(commission);
            price -= commission;
            emit Referral(referrer, commission, msg.sender);
        }
        
        address(vault).transfer(price); 
    }

     
    function callback(uint id) public {

        Purchase storage p = purchases[id];

        require(p.randomness == 0);

        bytes32 bhash = blockhash(p.commit);

        uint random = uint(keccak256(abi.encodePacked(totalCount, bhash)));

        totalCount += p.count;

        if (uint(bhash) == 0) {
             
             
             
            p.randomness = 1;
        } else {
            p.randomness = random;
        }

        emit RandomnessReceived(id, p.user, p.count, p.randomness);
    }

    

    function claim(uint id) public {
        
        Purchase storage p = purchases[id];

        require(canClaim);

        uint16 proto;
        uint16 purity;
        uint16 count = p.count;
        uint result = p.randomness;
        uint8 size = packSize();

        address user = p.user;
        uint16 current = p.current;

        require(result != 0);  
         
        require(count > 0);

        uint[] memory ids = new uint[](size);

        uint16 end = current + packsPerClaim() > count ? count : current + packsPerClaim();

        require(end > current);

        for (uint16 i = current; i < end; i++) {
            for (uint8 j = 0; j < size; j++) {
                (proto, purity) = getCardDetails(i, j, result);
                ids[j] = integration.createCard(user, proto, purity);
            }
            emit PackOpened(id, (i * size), user, ids);
        }
        p.current += (end - current);
    }

    function predictPacks(uint id) external view returns (uint16[] protos, uint16[] purities) {

        Purchase memory p = purchases[id];

        uint16 proto;
        uint16 purity;
        uint16 count = p.count;
        uint result = p.randomness;
        uint8 size = packSize();

        purities = new uint16[](size * count);
        protos = new uint16[](size * count);

        for (uint16 i = 0; i < count; i++) {
            for (uint8 j = 0; j < size; j++) {
                (proto, purity) = getCardDetails(i, j, result);
                purities[(i * size) + j] = purity;
                protos[(i * size) + j] = proto;
            }
        }
        return (protos, purities);
    }

    function calculatePrice(uint base, uint16 packCount) public view returns (uint) {
         
        uint difference = block.number - creationBlock;
        uint numDays = difference / 6000;
        if (20 > numDays) {
            return (base - (((20 - numDays) * base) / 100)) * packCount;
        }
        return base * packCount;
    }

    function _getCommonPlusRarity(uint32 rand) internal pure returns (CardProto.Rarity) {
        if (rand == 999999) {
            return CardProto.Rarity.Mythic;
        } else if (rand >= 998345) {
            return CardProto.Rarity.Legendary;
        } else if (rand >= 986765) {
            return CardProto.Rarity.Epic;
        } else if (rand >= 924890) {
            return CardProto.Rarity.Rare;
        } else {
            return CardProto.Rarity.Common;
        }
    }

    function _getRarePlusRarity(uint32 rand) internal pure returns (CardProto.Rarity) {
        if (rand == 999999) {
            return CardProto.Rarity.Mythic;
        } else if (rand >= 981615) {
            return CardProto.Rarity.Legendary;
        } else if (rand >= 852940) {
            return CardProto.Rarity.Epic;
        } else {
            return CardProto.Rarity.Rare;
        } 
    }

    function _getEpicPlusRarity(uint32 rand) internal pure returns (CardProto.Rarity) {
        if (rand == 999999) {
            return CardProto.Rarity.Mythic;
        } else if (rand >= 981615) {
            return CardProto.Rarity.Legendary;
        } else {
            return CardProto.Rarity.Epic;
        }
    }

    function _getLegendaryPlusRarity(uint32 rand) internal pure returns (CardProto.Rarity) {
        if (rand == 999999) {
            return CardProto.Rarity.Mythic;
        } else {
            return CardProto.Rarity.Legendary;
        } 
    }

    bool public canClaim = true;

    function setCanClaim(bool claim) public onlyOwner {
        canClaim = claim;
    }

    function getComponents(
        uint16 i, uint8 j, uint rand
    ) internal returns (
        uint random, uint32 rarityRandom, uint16 purityOne, uint16 purityTwo, uint16 protoRandom
    ) {
        random = uint(keccak256(abi.encodePacked(i, rand, j)));
        rarityRandom = uint32(extract(random, 4, 10) % 1000000);
        purityOne = uint16(extract(random, 2, 4) % 1000);
        purityTwo = uint16(extract(random, 2, 6) % 1000);
        protoRandom = uint16(extract(random, 2, 8) % (2**16-1));
        return (random, rarityRandom, purityOne, purityTwo, protoRandom);
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

}

contract ERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function allowance(address owner, address spender) public view returns (uint256);
    
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);
    
    function transfer(address to, uint256 value) public returns (bool);
    
  
}

pragma solidity 0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract TournamentPass is ERC20, Ownable {

    using SafeMath for uint256;

    Vault vault;

    constructor(Vault _vault) public {
        vault = _vault;
    }

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    address[] public minters;
    uint256 supply;
    uint mintLimit = 20000;
    
    function name() public view returns (string){
        return "GU Tournament Passes";
    }

    function symbol() public view returns (string) {
        return "PASS";
    }

    function addMinter(address minter) public onlyOwner {
        minters.push(minter);
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function isMinter(address test) internal view returns (bool) {
        for (uint i = 0; i < minters.length; i++) {
            if (minters[i] == test) {
                return true;
            }
        }
        return false;
    }

    function mint(address to, uint amount) public returns (bool) {
        require(isMinter(msg.sender));
        if (amount.add(supply) > mintLimit) {
            return false;
        } 
        supply = supply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    uint public price = 250 finney;

    function purchase(uint amount) public payable {
        
        require(msg.value >= price.mul(amount));
        require(supply.add(amount) <= mintLimit);

        supply = supply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        emit Transfer(address(0), msg.sender, amount);

        address(vault).transfer(msg.value);
    }

}

contract ShinyLegendaryPack is PresalePack {

    TournamentPass pass;

    constructor(CardIntegration integration, CappedVault _vault, TournamentPass _pass) public payable PresalePack(integration, _vault) {
        pass = _pass;
    }

    function purchase(uint16 packCount, address referrer) public payable {
        super.purchase(packCount, referrer);
        pass.mint(msg.sender, packCount);
    }

    function basePrice() public returns (uint) {
        return 4 ether;
    }

    function getCardDetails(uint16 packIndex, uint8 cardIndex, uint result) public view returns (uint16 proto, uint16 purity) {
        uint random;
        uint32 rarityRandom;
        uint16 protoRandom;
        uint16 purityOne;
        uint16 purityTwo;
        CardProto.Rarity rarity;

        (random, rarityRandom, purityOne, purityTwo, protoRandom) = getComponents(packIndex, cardIndex, result);

        if (cardIndex == 4) {
            rarity = _getLegendaryPlusRarity(rarityRandom);
            purity = _getShinyPurity(purityOne, purityTwo);
        } else if (cardIndex == 3) {
            rarity = _getRarePlusRarity(rarityRandom);
            purity = _getPurity(purityOne, purityTwo);
        } else {
            rarity = _getCommonPlusRarity(rarityRandom);
            purity = _getPurity(purityOne, purityTwo);
        }
    
        proto = integration.getRandomCard(rarity, protoRandom);

        return (proto, purity);
    } 

    function _getShinyPurity(uint16 randOne, uint16 randTwo) public pure returns (uint16) {
        if (randOne >= 998) {
            return 3000 + randTwo;
        } else if (randOne >= 748) {
            return 2000 + randTwo;
        } else {
            return 1000 + randTwo;
        }
    }
    
}