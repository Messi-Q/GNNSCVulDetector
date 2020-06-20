#include "vntlib.h"

typedef struct dice
{
    uint256 balance;     // 存款
    string nickName;     // 昵称
    bool freeAddress;    // 是否已经领取过赠送的筹码
    uint64 winCount;     // 赢的局数
    uint64 loseCount;    // 输的局数
    uint64 chickenCount; // 猜中50的局数
    uint256 winReward;   // 赢的收益
    uint256 loseAmount;  // 输的总额
} Account;

// 账号余额
KEY mapping(address, Account) accounts;

// 总局数
KEY uint64 totalGameCount;

// 存款总额
KEY uint256 deposit;

// 10%(奖金比例)
KEY uint256 fee = U256(10);

KEY address owner;

KEY uint256 freeAmount = U256(100000000000000000000); // 100*10**18;

// 事件的参数可以被indexed进行修饰，被修饰的参数会被索引, bigger的值: -1:<50, 0:=50, 1:>50
EVENT EVENT_BET(indexed address from, string nickname, uint256 amount,
                int32 bigger, uint64 lottery, uint256 reward);  // 赌
EVENT EVENT_WITHDRAW(indexed address from, string nickname, uint256 amount);  // 撤出
EVENT EVENT_DEPOSIT(indexed address from, string nickname, uint256 amount);  // 存入
EVENT EVENT_NICKNAME(indexed address from, string nickName);  // 昵称
EVENT EVENT_GETFREEVNT(indexed address from, bool got);  // 获取免费的VNT

constructor $Dice(){       // Payable函数可以接收来自交易中的原生代币，使用符号$表示
    owner = GetSender();   // owner即交易发起者的地址
    totalGameCount = 0;    // 游戏总局数
}

// getFee
uint256 getReward(uint256 amount){
    PrintUint256T("get amount in getreward:", amount);
    PrintUint256T("get fee1:", fee);
    uint256 res = U256SafeDiv(amount, fee);
    PrintUint256T("get fee2:", res);
    uint256 reward = U256SafeSub(amount, res);
    PrintUint256T("get reward:", reward);
    return reward;
}

// 是否有足够的赌注
void checkAmount(uint256 amount)
{
    Require(U256_Cmp(amount, U256(0) == 1), "amount must > 0");
    address from = GetSender();
    accounts.key = from;
    uint256 balance = accounts.value.balance;
    PrintAddress("get sender:", from);
    PrintUint256T("get balance:", balance);
    Require(U256_Cmp(U256SafeSub(balance, amount), 0) != -1,
            "No enough money to bet");  // U256SafeSub(balance, amount)表示余额减去amount
}

// 奖池是否足够
void checkPool(uint256 amount)
{
    uint256 contractBalance = GetBalanceFromAddress(GetContractAddress());
    PrintAddress("get contract address:", GetContractAddress());
    PrintUint256T("get contract balance:", contractBalance);
    PrintUint256T("get deposit balance:", deposit);
    uint256 reward = getReward(amount);  // 获得的奖金数
    Require(
        U256_Cmp(U256SafeSub(contractBalance, U256SafeAdd(deposit, U256SafeMul(reward, U256(10)))),0) != -1,
        "No enough money in prize pool");
}

// 校验交易的发起人
void checkOwner()
{
    address sender = GetSender();
    Require(Equal(sender, owner) == true, "Only the owner can operate");
}

uint64 random()
{
    uint64 time = GetTimestamp();
    PrintUint64T("get time", time);
    string time_sha3 = SHA3(SHA3(SHA3(FromU64(time))));
    PrintStr("get time sha3", time_sha3);
    uint64 index = time % 63 + 2;
    PrintUint64T("get index", index);
    uint64 gas = GetGas() % 64 + 2;
    PrintUint64T("get gas", gas);
    uint64 random_a = (uint64)time_sha3[index];
    PrintUint64T("get random_a", random_a);
    uint64 random_b = (uint64)time_sha3[index + 1];
    PrintUint64T("get random_b", random_b);
    uint64 random_c = random_a * random_b * gas % 101;
    PrintUint64T("get result", random_c);
    return random_c;
}

UNMUTABLE  // UNMUTABLE不会修改状态变量
uint64 testRandom() { return random(); }

