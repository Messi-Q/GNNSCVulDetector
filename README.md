# GNNSCVulDetector ![GitHub stars](https://img.shields.io/github/stars/Messi-Q/GNNSCVulDetector.svg?style=plastic) ![GitHub forks](https://img.shields.io/github/forks/Messi-Q/GNNSCVulDetector.svg?color=blue&style=plastic) 

This repo is a python implementation of smart contract vulnerability detection using graph neural networks (TMP).


## Citation
Please use this citation in your paper if you refer to our [paper](https://www.ijcai.org/Proceedings/2020/0454.pdf) or code.
```
@inproceedings{zhuang2020smart,
  title={Smart Contract Vulnerability Detection using Graph Neural Network.},
  author={Zhuang, Yuan and Liu, Zhenguang and Qian, Peng and Liu, Qi and Wang, Xiang and He, Qinming},
  booktitle={IJCAI},
  pages={3283--3290},
  year={2020}
}
``` 


## Requirements

#### Required Packages
* **python** 3+
* **TensorFlow** 1.14.0 (tf2.0 is not supported)
* **keras** 2.2.4 with TensorFlow backend
* **sklearn** 0.20.2
* **docopt** as a command-line interface parser 

Run the following script to install the required packages.
```shell
pip install --upgrade pip
pip install tensorflow==1.14.0
pip install keras==2.2.4
pip install scikit-learn==0.20.2
pip install docopt
```

### Dataset
For each dataset, we randomly pick 80% contracts as the training set while the remainings are utilized for the testing set. 
In the comparison, metrics accuracy, recall, precision, and F1 score are all involved. In consideration of the distinct features of different platforms, 
experiments for reentrancy and timestamp dependence vulnerability are conducted on ESC (Ethereum smart contract) dataset, while infinite loop vulnerability is evaluated on VSC (Vntchain smart contract) dataset.

Here, we provide a [tool](https://github.com/Messi-Q/Crawler) for crawling the smart contract source code from Etherscan, which is developed in Aug 2018. 
If out of date, you can make the corresponding improvements.

For original dataset, please turn to the dataset [repo](https://github.com/Messi-Q/Smart-Contract-Dataset).


#### Dataset structure in this project
All of the smart contract source code, graph data, and training data in these folders in the following structure respectively.
```shell
${GNNSCVulDetector}
├── data
│   ├── timestamp
│   │   └── source_code
│   │   └── graph_data
│   └── reentrancy
│       └── source_code
│       └── graph_data
├── train_data
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
The tools for extracting graph features (vectors) are as follows:
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
python3 AutoExtractGraph.py
```

`graph2vec.py`
* Feature ablation.
* Convert contract graph into vectors.
```shell
python3 graph2vec.py
```


## Running project
* To run the program, please use this command: python3 GNNSCModel.py.

Examples:
```shell
python3 GNNSCModel.py --random_seed 9930 --thresholds 0.45
```

### Note
We would like to point that the data processing code is available here. 
If any question, please email to messi.qp711@gmail.com. And, the code is adapted from [GGNN](https://github.com/Microsoft/gated-graph-neural-network-samples).



### Reference
1. Li Y, Tarlow D, Brockschmidt M, et al. Gated graph sequence neural networks. ICLR, 2016. [GGNN](https://arxiv.org/abs/1511.05493)
2. Qian P, Liu Z, He Q, et al. Towards automated reentrancy detection for smart contracts based on sequential models. 2020. [ReChecker](https://github.com/Messi-Q/ReChecker)



