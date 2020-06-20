#include"vntlib.h"

EVENT ProofCreated(string documentHash, uint256 timestamp);

KEY   address owner;

KEY  mapping (string , uint256) hashesById;


constructor a22297()  {
    owner = GetSender();
  }

void notarizeHash(string  documentHash) {
	Require(GetSender() == owner,"");
    uint32 timestamp = GetTimestamp();
    hashesById.key =documentHash;
    hashesById.value = timestamp;
    ProofCreated(documentHash, timestamp);
  }

uint256 doesProofExist(string  documentHash)  {
	hashesById.key =documentHash;
    if (hashesById.value!= 0) {
      return hashesById.value;
    }
  }
