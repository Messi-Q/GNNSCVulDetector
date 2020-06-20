#include"vntlib.h"

EVENT PCreated(string document, uint256 timestamp);

KEY   address people;

KEY  mapping (string , uint256) Hash;


constructor a6020()  {
    people = GetSender();
  }
MUTABLE
void NHash(string  document) {
	Require(GetSender() == people,"GetSender() != people");
    uint32 timestamp = GetTimestamp();
    Hash.key =document;
    Hash.value = timestamp;
    PCreated(document, timestamp);
  }

uint256 DProofExist(string  document)  {
	Hash.key =document;
    if (Hash.value!= 0) {
      return Hash.value;
    }
  }
