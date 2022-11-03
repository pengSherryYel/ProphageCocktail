#!/usr/bin/bash

conda activate abricate
abricate --db vfdb merged.all.fna >merged.all.vfdb.tab
