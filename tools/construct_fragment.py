InputSmartContract = "./reentrancy/results/Reentrancy_AutoExtract_fullnodes.json"
SmartContractNumber = "./reentrancy/reentrancy_contract_number.txt"
out = "./reentrancy/results/Reentrancy_AutoExtract_fullnodes_all.json"

ContractNumber = open(SmartContractNumber, "r")
ContractNumbers = ContractNumber.readlines()
f = open(InputSmartContract, "r")
lines = f.readlines()
f_w = open(out, "a")

for i in range(len(ContractNumbers)):
    number = ContractNumbers[i].strip()

    for j in range(int(number)):
        f_w.write(lines[i])
        print(j)

