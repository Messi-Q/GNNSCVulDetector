import os
import json
import numpy as np
from loops.vec2onehot import vec2onehot

"""
S, W, C features: Node features + Edge features + Var features;
Node self property + Incoming Var + Outgoing Var + Incoming Edge + Outgoing Edge
"""

dict_FRE = {"NULL": 0, "void": 1, "uint": 2, "int": 3, "uint8": 4, "uint16": 5, "uint32": 6, "uint64": 7, "uint128": 8,
            "uint256": 9, "bool": 10, "string": 11, "address": 12, "fallback": 13}

dict_NodeName = {"NULL": 0, "FALLBACK": 1, "FUN0": 2, "FUN1": 3, "FUN2": 4, "FUN3": 5, "VAR0": 6, "VAR1": 7}

dict_VarFunName = {"NULL": 0, "INNFUN": 1, "FOR": 2, "WHILE": 3}

dict_EdgeOpName = {"NULL": 0, "FW": 1, "WHILE": 2, "FOR": 3}

dict_InfiniteLoopFlag = {"NULL": 0, "AFOR": 1, "AWHILE": 2, "LOOPFOR": 3, "LOOPWHILE": 4, "SELFCALL": 5, "FALLCALL": 6}

node_convert = {"FALLBACK": 0, "FUN0": 1, "FUN1": 2, "FUN2": 3, "FUN3": 4, "VAR0": 5, "VAR1": 6}

v2o = vec2onehot()  # create the one-bot dicts


# extract the features of each nodes from input file #
def extract_node_features(nodeFile):
    nodeNum = 0
    node_list = []
    node_attribute_list = []

    f = open(nodeFile, encoding="utf-8")
    lines = f.readlines()
    f.close()

    for line in lines:
        node = list(map(str, line.split()))
        verExist = False
        for i in range(0, len(node_list)):
            if node[0] == node_list[i]:
                verExist = True
            else:
                continue
        if verExist is False:
            node_list.append(node[0])
            nodeNum += 1
        node_attribute_list.append(node)

    return nodeNum, node_list, node_attribute_list


def embedding_node(node_attribute_list):
    # embedding each nodes after elimination #
    node_encode = []
    var_encode = []
    node_embedding = []

    for j in range(0, len(node_attribute_list)):
        vf0 = node_attribute_list[j][0]
        vf1 = dict_NodeName[node_attribute_list[j][0]]
        vfm1 = v2o.node2vecEmbedding(node_attribute_list[j][0])
        vf2 = dict_NodeName[node_attribute_list[j][1]]
        vfm2 = v2o.node2vecEmbedding(node_attribute_list[j][1])
        vf3 = int(node_attribute_list[j][2])
        vfm3 = v2o.sn2vecEmbedding(node_attribute_list[j][2])
        vf4 = dict_InfiniteLoopFlag[node_attribute_list[j][3]]
        vfm4 = v2o.infiniteLoopFlag2vecEmbedding(node_attribute_list[j][3])
        nodeEmbedding = vfm1.tolist() + vfm2.tolist() + vfm3.tolist() + vfm4.tolist() + vfm4.tolist()
        node_embedding.append([vf0, np.array(nodeEmbedding)])
        temp = [vf1, vf2, vf3, vf4]
        node_encode.append([vf0, temp])

    return node_encode, var_encode, node_embedding


def elimination_edge(edgeFile):
    # eliminate edge #
    edge_list = []  # all edge
    extra_edge_list = []  # eliminated edge

    f = open(edgeFile, encoding="utf-8")
    lines = f.readlines()
    f.close()

    for line in lines:
        edge = list(map(str, line.split()))
        edge_list.append(edge)

    # The ablation of multiple edge between two nodes, taking the edge with the edge_operation priority
    for k in range(0, len(edge_list)):
        if k + 1 < len(edge_list):
            start1 = edge_list[k][0]  # start nodes
            end1 = edge_list[k][1]  # end nodes
            op1 = edge_list[k][3]
            start2 = edge_list[k + 1][0]
            end2 = edge_list[k + 1][1]
            op2 = edge_list[k + 1][3]
            if start1 == start2 and end1 == end2:
                op1_index = dict_EdgeOpName[op1]
                op2_index = dict_EdgeOpName[op2]
                # extract edge attribute based on priority
                if op1_index < op2_index:
                    extra_edge_list.append(edge_list.pop(k))
                else:
                    extra_edge_list.append(edge_list.pop(k + 1))

    return edge_list, extra_edge_list


