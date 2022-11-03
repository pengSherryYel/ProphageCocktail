#!/usr/bin/bash

source /home/viro/xue.peng/.bashrc

## inputProteinFaa is a faa file which can be generate from prodigal, this is just a faa file of protein coding gene
## gene2genome file is to distinguish the protein belong to which contig, and this also can be generate from prodial script.
## gene2genome file HEADER is a must!!

inputProteinFaa=$1
gene2genome=$2
outputDir=${3:-"vc2_result"}
#db=${4:-"ProkaryoticViralRefSeq94-Merged"}
db=${4:-"ProkaryoticViralRefSeq201-Merged"}
#can be singularity|conda
mode=${5:-"singularity"}

sif='/home/viro/xue.peng/script/vcontact2/vConTACT2_202205.sif'
c1_bin="/home/viro/xue.peng/software_home/vcontact2/cluster_one-1.0.jar"
#c1_bin="/usr/local/bin/cluster_one-1.0.jar"
## check header in gene2genome => protein_id,contig_id,keywords
header=`head -n 1 $gene2genome`

if [ $header == "protein_id,contig_id,keywords$" ];then
    echo "header check PASSED!!!"
else
    echo "add header"
    sed 1i'protein_id,contig_id,keywords' $gene2genome >addHeader.$gene2genome.csv
    #echo "protein_id,contig_id,keywords" >addHeader.$gene2genome
    gene2genome="addHeader.$gene2genome.csv"
fi


mkdir -p $outputDir

if [ $mode == "conda" ]; then
    echo "run conda"
    . /home/viro/xue.peng/software_home/miniconda3/etc/profile.d/conda.sh
    conda activate vContact2
    c1_bin="/home/viro/xue.peng/software_home/vcontact2/cluster_one-1.0.jar"
    #echo "RUN COMMAND: vcontact2 --raw-proteins $inputProteinFaa --rel-mode 'Diamond' --proteins-fp $gene2genome --db $db --pcs-mode  MCL --vcs-mode ClusterONE --c1-bin $c1_bin --output-dir $outputDir"
    vcontact2 --raw-proteins $inputProteinFaa --rel-mode 'Diamond' --proteins-fp $gene2genome --db $db --pcs-mode MCL --vcs-mode ClusterONE --c1-bin $c1_bin --output-dir $outputDir

elif [ $mode == "singularity" ];then
    echo "run singularity"
    sif='/home/viro/xue.peng/script/vcontact2/vConTACT2_202205.sif'
    c1_bin="/usr/local/bin/cluster_one-1.0.jar"
    echo "singularity run -e  $sif --raw-proteins $inputProteinFaa --rel-mode 'Diamond' --proteins-fp $gene2genome --db $db --pcs-mode MCL --vcs-mode ClusterONE --c1-bin $c1_bin --output-dir $outputDir"
    singularity run -e  $sif --raw-proteins $inputProteinFaa --rel-mode 'Diamond' --proteins-fp $gene2genome --db $db --pcs-mode MCL --vcs-mode ClusterONE --c1-bin $c1_bin --output-dir $outputDir
fi

#vcontact2 --raw-proteins ./proteins_bins.faa --rel-mode 'Diamond' --proteins-fp ./gene-to-genome.csv --db 'ProkaryoticViralRefSeq94-Merged' --pcs-mode MCL --vcs-mode ClusterONE --c1-bin /home/viro/xue.peng/software_home/vcontact2/cluster_one-1.0.jar --output-dir vc2_result
