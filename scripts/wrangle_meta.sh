#!/bin/bash


FSTQ=$(find ../../RawData/lcNGS_2025/files/P36454/ -name "*.fastq.gz" -type f)


# Goal
# sample	unit	lib	platform	fq1	fq2

# Sample we get from tmp.2.tsv f1
# unit we get from MetaData_bioinfo f14
# lib we get from tmp2.tsv f2
# platform is ILLUMINA
# fq1 and fq2 we get from $FSTQ

echo -e "sample\tunit\tlib\tplatform\tfq1\tfq2" > doc/units.tsv

for file in $(echo $FSTQ | tr " " "\n" | grep "_R1_"); do
    
    UNIT=$(echo $file | cut -f 7 -d "/")
    LANE=$(echo $file | cut -f 9 -d "_" | sed s/L00//g)
    UNIT_FIN=${UNIT}.$LANE
    R2=$(echo $file | tr " " "\n" | sed s/_R1_/_R2_/g)
    LIB=$(cat doc/MetaData_bioinfo.tsv | grep $UNIT | cut -f14)
    SAMP=$(cat tmp.2.tsv | grep $UNIT | cut -f 1)

    echo -e "$SAMP\t$UNIT_FIN\t$LIB\tILLUMINA\t$file\t$R2" | grep -f tmp.2.samp >> doc/units.tsv
done