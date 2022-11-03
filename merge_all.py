# coding: utf-8
# %load merge_all.py
# %load merge_all.py
# %load merge_all.py
# %load merge_all.py
def mergeAll(dirname):
    import glob,os
    import pandas as pd
    import math
    import sys
    sys.path.append("/home/viro/xue.peng/script")
    from NCBITaxonomy import ncbiAccTax
    tc = ncbiAccTax()

    files=glob.glob("%s/btalign/*/*.idxstatstat"%dirname)
    #print(files)
    new_file_list=[]
    fna="merged.all.fna"
    if os.path.exists(fna): os.remove(fna)
    for singlefile in files:
        idname = singlefile.split("/")[-1].strip(".bam.idxstatstat")
        print(idname)
        d = pd.read_csv(singlefile,sep="\t").iloc[0:-1,]
        d["Sample"]=[idname]*len(d)
        d["Abundance"]=d["#mapped_read-segments"]/d["sequence_length"]
        sumAbundance=sum(d["Abundance"])
        d["Relative_abundance"]=round((d["#mapped_read-segments"]*100)/(sumAbundance*d["sequence_length"]),4)
        #print(d)
        print(sumAbundance,)

        ## add quality
        checkv_file="%s/checkv/%s/quality_summary.tsv"%(dirname,idname)
        checkv_df=pd.read_csv(checkv_file,sep="\t").loc[:,["contig_id","checkv_quality","provirus","gene_count","viral_genes","host_genes","miuvig_quality"]]
        #print(checkv_df)
        d = d.merge(checkv_df,left_on="reference_sequence_name",right_on="contig_id")
        new_idename="%s_"%idname

        checkv_fna_level2="%s/checkv/%s/proviruses_virus_all.level_2.fna"%(dirname,idname)
        get_ipython().system('cat $checkv_fna_level2|sed "s/>/>$new_idename/" >> merged.all.ckv_level2.fna')

        checkv_fna="%s/checkv/%s/proviruses_virus_all.fna"%(dirname,idname)
        get_ipython().system('cat $checkv_fna|sed "s/>/>$new_idename/" >> merged.all.fna')

        ## add lifecycle
        lifestyle_file="%s/replidec/%s/BC_predict.summary"%(dirname,idname)
        replidec_df=pd.read_csv(lifestyle_file,sep="\t").loc[:,["sample_name","pfam_label","bc_label","final_label","match_gene_number"]]
        #print(replidec_df)
        d = d.merge(replidec_df,right_on="sample_name",left_on="contig_id",how="left")

        ## add host
        host_file="%s/host_iphop/%s/Host_prediction_to_genome_m90.csv"%(dirname,idname)
        if os.path.exists(host_file):
            name_list=[]
            index_list=[]
            host_df=pd.read_csv(host_file,sep=",")
            for i in host_df.index:
                first_name=host_df.loc[i,"Virus"]
                if first_name not in name_list:
                    name_list.append(first_name)
                    index_list.append(i)
            subset_host_df=host_df.loc[index_list,["Virus","Host taxonomy","Confidence score"]]
            d = d.merge(subset_host_df,left_on="contig_id",right_on="Virus",how="left")
        #print(subset_host_df)

        ## merge all df into one
        new_file_list.append(d)
        finaldf = pd.concat(new_file_list)
        finaldf.to_csv("merged.all.abundance.csv")
        #print(finaldf)
    tax = "%s/mmseqs/merged.all_lca.tsv"%(dirname)
    tax_df = pd.read_csv(tax,sep="\t",header=None).iloc[:,0:4]
    tax_df.columns = ["name","taxid","tax_level","tax_name"]
    tax_lin=[tc.taxid2lineage(i) for i in tax_df["taxid"]]
    print(tax_lin)
    tax_df["tax_linage"] = tax_lin
    tax_df["contig_id"] = ["_".join(i.split("_")[1:]) for i in tax_df.name]
    print(tax_df)
    finaldf = finaldf.merge(tax_df,left_on="reference_sequence_name",right_on="contig_id",how="left")
    print(finaldf.columns)
    finaldf.to_csv("merged.all.abundance.tax.csv")
mergeAll(".")
