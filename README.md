# Metagenomics_workflows
Repository for storing metagenomics workflows

# Metagenomics workflow containing [Kraken2](https://ccb.jhu.edu/software/kraken2/) and [Humann2](http://huttenhower.sph.harvard.edu/humann2)
**Metagenomic_workflow.sh** is a simple workflow for processing metagenomics sequencing data. Kraken2 and Humann2 are used for taxonomic and functional profiling, respectively.

## Important note regarding recent changes in bacterial taxonomy
Kraken2 utilizes NCBI's RefSeq database as a reference and some recent changes in bacterial taxonomy, which are already adopted by RefSeq, "clash" with Humann2's older Chocophlan taxonomy. This means that certain taxa identified by Kraken2 are not recognized by Humann2 during construction of sample-specific pan-genomes from identified species in each sample (e.g. *Cutibacterium acnes* in RefSeq is still listed as *Propionibacterium acnes* in Chocoplan). The Kraken2 to Humann2 conversion script, **Kraken2_mpa_humann2_compatiblity_print-whole_taxa_line.pl**, provides a short-term solution for this taxonomy discrepancy issue --> **(s/Cutibacterium/Propionibacterium/g)**.

## Define core pathways of certain sample groups (e.g. microbiomes from a certain body site or community state type) as ones that are detected with relative abundance >10−4 in at least 75% of subject-unique samples. 

A merged Humann2 output table (created using **humann2_join_tables** and **humann2_renorm_table**), or a subset thereof, serves as input for the core pathway extraction scripts listed below (provide input table using the *-humann2* flag):

```bash
  perl core_pathway_extraction_all_taxa.pl -humann2 sample_subset.tsv -coreRatio 0.75 -outFile core_from_all_taxa_sample_subset.txt

  perl core_pathway_extraction_total_abundance.pl -humann2 sample_subset.tsv -coreRatio 0.75 -outFile core_from_total_pathway_abundance_sample_subset.txt

  perl core_pathway_extraction_specific_taxa.pl -humann2 sample_subset.tsv -coreRatio 0.75 -outFile core_from_Staphylococcus_aureus_sample_subset.txt -speciesFilter Staphylococcus_aureus  
```