def embedding_edge(edge_list):
    # extract & embedding the features of each edge from input file #
    edge_encode = []
    edge_embedding = []

    for k in range(len(edge_list)):
        start = edge_list[k][0]  # start nodes
        end = edge_list[k][1]  # end nodes
        a, b = edge_list[k][2], edge_list[k][3]  # origin info

        ef1 = int(a)
        ef2 = dict_EdgeOpName[b]

        ef_temp = [ef1, ef2]
        edge_encode.append([start, end, ef_temp])

        efm1 = v2o.sn2vecEmbedding(a)
        efm2 = v2o.edgeOP2vecEmbedding(b)

        efm_temp = efm1.tolist() + efm2.tolist()
        edge_embedding.append([start, end, np.array(efm_temp)])

    return edge_encode, edge_embedding


def construct_vec(node_list, node_embedding, edge_embedding, edge_encode, edge_list):
    # Vec: Node self property + Incoming Var + Outgoing Var + Incoming Edge + Outgoing Edge
    print("Start constructing nodes vector...")
    edge_vec_length = len(edge_embedding[0][2])
    edge_in_node = []
    edge_in = []
    edge_out_node = []
    edge_out = []
    node_vec = []

    main_point = ['VAR0', 'VAR1', 'FUN0', 'FUN1', 'FUN2', 'FUN3', 'FALLBACK']

    for i in range(len(edge_embedding)):
        if edge_list[i][0] in main_point:
            edge_out.append([edge_embedding[i][0], edge_embedding[i][2]])
        elif edge_list[i][0] in main_point:
            edge_out.append([edge_embedding[i][0], edge_embedding[i][2]])
        if edge_list[i][1] in main_point:
            edge_in.append([edge_embedding[i][1], edge_embedding[i][2]])
        elif edge_list[i][1] in main_point:
            edge_in.append([edge_embedding[i][1], edge_embedding[i][2]])

    for i in range(len(edge_in)):
        edge_in_node.append(edge_in[i][0])
    for i in range(len(edge_out)):
        edge_out_node.append(edge_out[i][0])

    for i in range(len(node_list)):
        if node_list[i] not in edge_out_node:
            edge_out.append([node_list[i], np.zeros(edge_vec_length, dtype=int)])
        if node_list[i] not in edge_in_node:
            edge_in.append([node_list[i], np.zeros(edge_vec_length, dtype=int)])

    edgeIn_dict = dict(edge_in)
    edgeOut_dict = dict(edge_out)

    for i in range(len(node_embedding)):
        if node_embedding[i][0] in main_point:
            node_feature = node_embedding[i][1].tolist() + np.array(edgeIn_dict[node_embedding[i][0]]).tolist() + \
                           np.array(edgeOut_dict[node_embedding[i][0]]).tolist()
            node_vec.append([node_embedding[i][0], node_feature])

    for i in range(len(node_embedding)):
        node_embedding[i][1] = node_embedding[i][1].tolist()

    print("Node Vec:")
    for i in range(len(node_vec)):
        node_vec[i][0] = node_convert[node_vec[i][0]]
        print(node_vec[i][0], node_vec[i][1])

    # S0 -> 0, W0 -> 1, C0 -> 2
    print("Edge Vec:")
    for i in range(len(edge_encode)):
        edge_encode[i][0] = node_convert[edge_encode[i][0]]
        edge_encode[i][1] = node_convert[edge_encode[i][1]]
        print(edge_encode[i][0], edge_encode[i][1], edge_encode[i][2])

    graph_edge = []
    for i in range(len(edge_encode)):
        graph_edge.append([edge_encode[i][0], edge_encode[i][2][1], edge_encode[i][1]])

    print(graph_edge)

    return node_vec, graph_edge, node_embedding


