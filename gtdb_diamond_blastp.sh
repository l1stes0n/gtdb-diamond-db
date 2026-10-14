#!/bin/bash

# bash gtdb_diamond_blastp.sh <query.faa> <database prefix>

query=$1
database=$2
out="${query##*/}.${database##*/}"

mkdir -p tmp

diamond blastp \
    -q "$query" \
    -d "$database" \
    --very-sensitive \
    --id 30 \
    --evalue 1e-5 \
    --max-target-seqs 0 \
    --subject-cover 50 \
    --query-cover 50 \
    --header simple \
    --tmpdir ./tmp \
    --outfmt 6 qseqid sseqid pident evalue bitscore qcovhsp scovhsp staxids \
              sskingdoms skingdoms sphylums sscinames salltitles stitle \
              full_qseq full_sseq slineages \
    | awk 'BEGIN{FS=OFS="\t"} NR==1{next}
           {x=$17; gsub(/; /,";",x); sub(/;[^;]*$/,"",x)
            print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,x}' \
    > "$out"
