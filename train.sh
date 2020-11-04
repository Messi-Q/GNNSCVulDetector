#!/usr/bin/env bash
for i in 0.352 0.38 0.4 0.42 0.45 0.48 0.5 0.52 0.55;
do
python ./GNNSCModel.py --random_seed 9930 --thresholds $i | tee logs/reentrancy/threshold/SVDetector_"$i".log;
done