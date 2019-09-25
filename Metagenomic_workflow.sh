#!/bin/sh
#SBATCH --time 48:00:00
#SBATCH -p short -n 160
#SBATCH -o meta_wgs%j.out
#SBATCH -e meta_wgs%j.err

module load parallel/20141022
module load kraken/2.0.7-beta
module load humann2/0.11.2

#create output folders
mkdir humann2_out
mkdir humann2_final_out

#scripts and database locations
export scripts="/path/to/scripts"
export krakenDB="/path/to/kraken2_db"
export chocophlan="/path/to/chocophlan"
export uniref="/path/to/uniref"

#Merge reads. This is done after quality filtering so that both reads in a pair are either discarded or retained
#Use Perl version that includes Parallel/ForkManager.pm
perl $scripts/concat_paired_end.pl -p 2 --no_R_match -o cat_reads Kneaddata_clean_reads/*_paired_*.fastq

#Identify taxa from the merged reads using Kraken2
parallel -j 2 --load 80% 'kraken2 --db $krakenDB --report {.}.report.mpa --use-mpa-style --output {.}.kraken {}' ::: cat_reads/*.fastq

#Convert Kraken2 output to Metaphlan2 output to make it fully compatible with Humann2
for file in cat_reads/*.mpa; do perl $scripts/Kraken2_mpa_humann2_compatiblity_print-whole_taxa_line.pl $file; done

#Batch process data using parallel and Humann2
parallel -j 10 --load 80% 'humann2 --input {} --taxonomic-profile {.}.krakenmetaphlan --nucleotide-database $chocophlan --protein-database $uniref --translated-query-coverage-threshold 70.0 --threads 16 --memory-use maximum --output humann2_out/{/.}_humann2_out' ::: cat_reads/*.fastq

#Merge humann2 pathabundance output per sample into one table
humann2_join_tables -s --input humann2_out/ --file_name pathabundance --output humann2_final_out/humann2_pathabundance.tsv
#Re-normalize pathway abundances (to relative abundance)
humann2_renorm_table -i humann2_final_out/humann2_pathabundance.tsv --special n -u relab -o humann2_final_out/humann2_pathabundance_relab.tsv

#Merge humann2 genefamilies output per sample into one table
humann2_join_tables -s --input humann2_out/ --file_name genefamilies --output humann2_final_out/humann2_genefamilies.tsv
#Re-normalize gene family (to relative abundance)
humann2_renorm_table -i humann2_final_out/humann2_genefamilies.tsv --special n -u relab -o humann2_final_out/humann2_genefamilies_relab.tsv

#unpack pathways
humann2_unpack_pathways --input-genes humann2_final_out/humann2_genefamilies_relab.tsv --input-pathways humann2_final_out/humann2_pathabundance_relab.tsv --output humann2_final_out/humann2_unpacked_pathways.tsv
