# Answers to challenge activities and CLI/cluster warmup

1. Win scp, filezilla or secure copy (scp)
2. `samples = ["A", "B", "C"]`
https://snakemake.readthedocs.io/en/stable/project_info/faq.html#how-do-i-remove-all-files-created-by-snakemake-i-e-like-make-clean
OR
`rm -rf calls/ mapped/ plots/`
3.     
```
    shell:
        "module load samtools; "
        "module load bcftools; "
```        
4. 
```
rule vcf_tsv:
    input:
        "calls/all.vcf"
    output:
        "calls/vcf.tsv"
    shell:
        "sed '/##/d' {input} > {output}" 
```     

```
rule all:
    input:
        "calls/all.vcf",
        "plots/quals.svg",
        "calls/vcf.tsv"
```
OR 
```        
   "sed '1,28d' {input} > {output}"
```
5. temp() on the sorted one