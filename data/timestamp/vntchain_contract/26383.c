#include"vntlib.h"

KEY    uint256 xcbsd;
    
constructor isd23()
    {
        xcbsd = GetTimestamp();
    }
    
    uint64 xoic()
    {
       return ( U256FromU64(GetTimestamp()) >= days(2));
    }
    
   bool  mvbf() 
    {
        return (U256FromU64(GetTimestamp()) >= xcbsd + minutes(5 * 1 ));
    }

    bool  aaa() 
    {
        return (U256FromU64(GetTimestamp())>= xcbsd + minutes(10 * 1 ));
    }

    bool bbb() 
    {
        return (U256FromU64(GetTimestamp())>= xcbsd + hours(1 * 1 ));
    }
    
    bool ccc()
    {
        return (U256FromU64(GetTimestamp()) >= xcbsd + days(1 * 1 ));
    }

