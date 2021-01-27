import os
import re
import time
import numpy as np

# map user-defined variables to symbolic names(var)

# Boolean condition expression (VAR: )
var_op_bool = ['!', '~', '**', '*', '!=', '<', '>', '<=', '>=', '==', '<<', '>>', '||', '&&']

# Assignment expressions
var_op_assign = ['|=', '=', '^=', '&=', '<<=', '>>=', '+=', '-=', '*=', '/=', '%=', '++', '--']

# function return type ("$_()", "_()": fallback)
function_return_list = ['int8', 'int16', 'int32', 'int64', 'int128', 'int256', 'uint8', 'uint16', 'uint32', 'uint64',
                        'uint128', 'uint256', 'void', 'bool', 'string', 'address', "$_()", "_()"]


# split all functions of contracts
def split_function(filepath):
    function_list = []
    f = open(filepath, 'r', encoding="utf-8")
    lines = f.readlines()
    f.close()
    flag = -1

    for line in lines:
        count = 0
        text = line.rstrip()
        if len(text) > 0 and text != "\n":
            if "uint" in text.split()[0] and text.startswith("uint"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("uint" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "void" in text and text.startswith("void"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("void" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "bool" in text and text.startswith("bool"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("bool" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "string" in text and text.startswith("string"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("string" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "address" in text and text.startswith("address"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("address" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "$_()" in text and text.startswith("$_()"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("$_()" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "_()" in text and text.startswith("_()"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("_()" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue

    return function_list


# Position the call.value to generate the graph
def generate_graph(inputFile):
    allFunctionList = split_function(inputFile)
    functionNameList = []  # Store all functions' name
    fallbackList = []
    node_list = []  # Store all the points
    edge_list = []  # Store all the edge and edge features
    node_feature_list = []  # Store nodes feature
    selfcallflag = 0
    loopforflag = 0
    loopwhileflag = 0
    funflag = 0  # number of function
    varCount = 0  # number of var
    fallbackflag = 0
    # Store all functions' name
    for i in range(len(allFunctionList)):
        tmp = re.compile(".*?(?=\\()")
        funTypeAndName = tmp.match(allFunctionList[i][0]).group()
        if funTypeAndName != "$_" and funTypeAndName != "_":
            result = funTypeAndName.split(" ")
            functionNameList.append(result[1])
        else:
            functionNameList.append(funTypeAndName)
    # label node_list
    for i in range(len(functionNameList)):
        if functionNameList[i] == "_" or functionNameList[i] == "$_":
            fallbackList.append(["FALLBACK", allFunctionList[i]])
    # ======================================================================
    # ----------------------    Handle fallback call  ----------------------
    # ======================================================================
    if len(fallbackList) != 0:
        for i in range(1, len(fallbackList[0][1])):
            text = fallbackList[0][1][i]
            for j in range(len(functionNameList)):
                if functionNameList[j] in text:
                    node_list.append("FALLBACK")
                    node_list.append("FUN" + str(funflag))
                    node_feature_list.append(['FALLBACK', "FUN" + str(funflag), 1, 'FALLCALL'])
                    node_feature_list.append(["FUN" + str(funflag), 'FALLBACK', 2, 'FALLCALL'])
                    edge_list.append(['FALLBACK', "FUN" + str(funflag), 1, 'FW'])
                    edge_list.append(["FUN" + str(funflag), 'FALLBACK', 2, 'FW'])
                    funflag += 1
                    fallbackflag += 1
                    break
                elif fallbackflag == 0 and i + 1 == len(fallbackList[0][1]):
                    node_list.append("FALLBACK")
                    node_list.append("FUN" + str(funflag))
                    node_feature_list.append(['FALLBACK', "NULL", 0, 'NULL'])
                    node_feature_list.append(["FUN" + str(funflag), "NULL", 0, 'NULL'])
                    edge_list.append(['FALLBACK', "FUN" + str(funflag), 0, 'NULL'])
                    edge_list.append(["FUN" + str(funflag), 'FALLBACK', 0, 'NULL'])
                    funflag += 1
                    fallbackflag += 1
                    break
    else:
        node_list.append("FALLBACK")
        node_list.append("FUN" + str(funflag))
        node_feature_list.append(['FALLBACK', "NULL", 0, 'NULL'])
        node_feature_list.append(["FUN" + str(funflag), "NULL", 0, 'NULL'])
        edge_list.append(['FALLBACK', "FUN" + str(funflag), 0, 'NULL'])
        edge_list.append(["FUN" + str(funflag), 'FALLBACK', 0, 'NULL'])
        funflag += 1
    # ======================================================================
    # ----------------------      Handle self call    ----------------------
    # ======================================================================
    for i in range(len(allFunctionList)):
        currentProcessedFunctionName = functionNameList[i]  # current function name
        if selfcallflag != 0:
            break
        for j in range(1, len(allFunctionList[i])):
            text = allFunctionList[i][j]
            text = text.replace(" ", "")
            if currentProcessedFunctionName + "(" in text:
                node_list.append("FUN" + str(funflag))
                node_feature_list.append(["FUN" + str(funflag), "FUN" + str(funflag), 1, 'SELFCALL'])
                edge_list.append(["FUN" + str(funflag), "FUN" + str(funflag), 1, 'FW'])
                selfcallflag += 1
                funflag += 1
                break
    if selfcallflag == 0:
        node_list.append("FUN" + str(funflag))
        node_feature_list.append(["FUN" + str(funflag), "NULL", 0, 'NULL'])
        edge_list.append(["FUN" + str(funflag), "FUN" + str(funflag), 0, 'NULL'])
        funflag += 1
    # ======================================================================
    # ---------------------------   Handle for -----------------------------
    # ======================================================================
    for i in range(len(allFunctionList)):
        if loopforflag != 0:
            break
        for j in range(1, len(allFunctionList[i])):
            text = allFunctionList[i][j]
            text_value = re.findall('[a-zA-Z0-9]+', text)

            if "for" in text_value:
                result = re.findall('[(](.*?)[)]', text)[0].split(";")
                result_value = re.sub("\D", "", result[1])

                if (("<" or "<=") in result[1]) and (("--" or "-=") in result[2]):
                    node_list.append("FUN" + str(funflag))
                    node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPFOR'])
                    edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'FOR'])
                    node_feature_list.append(['VAR' + str(varCount), "FUN" + str(funflag), 2, 'LOOPFOR'])
                    funflag += 1
                    loopforflag += 1
                    varCount += 1
                    break
                elif ((">" or ">=") in result[1]) and (("++" or "+=") in result[2]):
                    node_list.append("FUN" + str(funflag))
                    node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPFOR'])
                    edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'FOR'])
                    node_feature_list.append(['VAR' + str(varCount), "FUN" + str(funflag), 2, 'LOOPFOR'])
                    funflag += 1
                    loopforflag += 1
                    varCount += 1
                    break
                elif (result[0] == "" or " ") and (result[1] == "" or " ") and (result[2] == "" or " "):
                    node_list.append("FUN" + str(funflag))
                    node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPFOR'])
                    edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'FOR'])
                    node_feature_list.append(['VAR' + str(varCount), "FUN" + str(funflag), 2, 'LOOPFOR'])
                    funflag += 1
                    loopforflag += 1
                    varCount += 1
                    break
                # uint8: the max value is 255, uint16: the max value is 65535; the max value is 4294967295
                elif result_value != "":
                    if "uint8" in result[0] and int(result_value) > 255:
                        node_list.append("FUN" + str(funflag))
                        node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPFOR'])
                        edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'FOR'])
                        node_feature_list.append(['VAR' + str(varCount), "FUN" + str(funflag), 2, 'LOOPFOR'])
                        funflag += 1
                        loopforflag += 1
                        varCount += 1
                        break
                    elif "uint16" in result[0] and int(result_value) > 65535:
                        node_list.append("FUN" + str(funflag))
                        node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPFOR'])
                        edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'FOR'])
                        node_feature_list.append(['VAR' + str(varCount), "FUN" + str(funflag), 2, 'LOOPFOR'])
                        funflag += 1
                        loopforflag += 1
                        varCount += 1
                        break
                    elif "uint32" in result[0] and int(result_value) > 4294967295:
                        node_list.append("FUN" + str(funflag))
                        node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPFOR'])
                        edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'FOR'])
                        node_feature_list.append(['VAR' + str(varCount), "FUN" + str(funflag), 2, 'LOOPFOR'])
                        funflag += 1
                        loopforflag += 1
                        varCount += 1
                        break
                else:
                    node_list.append("FUN" + str(funflag))
                    node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'AFOR'])
                    edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'FOR'])
                    node_feature_list.append(['VAR' + str(varCount), "FUN" + str(funflag), 2, 'AFOR'])
                    varCount += 1
                    funflag += 1
                    loopforflag += 1
                    break
    if loopforflag == 0:
        node_list.append("FUN" + str(funflag))
        node_feature_list.append(["FUN" + str(funflag), "NULL", 0, 'AFOR'])
        edge_list.append(["FUN" + str(funflag), "FUN" + str(funflag), 0, 'NULL'])
        node_feature_list.append(['VAR' + str(varCount), "NULL", 0, 'AFOR'])
        varCount += 1
        funflag += 1
    # ======================================================================
    # --------------------------   Handle while  ---------------------------
    # ======================================================================
    for i in range(len(allFunctionList)):
        WhileVaraible = None
        ResultValue = None
        whileflag = 0
        if loopwhileflag != 0:
            break
        for j in range(1, len(allFunctionList[i])):
            text = allFunctionList[i][j]
            text_value = re.findall('[a-zA-Z0-9]+', text)

            if "while" in text_value:
                whileflag += 1
                result = re.findall('[(](.*?)[)]', text)
                WhileVaraible = result[0]
                ResultValue = re.findall('[a-zA-Z0-9]+', WhileVaraible)

                if "True" == WhileVaraible:
                    node_list.append("FUN" + str(funflag))
                    node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPWHILE'])
                    edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'WHILE'])
                    node_feature_list.append(["VAR" + str(varCount), "FUN" + str(funflag), 2, 'LOOPWHILE'])
                    varCount += 1
                    funflag += 1
                    loopwhileflag += 1
                    break
                elif "==" or "!=" in WhileVaraible:
                    node_list.append("FUN" + str(funflag))
                    node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPWHILE'])
                    edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'WHILE'])
                    node_feature_list.append(["VAR" + str(varCount), "FUN" + str(funflag), 2, 'LOOPWHILE'])
                    varCount += 1
                    funflag += 1
                    loopwhileflag += 1
                    break
            elif whileflag != 0:
                if "<" in WhileVaraible or "<=" in WhileVaraible:
                    if (ResultValue[0] + "--" or ResultValue[0] + "-=") in text.replace(" ", ""):
                        node_list.append("FUN" + str(funflag))
                        node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPWHILE'])
                        edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'WHILE'])
                        node_feature_list.append(["VAR" + str(varCount), "FUN" + str(funflag), 2, 'LOOPWHILE'])
                        varCount += 1
                        funflag += 1
                        loopwhileflag += 1
                        break
                    elif (ResultValue[1] + "++" or ResultValue[0] + "+=") in text.replace(" ", ""):
                        node_list.append("FUN" + str(funflag))
                        node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPWHILE'])
                        edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'WHILE'])
                        node_feature_list.append(["VAR" + str(varCount), "FUN" + str(funflag), 2, 'LOOPWHILE'])
                        varCount += 1
                        funflag += 1
                        loopwhileflag += 1
                        break
                elif ">" in WhileVaraible or ">=" in WhileVaraible:
                    if (ResultValue[0] + "++" or ResultValue[0] + "+=") in text.replace(" ", ""):
                        node_list.append("FUN" + str(funflag))
                        node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPWHILE'])
                        edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'WHILE'])
                        node_feature_list.append(["VAR" + str(varCount), "FUN" + str(funflag), 2, 'LOOPWHILE'])
                        varCount += 1
                        funflag += 1
                        loopwhileflag += 1
                        break
                    elif (ResultValue[1] + "--" or ResultValue[0] + "-=") in text.replace(" ", ""):
                        node_list.append("FUN" + str(funflag))
                        node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'LOOPWHILE'])
                        edge_list.append(["FUN" + str(funflag), 'VAR' + str(varCount), 1, 'WHILE'])
                        node_feature_list.append(["VAR" + str(varCount), "FUN" + str(funflag), 2, 'LOOPWHILE'])
                        varCount += 1
                        funflag += 1
                        loopwhileflag += 1
                        break
                else:
                    node_list.append("FUN" + str(funflag))
                    node_feature_list.append(["FUN" + str(funflag), "NULL", 1, 'AWHILE'])
                    edge_list.append(["FUN" + str(funflag), "NULL", 0, 'NULL'])
                    node_feature_list.append(["VAR" + str(varCount), "NULL", 0, 'AWHILE'])
                    varCount += 1
                    funflag += 1
                    loopwhileflag += 1
                    break
    if loopwhileflag == 0:
        node_list.append("FUN" + str(funflag))
        node_feature_list.append(["FUN" + str(funflag), "NULL", 0, 'AWHILE'])
        edge_list.append(["FUN" + str(funflag), "FUN" + str(funflag), 0, 'NULL'])
        node_feature_list.append(['VAR' + str(varCount), "NULL", 0, 'AWHILE'])
        varCount += 1
        funflag += 1

    node_list.append("VAR0")
    node_list.append("VAR1")

    return node_feature_list, edge_list, node_list


