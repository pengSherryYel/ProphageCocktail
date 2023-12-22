#!/usr/bin/bash

###
### Aim: use cd hit to cluster the protein seq using psi-cd-hit and cd-hit; [amino acid] seq
###   Reason: cd-hit-est can not cluster long sequence(genome or scaffold);
###   Reqirement: blast should in PATH
### Usage: sh $0 <infaa> <identity> [mode] [outDir] [otherPara_psicdhit] [runPara] [other_cdhit]
###    eg. sh run_cdhit_protein_cluster.sh example.protein.faa 0.9-0.8-0.6-0.3 hc
###    infaa: input amino acid sequence file (fasta format)
###    identity: default 0.95; can be multiple 0.95-0.90-0.6-0.3(big-small)
###    mode: hc|one-step
###          hc --> Hierarchical clustering using psi-cd-hit(<40%) and cd-hit(>40%)
###          one-step --> do not clustering the result
###    outDir: output dir name(default: ./cdhit_cluster_protein)
###    otherPara: parameter for cd-hit
###          otherPara_psicdhit --> "-G 1 -g 1 -aL 0.5 -aS 0.5 -prog blastp -circle 1"
###          otherPara_cdhit --> "-G 1 -g 1 -d 0 -aL 0.5 -aS 0.5 -M 0 -T 5"
###                    wd size(-n): 2:0.4-0.5; 3:0.5-0.6; 4:0.6-0.7; 5:0.7-1.0
###    runPara: parameter for psi-cd-hit. default: "-exec local -para 8 -blp 4"
###
###    Important parameter:
###         -G: global identity(total identical letters from all co-linear and non-overlapping HSPs/length of short sequence)#
###         -g: cdhit mode. 0 - fast mode, compare with representative; 1 - accuracy mode, compare all seq
###         -prog: psi-blast program. blastn: remote seq; megablast: more similar program best at 95% identity.
###                (blastp, blastn, megablast, psiblast), default blastp
###         -s: blast search para, default  "-seg yes -evalue 0.000001 -max_target_seqs 100000"
###         -circle: wheather treat input as cricle
###         -n: word_length, default 5, see user's guide for choosing it
###

infaa=$1
identity=${2:-0.95}
mode=${3:-"one-step"} ##hc|one-step
outDir=${4:-"./cdhit_cluster_protein"}
otherPara_psicdhit=${5:-""}
runPara=${6:-"-exec local -para 8 -blp 4"}
otherPara_cdhit=${7:-""}

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

##-----------
## main func
##-----------

function get_wd_size(){
    #wd size(-n): 2:0.4-0.5; 3:0.5-0.6; 4:0.6-0.7; 5:0.7-1.0
    query_iden=`echo "scale=0;$1*100/1"|bc`
    if (( $query_iden >= 70 ));then
        wd_size=5
    elif (( $query_iden < 70 )) && (( $query_iden >= 60 ));then
        wd_size=4
    elif (( $query_iden < 60 )) && (( $query_iden >= 50 ));then
        wd_size=3
    elif (( $query_iden < 50 )) && (( $query_iden >= 40 ));then
        wd_size=2
    else
        wd_size=0
    fi
    echo $wd_size
}


function run_cdhit(){
    ## if identity < 0.4, then use psi-cd-hit, otherwise cd-hit
    query_faa=$1
    input_identity=$2
    cd_hit_sft_dir=$3

    ## value decide choose for cdhit or psi-cd-hit
    value_lower=`echo "$input_identity >= 0.4"|bc`
    value_upper=`echo "$input_identity <= 1"|bc`

    ## define the opt result
    #read -r dirpath prefix suffix <<< `split_file_path $infaa`
    read -r dirpath prefix suffix <<< `split_file_path $query_faa`
    cd_hit_opt="$outDir/${prefix}_rep_idt${input_identity}.$suffix"
    tmp="cdhit_tmp"
    #mkdirs $tmp 1 && cp $infaa $tmp
    mkdirs $tmp 1 && cp ${query_faa}* $tmp

    if [ $value_lower -eq 0 ];then
        #tmp="cdhit_tmp"
        #mkdirs $tmp 1 && cp $infaa $tmp
        echo "use psi-cd-hit"
        cd_hit="$cd_hit_sft_dir/psi-cd-hit/psi-cd-hit.pl"
        ## set default parameter
        if [ -z "$otherPara_psicdhit" ];then
            otherPara_psicdhit="-G 1 -g 1 -aL 0.5 -aS 0.5 -prog blastp -circle 1"
        fi

        #cmd="$cd_hit -i $tmp/$infaa -o $cd_hit_opt -c $input_identity $otherPara_psicdhit $runPara"
        cmd="$cd_hit -i $tmp/$prefix.$suffix -o $cd_hit_opt -c $input_identity $otherPara_psicdhit $runPara"
        echo "Run Command: $cmd"
        $cmd && echo "psi-cd-hit DONE!!" && rm -rf $tmp

    elif [ $value_lower -eq 1 -a $value_upper -eq 1 ];then
        echo "use cd-hit"
        cd_hit="$cd_hit_sft_dir/cd-hit"

        if [ -z "$otherPara_cdhit" ];then
            otherPara_cdhit="-G 1 -g 1 -d 0 -aL 0.5 -aS 0.5 -M 0 -T 5"
        fi

        wd_size=`get_wd_size $input_identity`
        #cmd="$cd_hit -i $tmp/$infaa -o $cd_hit_opt -c $input_identity -n $wd_size $otherPara_cdhit"
        cmd="$cd_hit -i $tmp/$prefix.$suffix -o $cd_hit_opt -c $input_identity -n $wd_size $otherPara_cdhit"
        echo "Run Command: $cmd"
        $cmd && echo "cd-hit DONE!!" && rm -rf $tmp

    else
        echo "identity should be in 0-1"

    fi
}

