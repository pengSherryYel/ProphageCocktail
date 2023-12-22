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
#assembleDir="assemble_spades/$name"
assembleDir="assemble_spades/${name}"
scaffolds="$assembleDir/scaffolds.fasta"
scaffolds_limit_length="$assembleDir/scaffolds.gt${filter_length}.fasta"


##software
fastp="/home/viro/xue.peng/software_home/fastp/fastp"
spades="/home/viro/xue.peng/software_home/SPAdes-3.15.2-Linux/bin/spades.py"

## function
echo $name
function mkdirs(){
    dir_name=$1
    clean=${2:-0}
    if [[ -e $dir_name && $clean == 1 ]];then
        rm -rf $dir_name  && mkdir -p $dir_name
    elif [[ -e $dir_name && $clean == 0 ]];then
        echo "dir exist and not clean!!"
    else
        mkdir -p $dir_name
    fi
}

### remove phiX
#. /home/viro/xue.peng/script/bt2.sh
phix_dirname="phiX_$name"
phix_opt="btalign/${phix_dirname}/${phix_dirname}.bam"
phix_unmapped_reads_index="btalign/${phix_dirname}/${phix_dirname}.unmapped.id"
rx_fq1="btalign/${phix_dirname}/${phix_dirname}.1.fq.gz"
rx_fq2="btalign/${phix_dirname}/${phix_dirname}.2.fq.gz"
##
#btalign fastq_screen/FastQ_Screen_Genomes/PhiX/phi_plus_SNPs $fq1 $fq2 $phix_dirname "--sensitive-local -q -p 10"
#samtools view -f 12 $phix_opt |cut -f 1|sort |uniq > $phix_unmapped_reads_index
#seqtk subseq $fq1 $phix_unmapped_reads_index|gzip > $rx_fq1
#seqtk subseq $fq2 $phix_unmapped_reads_index|gzip > $rx_fq2
#
####qc
mkdir -p $qcDir
## this is for the cocktail
$fastp -i $rx_fq1 -I $rx_fq2 -o $fastpfq1 -O $fastpfq2 -q 20 -h $qcDir/$name.fastp.html -j $qcDir/$name.fastp.json -z 4 -n 10 -l 60 -5 -3 -W 4 -M 20 -c -g -x
### below is for inhouse data
#$fastp -i $fq1 -I $fq2 -o $fastpfq1 -O $fastpfq2 -q 20 -h $qcDir/$name.fastp.html -j $qcDir/$name.fastp.json -z 4 -n 1 -l 30 -5 -W 4 -M 20 -r -c -g -x -f 0 -t 15 -F 0 -T 15
#
####assemble
mkdirs $assembleDir 0
$spades --meta -1 $fastpfq1 -2 $fastpfq2 -o $assembleDir -k 21,33,55,77,99
##
#
#### filter length
seqkit seq -m $filter_length $scaffolds >$scaffolds_limit_length
#
# checkv
checkv_opt_above_mq="./checkv/$name/proviruses_virus_all.level_2.fna"
checkv_opt="./checkv/$name/proviruses_virus_all.fna"
#sh run_checkv.sh $name $scaffolds_limit_length "checkv"


## replidec
. /home/viro/xue.peng/software_home/miniconda3/etc/profile.d/conda.sh
conda activate replidec
Replidec -i $checkv_opt -p multiSeqEachAsOne -w replidec/$name -c 1e-5 -m 1e-5 -b 1e-5
conda deactivate

## host
. /home/viro/xue.peng/software_home/miniconda3/etc/profile.d/conda.sh
conda activate iphop_env

host_dir="./host_iphop/$name"
mkdirs $host_dir 1
iphop predict --out_dir $host_dir --db_dir /home/viro/xue.peng/software_home/iphop/iphop_db/Sept_2021_pub --num_threads 8 --fa_file $checkv_opt
conda deactivate

# --
 bt alignment
