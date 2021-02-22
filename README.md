# GNNSCVulDetector ![GitHub stars](https://img.shields.io/github/stars/Messi-Q/GNNSCVulDetector.svg?style=plastic) ![GitHub forks](https://img.shields.io/github/forks/Messi-Q/GNNSCVulDetector.svg?color=blue&style=plastic) 

This repo is a python implementation of smart contract vulnerability detection using graph neural networks. 
In this research work, we focus on detecting three types of smart contract vulnerabilities (i.e., reentrancy, timestamp dependence, and infinite loop).


## Citation
Please use this citation if you want to cite our [paper](https://www.ijcai.org/Proceedings/2020/0454.pdf) or codebase in your paper:
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


## Requirements

#### Required Packages
* **python**3
* **TensorFlow**1.14.0 (tf2.0 is not supported)
* **keras**2.2.4 with TensorFlow backend
* **sklearn** for model evaluation
* **docopt** as a command-line interface parser 

Run the following script to install the required packages.
```shell
pip install --upgrade pip
pip install tensorflow==1.14.0
pip install keras==2.2.4
pip install scikit-learn
pip install docopt
```

### Dataset
For each dataset, we randomly pick 80% contracts as the training set while the remainings are utilized for the testing set. 
In the comparison, metrics accuracy, recall, precision, and F1 score are all involved. In consideration of the distinct features of different platforms, 
experiments for reentrancy and timestamp dependence vulnerability are conducted on ESC (Ethereum smart contract) dataset, while infinite loop vulnerability is evaluated on VSC (Vntchain smart contract) dataset.

#### Smart contract source code
[Ethereum smart contract](https://drive.google.com/open?id=1h9aFFSsL7mK4NmVJd4So7IJlFj9u0HRv)

[Vntchain smart contract](https://drive.google.com/open?id=1FTb__ERCOGNGM9dTeHLwAxBLw7X5Td4v)

Here, we provide a [tool](https://github.com/Messi-Q/Crawler) for crawling the smart contract source code from Etherscan, which is developed in Aug 2018. 
If out of date, you can refer and make the corresponding improvements.

#### Dataset structure in this project
All of the smart contract source code, graph data, and training data in these folders in the following structure respectively.
```shell
${GNNSCVulDetector}
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

* `data/reentrancy/source_code`:  This is the source code of smart contracts.
* `data/reentrancy/graph_data`: This is the graph structure of smart contracts, consisting edges and nodes, which are extracted by our AutoExtractGraph.
* `graph_data/edge`: It includes all edges and edge of each smart contract.
* `graph_data/node`: It includes all nodes and node of each smart contract.
* `features/reentrancy`: It includes all the reentrancy features of each smart contract extracted by our model.
* `train_data/reentrancy/train.json`: This is the training data of all the smart contract for reentrancy.
* `train_data/reentrancy/valid.json`: This is the testing data of all the smart contract for reentrancy.


### Code Files
The tools and models are as follows:
```shell
${GNNSCVulDetector}
├── tools
│   ├── remove_comment.py
│   ├── construct_fragment.py
│   ├── reentrancy/AutoExtractGraph.py
│   └── reentrancy/graph2vec.py
```

`AutoExtractGraph.py`
* All functions in the smart contract code are automatically split and stored.
* Find the relationships between functions.
* Extract all smart contracts source code into the corresponding contract graph consisting of nodes and edges.
```shell
python AutoExtractGraph.py
```

`graph2vec.py`
* Feature ablation.
* Convert contract graph into vectors.
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
If any question, please email to messi.qp711@gmail.com. And, the code is adapted from [GGNN](https://github.com/Microsoft/gated-graph-neural-network-samples).
Technical questions can be addressed to messi.qp711@gmail.com, zhuangyuan2020@outlook.com, liuzhenguang2008@gmail.com.



### Reference
1. Li Y, Tarlow D, Brockschmidt M, et al. Gated graph sequence neural networks. ICLR, 2016. [GGNN](https://arxiv.org/abs/1511.05493)
2. Qian P, Liu Z, He Q, et al. Towards automated reentrancy detection for smart contracts based on sequential models. 2020. [ReChecker](https://github.com/Messi-Q/ReChecker)