def outputResult(file, node_feature_list, edge_list):
    nodeOutPath = "../../data/loops/graph_data/node/" + file
    edgeOutPath = "../../data/loops/graph_data/edge/" + file

    f_node = open(nodeOutPath, 'a', encoding="utf-8")
    for i in range(len(node_feature_list)):
        result = " ".join(np.array(node_feature_list[i]))
        f_node.write(result + '\n')
    f_node.close()

    f_edge = open(edgeOutPath, 'a', encoding="utf-8")
    for i in range(len(edge_list)):
        result = " ".join(np.array(edge_list[i]))
        f_edge.write(result + '\n')
    f_edge.close()


if __name__ == "__main__":
    test_contract = "../../data/loops/source_code/fallback.c"
    node_feature_list, edge_list, node_list = generate_graph(test_contract)
    node_feature_list = sorted(node_feature_list, key=lambda x: (x[0]))
    edge_list = sorted(edge_list, key=lambda x: (x[2], x[3]))
    print("node_feature", node_feature_list)
    print("edge_feature", edge_list)
    print("node_list", node_list)

    # inputFileDir = "../../data/loops/source_code/"
    # dirs = os.listdir(inputFileDir)
    # start_time = time.time()
    # for file in dirs:
    #     inputFilePath = inputFileDir + file
    #     print(inputFilePath)
    #     node_feature_list, edge_list, node_list = generate_graph(inputFilePath)
    #     node_feature_list = sorted(node_feature_list, key=lambda x: (x[0]))
    #     edge_list = sorted(edge_list, key=lambda x: (x[2], x[3]))
    #     print("node_feature", node_feature_list)
    #     print("edge_feature", edge_list)
    #     outputResult(file, node_feature_list, edge_list)
    #
    # end_time = time.time()
    # print(end_time - start_time)