bt_unmapped_header="./btalign/$name/$name.unmapped.header"
bt_unmapped_fq1="./btalign/$name/$name.unmapped.1.fq.gz"
bt_unmapped_fq2="./btalign/$name/$name.unmapped.2.fq.gz"
. /home/viro/xue.peng/script/bt2.sh
btbuild $checkv_opt bt2Index/$name "--threads 3"
#xxxbtbuild $scaffolds_limit_length bt2Index/$name "--threads 3"
# use checkv, remove the host region
btalign bt2Index/$name $fastpfq1 $fastpfq2 $name "--sensitive-local -q -p 10"
samtoolsStat ./btalign/$name/$name.bam
# filter unmapped reads
samtools view -f 12 ./btalign/$name/$name.bam |cut -f 1|sort |uniq > $bt_unmapped_header
seqtk subseq $fastpfq1 $bt_unmapped_header|gzip > $bt_unmapped_fq1
seqtk subseq $fastpfq2 $bt_unmapped_header|gzip > $bt_unmapped_fq2

# kraken
kraken_dir="kraken"
mkdirs $kraken_dir/$name
export KRAKEN2_DB_PATH="/home/viro/xue.peng/software_home/kraken2-v2.1.2:"
~/software_home/kraken2-v2.1.2/kraken2 -db MinusB --paired --classified-out $kraken_dir/$name/classified_seqs#.fq --unclassified-out $kraken_dir/$name/unclassified_seqs#.fq $bt_unmapped_fq1 $bt_unmapped_fq2 --report $kraken_dir/$name/$name.kranken.report >$kraken_dir/$name/$name.kranken.mapping.out
#python ~/script/utility_python/taxonomy/add_taxonomy_info.py $kraken_dir/$name/$name.kranken.mapping.out 2

## bt bacteria containmation
btPara="--sensitive-local -q -p 10"
btalign /home/viro/xue.peng/software_home/FastQ_Screen/FastQ-Screen-0.15.2/FastQ_Screen_Genomes/E_coli/Ecoli $bt_unmapped_fq1 $bt_unmapped_fq2 ref_ecoli_$name $btPara
btalign /home/viro/xue.peng/software_home/FastQ_Screen/FastQ-Screen-0.15.2/FastQ_Screen_Genomes/Human/Homo_sapiens.GRCh38 $bt_unmapped_fq1 $bt_unmapped_fq2 ref_human_$name $btPara
btalign /home/viro/xue.peng/publicData/ncbi/genomes/refseq/btIndex/ecoli_two_represent $bt_unmapped_fq1 $bt_unmapped_fq2 ref_myecoli_$name $btPara
btalign /home/viro/xue.peng/publicData/ncbi/genomes/refseq/btIndex/GCF_000006925.2_SF $bt_unmapped_fq1 $bt_unmapped_fq2          ref_Shigella_$name $btPara
btalign /home/viro/xue.peng/publicData/ncbi/genomes/refseq/btIndex/GCF_000069965.1_PM $bt_unmapped_fq1 $bt_unmapped_fq2 ref_Proteus_$name $btPara
btalign /home/viro/xue.peng/publicData/ncbi/genomes/refseq/btIndex/GCF_009734005.1_EF $bt_unmapped_fq1 $bt_unmapped_fq2 ref_Enterococcus_$name $btPara
btalign /home/viro/xue.peng/publicData/ncbi/genomes/refseq/btIndex/GCF_000006765.1_PA $bt_unmapped_fq1 $bt_unmapped_fq2 ref_Pseudomonas_$name $btPara
btalign /home/viro/xue.peng/publicData/ncbi/genomes/refseq/btIndex/GCF_003516165.1_SM $bt_unmapped_fq1 $bt_unmapped_fq2 ref_Serratia_$name $btPara
btalign /home/viro/xue.peng/publicData/ncbi/genomes/refseq/btIndex/GCF_000013425.1_SA $bt_unmapped_fq1 $bt_unmapped_fq2 ref_Staphylococcus_$name $btPara

# --
