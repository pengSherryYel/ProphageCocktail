#!/usr/bin/bash

## prokka veerison: prokka-1.14.5
## The input is a contig or a genome not a faa file
prefix=${1:-"prokka"}
input_contig=${2:-"./test.fna"}
out_dir=${3:-"prokka"}
other_para=${4:-"--evalue 1e-05 --coverage 50 --gcode 11 --kingdom Viruses --cpus 8"}
mode=${5:-"conda"} ## conda | singularity

prokka_singularity="/home/viro/xue.peng/script/prokka/prokka_modify_PHROGs.sif"

#####
if [ ! -e $out_dir ]; then mkdir -p $out_dir;fi
input_suffix=`echo ${input_contig##*.}`
input_prefix=`basename $input_contig .$input_suffix`
echo "$input_suffix, $input_prefix"
input_dir=`dirname $input_contig`
## change name length, if the name too long will infect the gbk file
## change name
ln -s $input_contig
changed_name_fna=`python /home/viro/xue.peng/script/utility_python/rename_seq_id_substring.py $input_prefix.$input_suffix "_" 0 2`
chmod 755 $changed_name_fna
##changed_name_fna="$input_prefix.rename.$input_suffix"
##echo $changed_name_list

## run prokka
out_dir_full=`realpath $out_dir`

if [ $mode == "singularity" ];then
echo "RUN COMMAND:\
    singularity exec -B /home/viro/xue.peng/software_home/prokka/hmm:/prokka-1.14.1/db/hmm -B `pwd` $prokka_singularity prokka $other_para --force --outdir $out_dir --prefix $prefix --rawproduct $changed_name_fna"
#singularity exec -B $out_dir_full $prokka_singularity prokka $other_para --force --outdir $out_dir --prefix $prefix --rawproduct $changed_name_fna

singularity exec -B /home/viro/xue.peng/software_home/prokka/hmm:/prokka-1.14.1/db/hmm -B `pwd`:/data \
    $prokka_singularity prokka $other_para --force --outdir /data/$out_dir --prefix $prefix --rawproduct /data/$changed_name_fna &&\
    echo "Done!!"
elif [ $mode == "conda" ];then
    . /home/viro/xue.peng/software_home/miniconda3/etc/profile.d/conda.sh
    conda activate prokka
    prokka $other_para --force --outdir $out_dir --prefix $prefix --rawproduct $changed_name_fna &&\
    echo "Done!!"
    conda deactivate
fi

