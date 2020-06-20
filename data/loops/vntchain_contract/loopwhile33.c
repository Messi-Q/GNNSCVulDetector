#include "vntlib.h"

KEY uint64 count = 0;
KEY string s1 = "qian";

constructor While3(){}

 MUTABLE
 uint64 test2(bool isDone){
      PrintStr("while", "while");

      while(count < 3) {
         if(isDone) {
             continue;
         }
         count++;
      }
      return count;
 }


MUTABLE
uint64 test1(string s){
    uint64 isDone = Equal(s, s1);
    uint32 res = test2(isDone);
    return res;
}

