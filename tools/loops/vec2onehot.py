import numpy as np


def encode_one_hot(labels):
    classes = set(labels)
    classes_dict = {c: np.identity(len(classes))[i, :] for i, c in enumerate(classes)}
    labels_one_hot = np.array(list(map(classes_dict.get, labels)), dtype=np.int32)
    return labels_one_hot


class vec2onehot:
    varOP_sentence = []
    edgeOP_sentence = []
    nodeOP_sentence = []
    nodeAC_sentence = []
    node_sentence = []
    var_sentence = []
    varFun_sentence = []
    sn_sentence = []
    infiniteLoopFlag_sentence = []
    varOP_vectors = {}
    edgeOP_vectors = {}
    nodeOP_vectors = {}
    nodeAC_vectors = {}
    node_vectors = {}
    var_vectors = {}
    varFun_vectors = {}
    sn_vectors = {}
    infiniteLoopFlag_vectors = {}
    # map user-defined variables (internal state) to symbolic names (e.g.,“VAR1”, “VAR2”) in the one-to-one fashion.
    nodelist = ["NULL", 'FALLBACK', 'FUN0', 'FUN1', 'FUN2', 'FUN3', 'VAR0', 'VAR1']
    # Edges (Variable-related, Program-related, Extension edge)
    edgeOPlist = ["NULL", "FW", "WHILE", "FOR"]
    # variable expression
    varOPlist = ["NULL", "BOOL", "ASSIGN"]
    # variable function expression
    varFunlist = ["NULL", "INNFUN", "FOR", "WHILE"]
    # nodes call representation
    nodeOplist = ["NULL", "CALL", "INNCALL", "SELFCALL", "FALLCALL"]
    # map user-defined arguments to symbolic names (e.g., “ARG1”,“ARG2”) in the one-to-one fashion;
    # this notation (SN) is to show the execution order
    snlist = ['0', '1', '2', '3', '4', '5']
    # Access control
    aclist = ['NULL', 'void', 'uint', 'int', 'uint8', 'uint16', 'uint32', 'uint64', 'uint128', 'uint256', 'bool',
              'string', 'address', 'FALLBACK']
    # infinite Loop Flag
    infiniteLoopFlagList = ['NULL', 'AFOR', 'AWHILE', 'LOOPFOR', 'LOOPWHILE', 'SELFCALL', 'FALLCALL']

    def __init__(self):
        for i in range(len(self.nodelist)):
            self.node_sentence.append(i + 1)
        for i in range(len(self.snlist)):
            self.sn_sentence.append(i + 1)
        for i in range(len(self.edgeOPlist)):
            self.edgeOP_sentence.append(i + 1)
        for i in range(len(self.varOPlist)):
            self.varOP_sentence.append(i + 1)
        for i in range(len(self.varFunlist)):
            self.varFun_sentence.append(i + 1)
        for i in range(len(self.aclist)):
            self.nodeAC_sentence.append(i + 1)
        for i in range(len(self.nodeOplist)):
            self.nodeOP_sentence.append(i + 1)
        for i in range(len(self.infiniteLoopFlagList)):
            self.infiniteLoopFlag_sentence.append(i + 1)
        self.node_dict = dict(zip(self.nodelist, self.node_sentence))
        self.sn_dict = dict(zip(self.snlist, self.sn_sentence))
        self.varOP_dict = dict(zip(self.varOPlist, self.varOP_sentence))
        self.varFun_dict = dict(zip(self.varFunlist, self.varFun_sentence))
        self.edgOP_dict = dict(zip(self.edgeOPlist, self.edgeOP_sentence))
        self.nodeAC_dict = dict(zip(self.aclist, self.nodeAC_sentence))
        self.nodeOP_dict = dict(zip(self.nodeOplist, self.nodeOP_sentence))
        self.infiniteLoopFlag_dict = dict(zip(self.infiniteLoopFlagList, self.infiniteLoopFlag_sentence))
        self.sn2vec()
        self.node2vec()
        self.edgeOP2vec()
        self.varOP2vec()
        self.varFun2vec()
        self.nodeOP2vec()
        self.nodeAC2vec()
        self.infiniteLoopFlag2vec()

    def output_vec(self, vectors):
        for node, vec in vectors.items():
            print("{} {}".format(node, ' '.join([str(x) for x in vec])))

    def node2vec(self):
        for word, index in self.node_dict.items():
            node_array = np.zeros(len(self.nodelist), dtype=int)
            self.node_vectors[word] = node_array
            self.node_vectors[word][index - 1] = 1.0

    def node2vecEmbedding(self, node):
        return self.node_vectors[node]

    def sn2vec(self):
        for word, index in self.sn_dict.items():
            node_array = np.zeros(len(self.snlist), dtype=int)
            self.sn_vectors[word] = node_array
            self.sn_vectors[word][index - 1] = 1.0

    def sn2vecEmbedding(self, sn):
        return self.sn_vectors[sn]

    def edgeOP2vec(self):
        for word, index in self.edgOP_dict.items():
            node_array = np.zeros(len(self.edgeOPlist), dtype=int)
            self.edgeOP_vectors[word] = node_array
            self.edgeOP_vectors[word][index - 1] = 1.0

    def edgeOP2vecEmbedding(self, edgeOP):
        return self.edgeOP_vectors[edgeOP]

    def varOP2vec(self):
        for word, index in self.varOP_dict.items():
            node_array = np.zeros(len(self.varOPlist), dtype=int)
            self.varOP_vectors[word] = node_array
            self.varOP_vectors[word][index - 1] = 1.0

    def varOP2vecEmbedding(self, varOP):
        return self.varOP_vectors[varOP]

    def varFun2vec(self):
        for word, index in self.varFun_dict.items():
            node_array = np.zeros(len(self.varFunlist), dtype=int)
            self.varFun_vectors[word] = node_array
            self.varFun_vectors[word][index - 1] = 1.0

    def varFun2vecEmbedding(self, varFun):
        return self.varFun_vectors[varFun]

    def nodeOP2vec(self):
        for word, index in self.nodeOP_dict.items():
            node_array = np.zeros(len(self.nodeOplist), dtype=int)
            self.nodeOP_vectors[word] = node_array
            self.nodeOP_vectors[word][index - 1] = 1.0

    def nodeOP2vecEmbedding(self, verOP):
        return self.nodeOP_vectors[verOP]

    def nodeAC2vec(self):
        for word, index in self.nodeAC_dict.items():
            node_array = np.zeros(len(self.aclist), dtype=int)
            self.nodeAC_vectors[word] = node_array
            self.nodeAC_vectors[word][index - 1] = 1.0

    def nodeAC2vecEmbedding(self, nodeAC):
        return self.nodeAC_vectors[nodeAC]

    def infiniteLoopFlag2vec(self):
        for word, index in self.infiniteLoopFlag_dict.items():
            node_array = np.zeros(len(self.infiniteLoopFlagList), dtype=int)
            self.infiniteLoopFlag_vectors[word] = node_array
            self.infiniteLoopFlag_vectors[word][index - 1] = 1.0

    def infiniteLoopFlag2vecEmbedding(self, infiniteLoopFlag):
        return self.infiniteLoopFlag_vectors[infiniteLoopFlag]
