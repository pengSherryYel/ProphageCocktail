#!/usr/bin/bash

## compare the genome of above median quality contig which is temerate; only 3 genome
mkdir prokka
grep -i temperate merged.all.abundance.tax.csv |grep -vE "Not-determined|Low-quality"|grep RR|cut -d , -f 3|xargs -i grep -A 1 {} merged.all.fna > prokka/cocktail_temperate.ori.fna
sh ~/script/run_prokka.sh cocktail_temperate ./prokka/cocktail_temperate.ori.fna ./prokka "--evalue 1e-05 --coverage 50 --gcode 11 --kingdom Bacteria --cpus 8"

## run with annotation for tree construction
sh ~/script/run_prokka.sh merged_all_contig merged.all.fna  ./prokka "--evalue 1e-05 --coverage 50 --gcode 11 --kingdom Bacteria --cpus 8"
python ~/script/utility_python/gbk2faa_rename.py -i prokka/merged_all_contig.gbk
python ~/script/module_annotation/Vanno/annotation.py -i ./prokka/merged_all_contig_reformat_out.faa -k -v -p -r -rf -pf -t 10
