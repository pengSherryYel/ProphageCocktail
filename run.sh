#!/usr/bin/bash
##input
name=$1
fq1=$2
fq2=$3
filter_length=${4:-1000} ## this is used for filter scaffolds length above this

##fastpOutput
qcDir="qc/$name"
fastpfq1="$qcDir/$name.1.fastq.gz"
fastpfq2="$qcDir/$name.2.fastq.gz"

##spadesOutput
assembleDir="assemble_spades/$name"
scaffolds="$assembleDir/scaffolds.fasta"
scaffolds_limit_length="$assembleDir/scaffolds.gt${filter_length}.fasta"


##software
fastp="/home/viro/xue.peng/software_home/fastp/fastp"
spades="/home/viro/xue.peng/software_home/SPAdes-3.15.2-Linux/bin/spades.py"

## function
echo $name
###qc
mkdir -p $qcDir
$fastp -i $fq1 -I $fq2 -o $fastpfq1 -O $fastpfq2 -q 20 -h $qcDir/$name.fastp.html -j $qcDir/$name.fastp.json -z 4 -n 1 -l 30 -5 -W 4 -M 20 -r -c -g -x -f 0 -t 15 -F 0 -T 15

###assemble
mkdir -p $assembleDir
$spades --meta -1 $fastpfq1 -2 $fastpfq2 -o $assembleDir
#

### filter length
seqkit seq -m $filter_length $scaffolds >$scaffolds_limit_length

### checkv
checkv_opt_above_mq="./checkv/$name/proviruses_virus_all.level_2.fna"
checkv_opt="./checkv/$name/proviruses_virus_all.fna"
#sh run_checkv.sh $name $scaffolds_limit_length "checkv"


### replidec
. /home/viro/xue.peng/software_home/miniconda3/etc/profile.d/conda.sh
conda activate replidec
Replidec -i $checkv_opt  -p multiSeqEachAsOne -w replidec/$name -c 1e-5 -m 1e-5 -b 1e-5
conda deactivate

### host
. /home/viro/xue.peng/software_home/miniconda3/etc/profile.d/conda.sh
conda activate iphop_env

host_dir="./host_iphop/$name"
mkdir -p $host_dir
iphop predict --out_dir $host_dir --db_dir /project/genomics/jru/data2/db/viroprofiler/iphop/Sept_2021_pub --num_threads 8 --fa_file $checkv_opt
conda deactivate

### bt alignment
. /home/viro/xue.peng/script/bt2.sh
#btbuild $checkv_opt bt2Index/$name "--threads 3"
btbuild $scaffolds_limit_length bt2Index/$name "--threads 3"
btalign bt2Index/$name $fastpfq1 $fastpfq2 $name "--sensitive-local -q -p 10"
samtoolsStat ./btalign/$name/$name.bam

