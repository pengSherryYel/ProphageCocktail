#!/usr/bin/bash

## IQ-TREE multicore version 2.0.3 for Linux 64-bit built Dec 20 2020
input_msa=$1
iqtree_para=${2:-"-m MFP -B 1000 -T 10"}
## can use -m to specific mode. the default is to use modelFilder
## -B use ultrafast boost
#ModelFinder computes the log-likelihoods of an initial parsimony tree for many different models and the Akaike information criterion (AIC), corrected Akaike information criterion (AICc), and the Bayesian information criterion (BIC). Then ModelFinder chooses the model that minimizes the BIC score (you can also change to AIC or AICc by adding the option -AIC or -AICc, respectively).

source /home/viro/xue.peng/software_home/miniconda3/etc/profile.d/conda.sh
conda activate iqtree

echo "RUN COMMAND: iqtree -s $input_msa $iqtree_para"
iqtree -s $input_msa $iqtree_para
