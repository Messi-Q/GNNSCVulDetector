# GNNSCVulDetector ![GitHub stars](https://img.shields.io/github/stars/Messi-Q/GNNSCVulDetector.svg?style=plastic) ![GitHub forks](https://img.shields.io/github/forks/Messi-Q/GNNSCVulDetector.svg?color=blue&style=plastic) 

This repo is a python implementation of smart contract vulnerability detection using graph neural networks. 
In this research work, we focus on detecting three kinds of smart contract vulnerabilities (i.e., reentrancy, timestamp dependence, and infinite loop).
All of the infinite loop types we concerned are implemented by Class C/C++ of [VNT](https://github.com/vntchain/go-vnt), 
while the smart contracts of reentrancy and timestamp dependence are wirrten by Solidity, i.e., [Ethereum](https://etherscan.io/) smart contract. 

The ESC dataset consists of 40,932 smart contracts from Ethereum. 
Among the functions, around 5,013 functions possess at least one invocation to call.value, making them potentially affected by the reentrancy vulnerability. 
Around 4,833 functions contain the block.timestamp statement, making them susceptible to the timestamp dependence vulnerability.
The VSC dataset contains all the available 4,170 smart contracts collected from the VNT Chain network, which overall contain 13,761 functions. 
VNT Chain is an experimental public blockchain platform proposed by companies and universities from Singapore, China, and Australia.

## Requirements

#### Required Packages
* **python**3
* **TensorFlow**1.14.0
* **keras**2.2.4 with TensorFlow backend
* **sklearn** for model evaluation
* **docopt** as a command-line interface parser 
* **go-vnt** as a vntchain platform support
* **go-ethereum** as a ethereum platform support

Run the following script to install the required packages.
```shell
pip install --upgrade pip
pip install --upgrade tensorflow
pip install keras
pip install scikit-learn
pip install docopt
```

### Required Dataset
For each dataset, we randomly pick 80% contracts as the training set while the remainings are utilized for the testing set. 
In the comparison, metrics accuracy, recall, precision, and F1 score are all involved. In consideration of the distinct features of different platforms, 
experiments on reentrancy vulnerability and timestamp dependence vulnerability are conducted on the ESC dataset, 
while experiments on infinite loop vulnerability detection are conducted on the VSC dataset.

#### source code
Original smart contract source code:

Ethereum smart contracts:  [Etherscan_contract](https://drive.google.com/open?id=1h9aFFSsL7mK4NmVJd4So7IJlFj9u0HRv)

Vntchain smart contacts: [Vntchain_contract](https://drive.google.com/open?id=1FTb__ERCOGNGM9dTeHLwAxBLw7X5Td4v)


#### Dataset structure in this project
All of the smart contract source code, graph data, and training data in these folders in the following structure respectively.
```shell
${GGNNSmartVulDetector}
├── data
│   ├── loops
│   │   └── source_code
│   │   └── graph_data
│   ├── timestamp
│   │   └── source_code
│   │   └── graph_data
│   └── reentrancy
│       └── source_code
│       └── graph_data
├── features
    ├── loops
    ├── timestamp
    └── reentrancy
├── train_data
    ├── loops
    │   └── train.json
    │   └── vaild.json
    ├── timestamp
    │   └── train.json
    │   └── vaild.json
    └── reentrancy
        └── train.json
        └── vaild.json
      

```

* `data/reentrancy/contract`:  This is the data of original smart contracts.
* `data/reentrancy/graph_data`: This is the graph data, consisting edges and nodes, which are extracted by our AutoExtractor.
* `graph_data/edge`: It includes all edges and edge of each smart contract.
* `graph_data/node`: It includes all nodes and node of each smart contract.
* `features/reentrancy`: It includes all the reentrancy features of each smart contract extracted by our model.
* `train_data/reentrancy/train.json`: This is the training data of all the smart contract.
* `train_data/reentrancy/valid.json`: This is the testing data of all the smart contract.


### Code Files
The tools and models are as follows:
```shell
${GGNNSmartVulDetector}
├── tools
│   ├── remove_comment.py
│   ├── construct_fragment.py
│   ├── reentrancy/AutoExtractGraph.py
│   └── reentrancy/graph2vec.py
```

`AutoExtractGraph.py`
* All functions in the smart contract code are automatically split and stored.
* Find the relationships between functions.
* Extract all smart contracts source code into features of nodes and edges.
```shell
python AutoExtractGraph.py
```

`graph2vec.py`
* Feature ablation.
* Converts graph into vectors.
```shell
python graph2vec.py
```


## Running project
* To run the program, use this command: python GNNSCModel.py.

Examples:
```shell
python GNNSCModel.py --random_seed 9930 --thresholds 0.45
```

### Consultation
We would like to point that the data processing code is available here. 
For the complete codebase, please email to messi.qp711@gmail.com. And, the code is adapted from [GGNN](https://github.com/Microsoft/gated-graph-neural-network-samples).
Technical questions can be addressed to zhuangyuan2020@outlook.com, 
liuzhenguang2008@gmail.com, and qi.liu@cs.ox.ac.uk.


## References
```
@inproceedings{ijcai2020-454,
  title     = {Smart Contract Vulnerability Detection using Graph Neural Network},
  author    = {Zhuang, Yuan and Liu, Zhenguang and Qian, Peng and Liu, Qi and Wang, Xiang and He, Qinming},
  booktitle = {Proceedings of the Twenty-Ninth International Joint Conference on
               Artificial Intelligence, {IJCAI-20}},
  publisher = {International Joint Conferences on Artificial Intelligence Organization}, 
  pages     = {3283--3290},
  year      = {2020},
}

```

1. VNT Document. [vnt-document](https://github.com/vntchain/vnt-documentation).
2. Li Y, Tarlow D, Brockschmidt M, et al. Gated graph sequence neural networks. ICLR, 2016. [GGNN](https://arxiv.org/abs/1511.05493)



