## IPA_diploid_p

```bash
busco -f -c 20 -m genome \
    -i /share/workshop/genome_assembly/pacbio_2020_data_drosophila/hifi_long_read_diploid_ipa_assembly/RUN/14-final/final.p_ctg.fasta \
    -o IPA_diploid_p_ctg --lineage_dataset diptera_odb10
```

```
        --------------------------------------------------
        |Results from dataset diptera_odb10               |
        --------------------------------------------------
        |C:99.7%[S:34.8%,D:64.9%],F:0.1%,M:0.2%,n:3285    |
        |3273   Complete BUSCOs (C)                       |
        |1142   Complete and single-copy BUSCOs (S)       |
        |2131   Complete and duplicated BUSCOs (D)        |
        |3      Fragmented BUSCOs (F)                     |
        |9      Missing BUSCOs (M)                        |
        |3285   Total BUSCO groups searched               |
        --------------------------------------------------
```

## IPA_dipload_a

```bash
busco -f -c 20 -m genome \
    -i /share/workshop/genome_assembly/pacbio_2020_data_drosophila/hifi_long_read_diploid_ipa_assembly/RUN/14-final/final.a_ctg.fasta \
    -o IPA_diploid_a_ctg --lineage_dataset diptera_odb10
```

        ***** Results: *****

        C:28.8%[S:28.6%,D:0.2%],F:0.6%,M:70.6%,n:3285      
        947     Complete BUSCOs (C)                        
        940     Complete and single-copy BUSCOs (S)        
        7       Complete and duplicated BUSCOs (D)         
        21      Fragmented BUSCOs (F)                      
        2317    Missing BUSCOs (M)                         
        3285    Total BUSCO groups searched    


## IPA_diploid_a+p

```bash
cat /share/workshop/genome_assembly/pacbio_2020_data_drosophila/hifi_long_read_diploid_ipa_assembly/RUN/14-final/final.*.fasta  > ipa_diploid_a+p.fasta

busco -f -c 20 -m genome -i ipa_diploid_a+p.fasta -o IPA_diploid_a+p_ctg --lineage_dataset diptera_odb10
```

        --------------------------------------------------
        |Results from dataset diptera_odb10               |
        --------------------------------------------------
        |C:99.7%[S:10.5%,D:89.2%],F:0.1%,M:0.2%,n:3285    |
        |3273   Complete BUSCOs (C)                       |
        |344    Complete and single-copy BUSCOs (S)       |
        |2929   Complete and duplicated BUSCOs (D)        |
        |3      Fragmented BUSCOs (F)                     |
        |9      Missing BUSCOs (M)                        |
        |3285   Total BUSCO groups searched               |
        --------------------------------------------------

## Shasta

busco -f -c 20 -m genome \
    -i /share/biocore/shunter/drosophila/ShastaRun/Assembly.fasta -o Shasta_ctgs --lineage_dataset diptera_odb10
        --------------------------------------------------
        |Results from dataset diptera_odb10               |
        --------------------------------------------------
        |C:23.5%[S:21.5%,D:2.0%],F:2.8%,M:73.7%,n:3285    |
        |771    Complete BUSCOs (C)                       |
        |706    Complete and single-copy BUSCOs (S)       |
        |65     Complete and duplicated BUSCOs (D)        |
        |93     Fragmented BUSCOs (F)                     |
        |2421   Missing BUSCOs (M)                        |
        |3285   Total BUSCO groups searched               |
        --------------------------------------------------

## Flye

busco -f -c 20 -m genome \
    -i /share/biocore/shunter/drosophila/flyeasm/assembly.fasta -o Flye_ctgs --lineage_dataset diptera_odb10
        --------------------------------------------------
        |Results from dataset diptera_odb10               |
        --------------------------------------------------
        |C:99.5%[S:87.7%,D:11.8%],F:0.2%,M:0.3%,n:3285    |
        |3269   Complete BUSCOs (C)                       |
        |2882   Complete and single-copy BUSCOs (S)       |
        |387    Complete and duplicated BUSCOs (D)        |
        |5      Fragmented BUSCOs (F)                     |
        |11     Missing BUSCOs (M)                        |
        |3285   Total BUSCO groups searched               |
        --------------------------------------------------


# IPA primary contigs from Trio-binned Maternal assembly 
busco -f -c 40 -m genome \
    -i /share/workshop/genome_assembly/pacbio_2020_data_drosophila/hifi_long_read_mat_ipa_assembly/RUN/14-final/final.p_ctg.fasta -o IPA_trio-mat --lineage_dataset diptera_odb10



# IPA primary contigs from Trio-binned Paternal assembly
busco -f -c 40 -m genome \
-i /share/workshop/genome_assembly/pacbio_2020_data_drosophila/hifi_long_read_pat_ipa_assembly/RUN/14-final/final.p_ctg.fasta -o IPA_trio-mat --lineage_dataset diptera_odb10


# IPA contigs after purge_dups vs IPA primary contigs
busco -f -c 40 -m genome -i /share/workshop/genome_assembly/pacbio_2020_data_drosophila/purge_dup_asm/final.purged.p_ctg.fasta  -o IPA_purged.p_ctg --lineage_dataset diptera_odb10


## IPA accessory contigs after purge dup: 
busco -f -c 40 -m genome -i /share/workshop/genome_assembly/pacbio_2020_data_drosophila/purge_dup_asm/final.purged.a_ctg.fasta -o IPA_purged.a_ctg --lineage_dataset diptera_odb10