if __name__ == "__main__":
    node = "../../data/loops/graph_data/node/fallback.c"
    edge = "../../data/loops/graph_data/edge/fallback.c"
    nodeNum, node_list, node_attribute_list = extract_node_features(node)
    node_encode, var_encode, node_embedding = embedding_node(node_attribute_list)
    edge_list, extra_edge_list = elimination_edge(edge)
    edge_encode, edge_embedding = embedding_edge(edge_list)
    node_vec, graph_edge, node_embedding = construct_vec(node_list, node_embedding, edge_embedding, edge_encode,
                                                         edge_list)

    # v_path = "../../data/loops/graph_data/node/"
    # e_path = "../../data/loops/graph_data/edge/"
    #
    # corenodes_output_tmp = open('./results/Infinite_Loop_AutoExtract_corenodes.json', 'w')
    # fullnodes_ouptput_tmp = open('./results/Infinite_Loop_AutoExtract_fullnodes.json', 'w')
    # corenodes_ouptput_gcn = open('./results/Infinite_Loop_AutoExtract_corenodes.txt', 'a')
    # fullnodes_ouptput_gcn = open('./results/Infinite_Loop_AutoExtract_fullnodes.txt', 'a')
    # contract_name = open("./infinite_loop_contract_name.txt")  # contracts list
    # contract_label = open("./infinite_loop_contract_label.txt")  # contracts label
    # names = contract_name.readline().strip(" ")
    # labels = contract_label.readline()
    #
    # while names:
    #     node = os.path.join(v_path, names.strip('\n'))
    #     edge = os.path.join(e_path, names.strip('\n'))
    #     print(node)
    #
    #     nodeNum, node_list, node_attribute_list = extract_node_features(node)
    #     node_encode, var_encode, node_embedding = embedding_node(node_attribute_list)
    #
    #     edge_list, extra_edge_list = elimination_edge(edge)
    #     edge_encode, edge_embedding = embedding_edge(edge_list)
    #     node_vec, graph_edge, node_embedding = construct_vec(node_list, node_embedding, edge_embedding, edge_encode, edge_list)
    #
    #     fullnodes_ouptput_gcn.write(names)
    #     corenodes_ouptput_gcn.write(names)
    #
    #     for k in range(len(node_embedding)):
    #         fullnodes_ouptput_gcn.write(str(node_embedding[k][0]) + ":" + str(node_embedding[k][1]) + '\n')
    #     for k in range(len(node_vec)):
    #         corenodes_ouptput_gcn.write(str(node_vec[k][0]) + ":" + str(node_vec[k][1]) + '\n')
    #
    #     corenodes_feature_list = []
    #     for i in range(len(node_vec)):
    #         corenodes_feature_list.append(node_vec[i][1])
    #
    #     fullnodes_feature_list = []
    #     for i in range(len(node_embedding)):
    #         fullnodes_feature_list.append(node_embedding[i][1])
    #
    #     edge_dict = {
    #         "graph": graph_edge
    #     }
    #
    #     node_feature_dict = {
    #         "node_features": corenodes_feature_list,
    #     }
    #
    #     graph_dict = ({
    #         "targets": labels.strip('\n'),
    #         "graph": graph_edge,  # graph_edge,
    #         "contract_name": names.strip('\n'),
    #         "node_features": corenodes_feature_list,  # corenodes_feature_list
    #     })
    #
    #     fullnode_graph_dict = ({
    #         "targets": labels.strip('\n'),
    #         "graph": graph_edge,  # graph_edge,
    #         "contract_name": names.strip('\n'),
    #         "node_features": fullnodes_feature_list,  # corenodes_feature_list
    #     })
    #
    #     result = json.dumps(graph_dict)
    #     fullnodes_result = json.dumps(fullnode_graph_dict)
    #
    #     corenodes_output_tmp.write(result + "," + "\n")
    #     fullnodes_ouptput_tmp.write(fullnodes_result + "," + "\n")
    #     names = contract_name.readline()
    #     labels = contract_label.readline()
    #
    # fullnodes_ouptput_gcn.close()
    # corenodes_ouptput_gcn.close()
    # corenodes_output_tmp.close()
    # fullnodes_ouptput_tmp.close()
