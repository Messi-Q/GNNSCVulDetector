#include"vntlib.h"

KEY    uint256 cDate;
    
constructor uastyudy()
    {
        cDate = GetTimestamp();
    }
    
    uint64 two_today()
    {
       return ( U256FromU64(GetTimestamp()) >= days(2));
    }
    
   bool  FiveMinutes() 
    {
        return (U256FromU64(GetTimestamp()) >= cDate + minutes(5 * 1 ));
    }

    bool  TenMinutes() 
    {
        return (U256FromU64(GetTimestamp())>= cDate + minutes(10 * 1 ));
    }

    bool OneHour() 
    {
        return (U256FromU64(GetTimestamp())>= cDate + hours(1 * 1 ));
    }
    
    bool OneDay()
    {
        return (U256FromU64(GetTimestamp()) >= cDate + days(1 * 1 ));
    }

