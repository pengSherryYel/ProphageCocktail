#!/usr/bin/bash

###
### Aim: multiple alignment and then trim gap; run mafft and trimal
### Usage: sh $0 <inputseq> [output_dir(.)] [mafft_mode] [trimal_para]
###    mafft_mode: fast|accuracy
###        fast --> mafft: FFT-NS-2 ; accuracy --> mafft-linsi: L-INS-i
###    trimal_para: "-gappyout"
###

##----------
## help
##----------
help() {
    sed -rn 's/^### ?//;T;p;' "$0"
}

if [ $# == 0 ];then
    help
    exit 1
fi

##----------
## parameter
##----------
inputseq=$1
output_dir=${2:-"."}
mafft_mode=${3:-"accuracy"}
trimal_para=${4:-"-gappyout"}

source /home/viro/xue.peng/software_home/miniconda3/etc/profile.d/conda.sh
conda activate mafft
trimal="/home/viro/xue.peng/software_home/trimal/trimal-1.4.1/source/trimal"

## function
function split_file_path(){
     path=$1
     path_dir=`dirname $path`
     path_suffix=`echo ${path##*.}`
     path_prefix=`basename $path .$path_suffix`
     echo $path_dir $path_prefix $path_suffix
}

## run mafft
read -r path_dir prefix suffix <<< `split_file_path $inputseq`
if [ $mafft_mode == "fast" ];then
    mafft_cmd="mafft"
elif [ $mafft_mode == "accuracy" ];then
    mafft_cmd="mafft-linsi"
else
    echo "mafft_mode must be accuracy|fast"
fi

mafft_opt="$output_dir/${prefix}.${mafft_mode}.msa"
cmd="$mafft_cmd $inputseq > $mafft_opt"
echo "RUN COMMAND: $cmd"
$mafft_cmd $inputseq > $mafft_opt


## trim
trimal_opt="$output_dir/${prefix}.${mafft_mode}.trimal.msa"
cmd="$trimal -in $mafft_opt -out $trimal_opt $trimal_para"
echo "RUN COMMAND: $cmd"
$cmd
