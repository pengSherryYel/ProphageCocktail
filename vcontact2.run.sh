#!/usr/bin/bash

input_scaffolds="merged.all.fna"
#input_scaffolds=$1
prefix=${2:-"vc2_rerun"}
p_prefix="$prefix/cocktail_merged"
#sh ~/script/run_prodigal.sh $input_scaffolds $p_prefix meta
prodigal_faa="$p_prefix.faa"
gene2genome="$p_prefix.gene2genome.csv"
v_prefix="$prefix/vc2"
#. /home/viro/xue.peng/software_home/miniconda3/etc/profile.d/conda.sh
sh ~/script/run_vconcat2.sh $prodigal_faa $gene2genome $v_prefix
#singularity run -B /project/genomics/xuePeng:/project/genomics/xuePeng /home/viro/xue.peng/script/vcontact2/vConTACT2_202210.sif --raw-proteins /project/genomics/xuePeng/workPlace/workplace_2022/prophageInphagecocktail/vc2//cocktail_merged.faa --rel-mode 'Diamond' --proteins-fp /project/genomics/xuePeng/workPlace/workplace_2022/prophageInphagecocktail/vc2/addHeader.cocktail_merged.gene2genome.csv --db ProkaryoticViralRefSeq211-Merged --pcs-mode MCL --vcs-mode ClusterONE --c1-bin /usr/local/bin/cluster_one-1.0.jar --output-dir vc2 --blast-fp /project/genomics/xuePeng/workPlace/workplace_2022/prophageInphagecocktail/vc2/merged.self-diamond.tab
