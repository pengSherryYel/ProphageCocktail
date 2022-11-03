#!/usr/bin/bash
less Vanno_opt/Vanno_summary.tsv |grep -i endolysin|cut -f 2|xargs -i grep -A 1 {} prokka/merged_all_contig_reformat_out.faa> tree/endolysin.faa
grep -i :[es]RR tree/endolysin.faa|cut -d " " -f 1|xargs -i grep -A 1 {} tree/endolysin.faa >tree/endolysin.cocktail.faa
sh ~/script/run_cdhit_protein_cluster.sh tree/endolysin.cocktail.faa 1 one-step ./tree/cdhit_cluster_protein

## add pfam and phrog into one

sh ~/script/module_tree/mafft/run_mafft_trimal.sh tree/cdhit_cluster_protein/endolysin.cocktail_rep_idt1.faa tree
sh ~/script/module_tree/iqtree/run_iqtree.sh tree/endolysin.cocktail_rep_idt1.accuracy.trimal.msa
cd tree

#less ../Vanno_opt/Vanno_summary.tsv| grep -i endolysin|awk -F '\t' '{printf "%s\t%s (%s)|%s (%s)\n",$0,$7,$8,$11,$9}' > Vanno_summary.onlyendlysin.tsv
less ../Vanno_opt/Vanno_summary.tsv| grep -i endolysin|awk -F '\t' '{printf "%s\t%s (%s)\n",$0,$11,$9}' > Vanno_summary.onlyendlysin.tsv
python ~/script/module_tree/generate_itol_color_strip_multicol.py -i Vanno_summary.onlyendlysin.tsv -k 1 -v 8 -n phrogs_id
python ~/script/module_tree/generate_itol_color_strip_multicol.py -i Vanno_summary.onlyendlysin.tsv -k 1 -v 10 -n phrogs_des
python ~/script/module_tree/generate_itol_color_strip_multicol.py -i Vanno_summary.onlyendlysin.tsv -k 1 -v 13 -n pfam_phrogs
less endolysin.faa|grep \>|sed '{s/>//;s/from://;s/_NODE_[0-9]*//;s/\s/\t/1;s/\s/\t/2}'>endolysin.header.index
python ~/script/module_tree/generate_itol_color_strip_multicol.py -i endolysin.header.index -k 0 -v 1 -n cocktail
python ~/script/module_tree/generate_itol_color_strip_multicol.py -i endolysin.header.index -k 0 -v 2 -n prokka