##------------
## main func
##------------

scriptRealPath=`realpath $0`
scriptDir=`dirname $scriptRealPath`
source $scriptDir/utility.sh
mkdirs $outDir 1
declare -A clstr_dict
cd_hit_sft_dir="/home/viro/xue.peng/software_home/cdhit/cd-hit-v4.8.1-2019-0228"

if [ $mode == "one-step" ];then
    ## use same input then caluculate each identity creteria
    for i in `echo $identity|sed 's/-/ /g'`;do
        echo $i
        read -r dirpath prefix suffix <<< `split_file_path $infaa`
        #cd_hit_opt_clstr="$outDir/${prefix}_idt${i}.rep.${suffix}.clstr"
        run_cdhit $infaa $i $cd_hit_sft_dir
        cd_hit_opt_clstr="${cd_hit_opt}.clstr"
        clstr_dict[$i]=$cd_hit_opt_clstr
    done

elif [ $mode == "hc" ];then
    ## use input from last step then caluculate each identity creteria
    m=0
    for i in `echo $identity|sed 's/-/ /g'`;do
        echo $i
        read -r dirpath prefix suffix <<< `split_file_path $infaa`
        #cd_hit_opt_clstr="$outDir/${prefix}_idt${i}.rep.${suffix}.clstr"
        if (( $m >= 1 ));then
            #file_name_key="${file_name_key}_${iden_key}"
            run_cdhit $cd_hit_opt $i $cd_hit_sft_dir
            cd_hit_opt_clstr="${cd_hit_opt}.clstr"
            clstr_dict[$i]=$cd_hit_opt_clstr
            let m+=1
        elif (( $m == 0));then
            ## run cdhit
            run_cdhit $infaa $i $cd_hit_sft_dir
            cd_hit_opt_clstr="${cd_hit_opt}.clstr"
            clstr_dict[$i]=$cd_hit_opt_clstr
            let m+=1
        fi
    done
else
    echo "mode must be hc|one-step"
fi

##------------
##
m=0
script="$cd_hit_sft_dir/clstr_rev.pl"
if [ $mode == "hc" ];then
    echo "Begin to concat the cluster file"
    for iden_key in `echo $identity|sed 's/-/ /g'`;do
        echo $iden_key
        #echo ${clstr_dict[$iden_key]}

        if [[ $m > 1 ]] || [[ $m == 1 ]];then
            file_name_key="${file_name_key}_${iden_key}"
            two_clstr_array[1]=${clstr_dict[$iden_key]}
            ## do sth
            cd_hit_opt_clstr="$outDir/finalHcMerge_idt${file_name_key}.rep.${suffix}.clstr"
            merge_cmd="$script ${two_clstr_array[0]} ${two_clstr_array[1]} > $cd_hit_opt_clstr"
            $script ${two_clstr_array[0]} ${two_clstr_array[1]} > $cd_hit_opt_clstr
            echo "Run Command: $merge_cmd"
            #$merge_cmd
            two_clstr_array[0]=$cd_hit_opt_clstr

            #echo $file_name_key
            #echo ${two_clstr_array[@]}
            let m+=1

        elif [[ $m == 0 ]];then
            file_name_key=$iden_key
            two_clstr_array[0]=${clstr_dict[$iden_key]}
            let m+=1

            #echo $two_clstr_array[@]
            #echo $two_clstr_array
        else
            echo "xx"
        fi
    done
fi


