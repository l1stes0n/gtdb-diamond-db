#!/bin/bash
#
# Build a taxonomy-aware DIAMOND database from the GTDB R226 species
# representative protein sequences, following
# https://www.jameslingford.com/blog/gtdb-to-diamond-taxonomy-database/
#
#   bash gtdb_diamond_taxonomy.sh [outdir]
#
# Produces, under outdir:
#   protein_faa_reps/gtdb226_combined_faa_withgenomeids.faa.gz
#   protein_faa_reps/gtdb226_species_reps.dmnd

OUTDIR=${1:-.}
threads=16

PROT_URL=https://data.ace.uq.edu.au/public/gtdb/data/releases/release226/226.0/genomic_files_reps/gtdb_proteins_aa_reps_r226.tar.gz
TAX_URL=https://github.com/shenwei356/gtdb-taxdump/releases/download/v0.6.0/gtdb-taxdump-R226.tar.gz

mkdir -p "$OUTDIR"
cd "$OUTDIR"

[ -s gtdb_proteins_aa_reps_r226.tar.gz ] || wget -c "$PROT_URL"
[ -s gtdb-taxdump-R226.tar.gz ]          || wget -c "$TAX_URL"
[ -d protein_faa_reps ]                  || tar xf gtdb_proteins_aa_reps_r226.tar.gz
[ -d gtdb-taxdump-R226 ]                 || tar xf gtdb-taxdump-R226.tar.gz

TAXDUMP=$PWD/gtdb-taxdump-R226
cd protein_faa_reps

# prefix the genome id, giving the >GENOMEID~PROTEINID accessions DIAMOND looks up
COMBINED=gtdb226_combined_faa_withgenomeids.faa
: > "$COMBINED"

for file in ./{bacteria,archaea}/*_protein.faa.gz; do
    stem=${file##*/}
    stem=${stem%_protein.faa.gz}
    magid=${stem#RS_}
    magid=${magid#GB_}

    zcat "$file" | awk -v m="$magid" '/^>/{sub(/^>/,"",$1); printf ">%s~%s\n", m, $1; next} {print}' \
        >> "$COMBINED"
done

pigz -f -p "$threads" "$COMBINED"

if [ ! -s taxidmap ]; then
    printf 'accession.version\ttaxid\n' > taxidmap
    zcat "${COMBINED}.gz" | awk -F'\t' 'NR==FNR{t[$1]=$2; next}
        /^>/{a=$1; sub(/^>/,"",a); g=a; sub(/~.*/,"",g); print a"\t"t[g]}' \
        "$TAXDUMP/taxid.map" - >> taxidmap
fi

# making diamond database
diamond makedb \
    --in "${COMBINED}.gz" \
    --db gtdb226_species_reps \
    --taxonmap taxidmap \
    --taxonnodes "$TAXDUMP/nodes.dmp" \
    --taxonnames "$TAXDUMP/names.dmp" \
    --threads "$threads"


# mkdir -p tmp
# diamond blastp \
#     -q my.faa \
#     -d protein_faa_reps/gtdb226_species_reps \
#     --very-sensitive \
#     --id 30 \
#     --evalue 1e-5 \
#     --max-target-seqs 5 \
#     --subject-cover 50 \
#     --query-cover 50 \
#     --header simple \
#     --tmpdir ./tmp \
#     --outfmt 6 qseqid sseqid pident evalue bitscore qcovhsp scovhsp staxids \
#               sskingdoms skingdoms sphylums sscinames salltitles stitle \
#               full_qseq full_sseq slineages \
#     | awk 'BEGIN{FS=OFS="\t"} NR==1{next}
#            {x=$17; gsub(/; /,";",x); sub(/;[^;]*$/,"",x)
#             print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,x}' \
#     > my.faa.gtdb226

