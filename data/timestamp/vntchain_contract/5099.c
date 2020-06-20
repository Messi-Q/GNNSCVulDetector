#include"vntlib.h"

EVENT ProofCreated(string document, uint256 timestamp);

KEY   address creator;

KEY  mapping (string , uint256) Hash;


constructor a5099()  {
    creator = GetSender();
  }

void notarizeHash(string  document) {
	Require(GetSender() == creator,"error");
    uint32 timestamp = GetTimestamp();
    Hash.key =document;
    Hash.value = timestamp;
    ProofCreated(document, timestamp);
  }

uint256 doesProofExist(string  document)  {
	Hash.key =document;
    if (Hash.value!= 0) {
      return Hash.value;
    }
  }