// bigger的值: -1:<50, 0:=50, 1:>50
MUTABLE
void Bet(uint256 amount, int32 bigger)
{
    PrintUint256T("get amount:", amount);
    checkAmount(amount);
    checkPool(amount);
    address sender = GetSender();
    uint64 res = random();
    totalGameCount += 1;
    if (res > 50 && bigger == 1)
    {
        // you win
        accounts.key = sender;
        uint256 reward = getReward(amount);
        accounts.value.balance = U256SafeAdd(accounts.value.balance, reward);
        accounts.value.winReward = U256SafeAdd(accounts.value.winReward, reward);  // 赢的收益
        deposit = U256SafeAdd(deposit, reward);
        accounts.value.winCount += 1;
        EVENT_BET(sender, accounts.value.nickName, amount, bigger, res, reward);  // res 随机数
    }
    else if (res < 50 && bigger == -1)
    {
        // you win
        accounts.key = sender;
        uint256 reward = getReward(amount);
        accounts.value.balance = U256SafeAdd(accounts.value.balance, reward);
        accounts.value.winReward = U256SafeAdd(accounts.value.winReward, reward);
        deposit = U256SafeAdd(deposit, reward);
        accounts.value.winCount += 1;
        EVENT_BET(sender, accounts.value.nickName, amount, bigger, res, reward);
    }
    else if (res == 50 && bigger == 0)
    {
        // you are the luckiest man, you bet!
        accounts.key = sender;
        uint256 reward = getReward(amount);
        reward = U256SafeMul(reward, U256(100));
        accounts.value.balance = U256SafeAdd(accounts.value.balance, reward);
        accounts.value.winReward = U256SafeAdd(accounts.value.winReward, reward);
        deposit = U256SafeAdd(deposit, reward);
        accounts.value.chickenCount += 1;
        EVENT_BET(sender, accounts.value.nickName, amount, bigger, res, reward);
    }
    else
    {
        // you lose
        accounts.key = sender;
        accounts.value.balance = U256SafeSub(accounts.value.balance, amount);
        accounts.value.loseAmount = U256SafeAdd(accounts.value.loseAmount, amount);
        deposit = U256SafeSub(deposit, amount);
        accounts.value.loseCount += 1;
        EVENT_BET(sender, accounts.value.nickName, amount, bigger, res, U256(0));  // U256(0) 表示奖励为 0
    }
}

// 提款
MUTABLE
void Withdraw(uint256 amount)
{
    checkAmount(amount);
    address from = GetSender();
    if (TransferFromContract(from, amount) == true)  // TransferFromContract 合约向addr from转账金额 amount
    {
        accounts.key = from;
        accounts.value.balance = U256SafeSub(accounts.value.balance, amount);
        deposit = U256SafeSub(deposit, amount);
        EVENT_WITHDRAW(from, accounts.value.nickName, amount);
    }
}

// 提取全部

MUTABLE
void WithdrawAll()
{
    accounts.key = GetSender();
    uint256 amount = accounts.value.balance;
    Withdraw(amount);
}

// 提取奖池, only owner
MUTABLE
void WithdrawPool(uint256 amount)
{
    checkOwner();  // 校验交易的发起人
    checkPool(amount);  // 校验奖池是否足够
    TransferFromContract(GetSender(), amount);
}

//提取奖池
MUTABLE
void WithdrawPoolAll()
{
    uint256 amount = GetBalanceFromAddress(GetContractAddress());
    WithdrawPool(amount);
}

//扩充奖池
MUTABLE
void $DepositPool() {}

//存款
MUTABLE
void $Deposit()
{
    uint256 amount = GetValue();
    address from = GetSender();
    accounts.key = from;
    accounts.value.balance = U256SafeAdd(accounts.value.balance, amount);
    deposit = U256SafeAdd(deposit, amount);
    EVENT_DEPOSIT(from, accounts.value.balance, amount);
}

//免费筹获取100VNT的筹码,每个账号可以获取一次
MUTABLE
void GetFreeChips()
{
    address from = GetSender();
    accounts.key = from;
    bool flag = accounts.value.freeAddress;
    Require(flag == false, "you have got before");
    accounts.value.balance = U256SafeAdd(accounts.value.balance, freeAmount);
    deposit = U256SafeAdd(deposit, freeAmount);
    accounts.value.freeAddress = true;
    EVENT_GETFREEVNT(from, true);
}

// 设置昵称
MUTABLE
void SetNickName(string name)
{
    address from = GetSender();
    accounts.key = from;
    accounts.value.nickName = name;
    EVENT_NICKNAME(from, name);
}

// 根据合约地址获取昵称
UNMUTABLE
string GetNickNameFromAddress(address addr)
{
    accounts.key = addr;
    return accounts.value.nickName;
}

// 获取昵称
UNMUTABLE
string GetNickName() { return GetNickNameFromAddress(GetSender()); }

// 获取交易发起人
UNMUTABLE
address GetOwner() { return owner; }

// 根据合约地址获取金额
UNMUTABLE
uint256 GetAmountFromAddress(address addr)
{
  accounts.key = addr;
  return accounts.value.balance;
}

// 获取金额
UNMUTABLE
uint256 GetAmount() { return GetAmountFromAddress(GetSender()); }

// 获取赢和输的次数
UNMUTABLE
string GetWinAndLose()
{
    accounts.key = GetSender();
    uint64 win = accounts.value.winCount;
    uint64 lose = accounts.value.loseCount;
    uint64 chicken = accounts.value.chickenCount;
    return Concat(
        Concat(Concat(Concat(FromU64(win), "-"), FromU64(chicken)), "-"),
        FromU64(lose));
}

// 获取奖池余额
UNMUTABLE
uint256 GetPool()
{
    uint256 amount = GetBalanceFromAddress(GetContractAddress());
    return U256SafeSub(amount, deposit);
}

// 获取游戏的总局数
UNMUTABLE
uint64 GetTotalGameCount() { return totalGameCount; }

$_() { $Deposit(); }
