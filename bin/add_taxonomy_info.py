# coding: utf-8
import os
def parse_path_to_three(path,suffix=""):
    path=os.path.realpath(path)
    t = os.path.split(path)
    dir_path = t[0]
    file = t[-1]
    if not suffix:
        namet = os.path.splitext(file)
        path_prefix = namet[0]
        path_suffix = namet[-1]
    else:
        path_suffix = suffix
        path_prefix = file.strip(path_suffix)
    print(dir_path,path_prefix,path_suffix)
    return dir_path,path_prefix,path_suffix


def find_lineage(taxid):
    import sys
    #sys.path.append("/home/viro/xue.peng/script")
    from NCBITaxonomy import ncbiAccTax
    t = ncbiAccTax()
    lineage = t.taxid2lineage(taxid)
    return lineage


def add_tax(infile,taxidCol,sep="\t"):
    import pandas as pd
    dir_path,file_prefix, file_suffix = parse_path_to_three(infile)
    opt = open(os.path.join(dir_path,"%s.addlineage%s"%(file_prefix,file_suffix)),"w")

    with open(infile) as f:
        for line in f:
            if line.startswith("#"):
                opt.write(line)
            else:
                lineL = line.strip("\n").split(sep)
                taxid=lineL[int(taxidCol)]
                try:
                    lineage = find_lineage(taxid)
                    print(lineage)
                except:
                    lineage = "unknown"
                lineL.insert(int(taxidCol)+1,lineage)
                print(lineL)
                opt.write("\t".join(lineL)+"\n")
        opt.close()

if __name__=="__main__":
    import sys
    infile=sys.argv[1]
    taxidCol=sys.argv[2]
    sep=sys.argv[3]
    #infile="./mmseqs/checkv_result_prophage.fna_lca.tsv"
    #taxidCol=1
    if sep!="tab":
        add_tax(infile,taxidCol,sep=sys.argv[3])
    else:
        add_tax(infile,taxidCol)

