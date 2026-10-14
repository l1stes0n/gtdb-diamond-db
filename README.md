# GTDB DIAMOND Database

Build a DIAMOND protein database from the GTDB species representative genomes
with the taxonomy stored inside it, and search it.

```bash
bash gtdb_diamond_taxonomy.sh /path/to/outdir
bash gtdb_diamond_blastp.sh my.faa /path/to/outdir/protein_faa_reps/gtdb226_species_reps
```

`gtdb_diamond_taxonomy.sh` follows
[James Lingford's write-up](https://www.jameslingford.com/blog/gtdb-to-diamond-taxonomy-database/).
