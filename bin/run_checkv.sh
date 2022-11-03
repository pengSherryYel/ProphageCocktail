#!/usr/bin/bash

sampleid=$1
inseq=$2
optdir=${3:-'tmp'}
otherPara=${4:-'-t 2 --restart'}
checkv_level=${5:-2}
## "Complete,High-quality,Medium-quality,Low-quality,Undetermined quality"
## 0-Complete 1-Complete,High-quality et al
checkv_value_array=("Complete" "High-quality" "Medium-quality" "Low-quality" "Undetermined quality")

. /home/viro/xue.peng/software_home/miniconda3/etc/profile.d/conda.sh
conda activate
export CHECKVDB=/home/viro/xue.peng/software_home/checkv/checkv-db-v1.0


mkdir -p $optdir/$sampleid

## unzip input seq
gzcheck=`file $inseq|grep gzip`
if [ -n "$gzcheck" ]; then
    ungz_dir="ungz_seq"
    if [ ! -e $ungz_dir ]; then mkdir $ungz_dir; fi
    inseq_ungz=$ungz_dir/$sampleid.fna
    zcat $inseq > $inseq_ungz
else
    inseq_ungz=$inseq
fi

## checkv command
echo "Run Command: checkv end_to_end $inseq $optdir/$sampleid $otherPara"
checkv end_to_end $inseq_ungz $optdir/$sampleid $otherPara

## format the output
quality_opt="$optdir/$sampleid/quality_summary.tsv"
virus_opt="$optdir/$sampleid/viruses.fna"
provirus_opt="$optdir/$sampleid/proviruses.fna"

all_virus_opt="$optdir/$sampleid/proviruses_virus_all.fna"
all_virus_filter_opt="$optdir/$sampleid/proviruses_virus_all.level_${checkv_level}.fna"
if [ -e $all_virus_filter_opt ];then rm $all_virus_filter_opt ;fi
cat $virus_opt $provirus_opt > $all_virus_opt

## select above quality
for i in `seq 0 $(($checkv_level))`;do
    fv=${checkv_value_array[$i]};
    num=`awk -v fv="$fv" '$8~fv{print $1}' $quality_opt|wc -l`
    echo "filter: $fv $num"
    awk -v fv="$fv" '$8~fv{print $1}' $quality_opt|xargs -i grep -wEA1 --no-group-separator "{}.*" $all_virus_opt >>$all_virus_filter_opt
done
echo -e "$sampleid\t`realpath $all_virus_filter_opt`" >>$optdir.index

