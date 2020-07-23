<center><a href="https://busco.ezlab.org/"><img src="figures/busco.png" alt="busco" width="20%" align="center"/></center></a>


**Benchmarking Universal Single-Copy Orthologs**, [BUSCO](https://doi.org/10.1093/bioinformatics/btv351), is a popular software package for assessing genome/transcriptome assembly completeness using single copy orthologs. It was published in Oct 2015 and had 3486 citations as of July 2020 according to Google Scholar! [The authors](https://www.sib.swiss/evgeny-zdobnov-group) are also responsible for [OrthoDB](https://www.orthodb.org/), a large database of curated [orthologous genes](https://www.orthodb.org/orthodb_userguide.html#terminology). 

The BUSCO sets are collections of nearly universally distributed (90%) single-copy orthologous genes found within species at a specific phylogenetic level. Originally these sets represented arthropods, vertebrates, metazoans, fungi, and eukaryotes, but additional genome sequences have made it possible to create BUSCO sets at a finer scale.

These sets are determined by analysis of species in the OrthoDB database. [The theory](https://academic.oup.com/gbe/article/doi/10.1093/gbe/evq083/573552) is that genes belonging to these sets are evolving under "single-copy control" where something about their necessity and dosage constraints maintains them at a single copy within the genome.

If a newly assembled genome or transcriptome is missing genes from the corresponding BUSCO set, something may have gone wrong with sequencing/assembly/annotation/etc, and other genes may also be missing.

-----

### How are BUSCOs made? <img src="figures/stork2.png" alt="busco_figure" width="30%" align="right"/>

1. Selection: Single-copy orthologs present in at least 90% of species in a specific group are selected from OrthoDB.

1. Model Building: Multiple sequence alignments of protein sequences from each BUSCO group are generated and used to build a hidden Markov model (HMM) for the group.

1. Pruning: Sequences are then searched against the library of HMM profiles to remove any that cannot reliably distinguish members of their group from other sequences.

1. Parameter Optimization: "expected-score" and "expected-length" classification cut-offs are calculated for each BUSCO group based on the distribution of HMM search scores and lengths for members of the group. These cut-offs well be used to classify new proteins as members of the group.

1. Consensus sequences and Block profiles (position-specific frequency matrices) for each BUSCO are then created.


-----

### How are genomes/transcriptomes assessed?

1. Consensus sequences for each BUSCO are searched against the genome sequence using tBLASTn. Regions containing potential BUSCOs are identified. Up to three candidate genomic regions can be identified for each BUSCO. 

1. Candidate regions are extracted from the genome and [AUGUSTUS/Augustus](http://augustus.gobics.de/) in combination with the BUSCO block porfile is used for gene prediction. For transcriptomes,the protein prediction is used directly if available, otherwise the longest ORF within the transcript is used.

1. Each predicted gene is then matched against the BUSCO group's HMM profile, sequences meeting the minimum alignment cut-off are considered orthologous.

1. Orthologous sequences are then evaluated based on the expected-length cutoff. Sequences are classified as "Complete" if they meet the length cutoff, or "Fragmented" if too short. If multiple sequences meet the alignment and length cutoff they are classified as "Duplicated". Any BUSCO without Complete, Fragmented, or Duplicated sequence is "Missing".

1. Finally, "Complete" sequences are used to build a new gene prediction model for Augustus. A second round of Augustus gene prediction is then performed on all BUSCO-matching candidate regions that did not yield a "Complete" ortholog. Classification is then carried out a second time on the new set of predicted genes.

--------

BUSCO scores and contiguity as defined by N50 are not well correlated:

<img src="figures/Busco_vs_N50.png" alt="Busco_vs_N50" width="50%"/>

[Simão et al. 2015](https://academic.oup.com/bioinformatics/article/31/19/3210/211866)


---------

### Lets try it out on some assemblies!

But first we need to set up BUSCO.

#### Create an interactive session:
```bash
srun -t 03:00:00 -c 20 -n 1 --mem 16000 --partition production \
    --account genome_workshop --reservation genome_workshop --pty /bin/bash
aklog 
source ~/.bashrc

```

### Get access to BUSCO:

#### Option 1 Run BUSCO using modules 

```bash
cd /share/workshop/genome_assembly/$USER/busco

module load busco/4.0.2

cp -r /share/biocore/shunter/2020-Genome_Assembly_Workshop/busco/augustus.config /share/workshop/genome_assembly/$USER/busco/
export AUGUSTUS_CONFIG_PATH=/share/workshop/genome_assembly/$USER/busco/augustus.config

cp /share/biocore/shunter/2020-Genome_Assembly_Workshop/busco/busco_config.ini /share/workshop/genome_assembly/$USER/busco/
export BUSCO_CONFIG_FILE=/share/workshop/genome_assembly/$USER/busco/busco_config.ini

cp /share/biocore/shunter/2020-Genome_Assembly_Workshop/busco/generate_plot.py /share/workshop/genome_assembly/$USER/busco/


```
-------

#### Option 2 Install BUSCO using Conda

This option is for patient people or people who need to install BUSCO on a system where no module is available.

*Note that if you go this route, you will not need to set environment variables or copy generate_plot.py as in Option 1.*

```bash
mkdir -p /share/workshop/genome_assembly/$USER/busco
cd /share/workshop/genome_assembly/$USER/busco
```

##### Download miniconda:

See: https://docs.conda.io/en/latest/miniconda.html for more details

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
```

##### Install it to your workshop folder:

```bash
sh Miniconda3-latest-Linux-x86_64.sh -b -p /share/workshop/genome_assembly/$USER/busco/miniconda
```

#### Activate this new Conda install:

```bash
eval "$(/share/workshop/genome_assembly/$USER/busco/miniconda/bin/conda shell.bash hook)"
```

#### Add some channels, update Conda:

```bash
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda update --all
```

#### Create a new environment and install Busco:

Note that this step can take **a very long time** because Busco has a large number of dependencies. This set also sets the AUGUSTUS_CONFIG_PATH and BUSCO_CONFIG_FILE environment variables.

```bash
conda create -n busco_env
conda activate busco_env
conda install busco=4.0.6
```

----------

#### Now that Busco is activated/installed, lets try it out. 

First we need a genome to test on. Lets start with a small bacterial one.

The following code block symlinks in some raw Illumina reads and does some basic read clean up with [HTStream](https://github.com/s4hts/HTStream/issues).

```bash
# NOTE: Create an interactive session on the cluster if you closed the previous one.
cd /share/workshop/genome_assembly/$USER/busco
mkdir -p bacterial_test
cd bacterial_test

# Setup Raw Data
mkdir 00-RawData
ln -s /share/biocore/shunter/bacteria/*.gz ./00-RawData/

# Clean reads:
module load htstream/1.3.1
mkdir -p 01-HTS_Preproc

hts_Stats -L 01-HTS_Preproc/Bacteria.json -1 00-RawData/Bacteria_R1.fastq.gz -2 00-RawData/Bacteria_R2.fastq.gz | \
hts_SuperDeduper -A 01-HTS_Preproc/Bacteria.json | \
hts_SeqScreener -A 01-HTS_Preproc/Bacteria.json | \
hts_AdapterTrimmer -A 01-HTS_Preproc/Bacteria.json | \
hts_Stats -A 01-HTS_Preproc/Bacteria.json -F -f 01-HTS_Preproc/Bacteria

```

Next we assemble the cleaned reads with [Spades](http://cab.spbu.ru/software/spades/) and look at the assembly stats.

```bash
module load spades/3.13.0
spades.py -t 15 -1 01-HTS_Preproc/Bacteria_R1.fastq.gz -2 01-HTS_Preproc/Bacteria_R2.fastq.gz -o 02-SpadesAssembly

module load assembly_stats/1.0.1

assembly_stats ./02-SpadesAssembly/contigs.fasta
```

```
stats for ./02-SpadesAssembly/contigs.fasta
sum = 1113800, n = 60, ave = 18563.33, largest = 389847
N50 = 82313, n = 3
N60 = 75116, n = 5
N70 = 54132, n = 6
N80 = 37018, n = 9
N90 = 12161, n = 15
N100 = 128, n = 60
N_count = 0
Gaps = 0
```

**Wow, an N50 of only 82Kb?**


#### Run BUSCO in genome assessment mode

We will use new features in BUSCO V4: better support for bacteria and archaea, auto-lineage selection, and automated download of reference datasets (all of which are very nice!). To speed things up we can ask Busco to only search the prokaryotic lineage using --auto-lineage-prok.

```bash 

busco -f -c 20 -m genome -i ./02-SpadesAssembly/contigs.fasta -o 03-Busco --auto-lineage-prok

```

```
        --------------------------------------------------
        |Results from dataset mycoplasmatales_odb10       |
        --------------------------------------------------
        |C:98.9%[S:98.3%,D:0.6%],F:1.1%,M:0.0%,n:174      |
        |172    Complete BUSCOs (C)                       |
        |171    Complete and single-copy BUSCOs (S)       |
        |1      Complete and duplicated BUSCOs (D)        |
        |2      Fragmented BUSCOs (F)                     |
        |0      Missing BUSCOs (M)                        |
        |174    Total BUSCO groups searched               |
        --------------------------------------------------
```

This isolate had previously been identified as *Mycoplasma ovipneumoniae* and Busco has identified it as part of the Mycoplasmatales family. The assembly looks like it captured almost all of the single copy genes. If we look into the Busco folders we can find some additional interesting information about the genome. Note that because this sample was a prokaryote Busco used [Prodigal](https://github.com/hyattpd/Prodigal) to do gene prediction instead of Augustus.


Alternatively we can also look through the BUSCO database and specify the lineage directly if we have a good identification for the sample:

```bash
busco --list-datasets

busco -f -c 20 -m genome -i ./02-SpadesAssembly/contigs.fasta -o 03-Busco_lineage --lineage_dataset mycoplasmatales_odb10

```

Finally we can generate the canonical BUSCO plot using a script that comes with the BUSCO package. However we need to install the ggplot2 package in R first.

Start R and run (answer yes to install the package to your personal library):

```R
install.packages("ggplot2")
q(save="no")
```

Next, copy the summary files and make the plot:

```bash
mkdir -p short_summaries
cp ./03-Busco/short_summary.* ./short_summaries/ 
cp ./03-Busco_lineage/short_summary.* ./short_summaries/
python3 /share/workshop/genome_assembly/$USER/busco/generate_plot.py -wd ./short_summaries/

```

<img src="figures/busco_figure.png" alt="busco_figure" width="80%"/>

Note that each of the summary files has been incorporated in the plot. This may be helpful in comparing different assemblies.


---------



#### Test Busco on the *Drosophila* HiFi assemblies.

Additional assemblies were built with:
1. Shasta version 0.5.1 using command:
    * shasta --input ELF_19kb.m64001_190914_015449.Q20.28X.fasta
1. Flye v2.7.1 using command:
    * python ./Flye/bin/flye -t 40 --pacbio-hifi ELF_19kb.m64001_190914_015449.Q20.28X.fasta --out-dir flyeasm

Note that we will be using the "diptera_odb10" reference since _Drosophila melanogaster_ is in order _Diptera_.


**EXTRA CREDIT**: calculate assembly statistics for each of the following sets of contigs. Given that the haploid genome size is 139.5Mb with three autosomes and a sex chromosome, what are your guesses about the BUSCO results?


```bash 
cd /share/workshop/genome_assembly/$USER/busco/

mkdir -p drosophila_test
cd drosophila_test
```



Next copy the summary files and make the plot:

```bash
mkdir -p short_summaries
cp ./03-Busco/short_summary.* ./short_summaries/ 
cp ./03-Busco_lineage/short_summary.* ./short_summaries/
python3 /share/workshop/genome_assembly/$USER/busco/generate_plot.py -wd ./short_summaries/

```


/share/workshop/genome_assembly/pacbio_2020_data_drosophila/hifi_long_read_data





Make sure our workspace is setup properly
```bash
mkdir -p /share/workshop/genome_assembly/$USER
cd /share/workshop/genome_assembly/$USER
```

Assembly:
/share/workshop/genome_assembly/pacbio_2020_data_drosophila/hifi_long_read_diploid_ipa_assembly/RUN/14-final

Final:
/share/workshop/genome_assembly/pacbio_2020_data_drosophila/purge_dup_asm

# K-mer frequency plots

We can use K-mers (sequences of length K) to estimate biases, repeat content, sequencing coverage, and heterozygosity.

It is always a good idea to plot K-mer frequencies to get a picture of the genome composition and sequencing coverage/quality. For example, haploid and diploid genomes have differing K-mer distributions.

<img src="figures/k-mer-plot-large.jpg" alt="k-mer-plot-large" width="80%"/>

The 31-mer histograms of paired-end sequence data. Each histogram shows a bimodal distribution typical of a diploid heterozygous genome. The relative fraction of the distribution under the left (haploid) peak is proportional to the genome heterozygosity. Using the relative proportions of the two peaks the genomes can be ranked by their heterozygosity.

    Kristian A. Stevens, Keith Woeste, Sandeep Chakraborty, Marc W. Crepeau, Charles A. Leslie, Pedro J. Martínez-García, Daniela Puiu, Jeanne Romero-Severson, Mark Coggeshall, Abhaya M. Dandekar, Daniel Kluepfel, David B. Neale, Steven L. Salzberg, Charles H. Langley, Genomic Variation Among and Within Six Juglans Species, G3: GENES, GENOMES, GENETICS July 1, 2018 vol. 8 no. 7 2153-2165. doi: 10.1534/g3.118.200030."

## What are K-mers

A **K-mer** is a substring of length K in a string of DNA bases. For example: All 2-mers of the sequence AATTGGCCG are AA, AT, TT, TG, GG, GC, CC, CG. Similarly, all 3-mers of the sequence AATTGGCCG are AAT, ATT, TTG, TGG, GGC, GCC, CCG. There are an exponentially increasing number of possible K-mers for increasing numbers of K. There are 16 possible 2-mers for DNA if we assume there are only 4 types of bases (A,T,G,C). The equation for the number of K-mers possible for a given K is then 4^K.

|Bases|K-mer size|Total possible kmers|
|---|---|---|
|4|1|4|
|4|2|16|
|4|3|64|
|4|4|256|
|4|5|1,024|
|4|6|4,096|
|4|7|16,384|
|4|8|65,536|
|4|9|262,144|
|4|10|1,048,576|
|4|…|…|
|4|21|4.4e+12|
|4|27|1.8e+16|
|4|31|4.6e+18|

As you can see, there are 64 possibilities for a 3-mer and over 4 Trillion possibilities for a 21-mer!

For a given sequence of length L,  and a K-mer size of K, the total k-mer’s possible will be given by ( L – k ) + 1

e.g. For the sequence of length of 14 , and a K-mer length of 8, the number of K-mer’s generated will be:

**GATCCTACTGATGC**

    n   = ( L - K ) + 1
        = (14 - 8 ) + 1
        = 7

**GATCCTAC,     ATCCTACT,     TCCTACTG,     CCTACTGA,     CTACTGAT,     TACTGATG,     ACTGATGC**

For shorter fragments, as in the above example, the total number of K-mers estimated is n = 7, which it is not close to actual fragment size of L which is 14 bps.  But for larger fragments , the total number of K-mer’s (n) provide a good approximation to the actual genome size. The following table tries to illustrate the approximation:

K=18		

|Genome Sizes| Total K-mers of k=18|% error in genome estimation
|---|---|---|
|L|N=(L-K)+1||
|100|83|17|
|1000|983|1.7|
|10000|9983|0.17|
|100000|99983|0.017|
|1000000|999983|0.0017

So for a genome size of 1 Mb and K-mer size of 18, the error between estimation and reality is only .0017%. Which is a very good approximation of actual size.

In choosing a K-mer size, it should be large enough to allow the K-mer to map uniquely to the genome. So the total available K-mers should be sufficiently larger than the genome size and therefor has the ability to store all the K-mers in the genome (a K-mer size of 21 is large enough for most genomes). However, too large K-mers leads to need for substantial computational resources, as well as producing more erroneous K-mers caused by sequencing errors. In other words, the higher error rate in the sequencing data, the smaller k-mer size should be used.

### Genome copies

A significant issue that we face in a real genome sequencing project is non-uniform coverage of genome. This is attributed to both technical and biological variables.

ex:  amplification bias of certain genomic regions during PCR (a step in preparation of Illumina sequencing libraries) [Technical] and presence of repetitive sequences in genome [Biological].

Extending the above example, if we had 10 copies (C) of 1Mb genome, then the total no of K-mer’s seen (n) of length k = 21 will be 9999700.

    n   = [( L - k ) + 1 ] * C
        = [(1000000 - 21 ) + 1] * 10
        = 9999700


To get the fragement size (ala genome size), we simply need to divide the total by the number of copies:

    L   = n / C
        = 9999700 / 10
        = 9999700

The above example helps to understand that we never sequence a single copy of genome but rather a population. Rather we end up sequencing C copies of genome. This is also referred as coverage in sequencing. To obtain actual genome size (N), divide the total K-mers seen (n) by coverage (C).

    N  = n / C

## Estimating genome characteristics

In the first step, a K-mer frequency is calculated. There are software tools that help in finding the K-mer frequency in sequencing projects. The K-mer frequency of a shotgun library follows a pseudo-normal distribution (actually it is a Poisson distribution) around the mean coverage.

### K-mer counting tools

* [Jellyfish](https://github.com/gmarcais/Jellyfish)
* [kmerfreq](https://github.com/fanagislab/kmerfreq)
* [KMC3](https://github.com/refresh-bio/KMC)
* [DSK](https://github.com/GATB/dsk)
* [KCMBT](https://github.com/abdullah009/kcmbt_mt)
* [BFCounter](https://github.com/pmelsted/BFCounter)
* [GenomeTester4](https://github.com/bioinfo-ut/GenomeTester4)

Once the K-mer frequencies are calculated a histogram can be plotted to visualize the distribution.

## Genomescope

Genomescope uses k-mer frequencies generated from raw read data to estimate the genome size, abundance of repetitive elements and rate of heterozygosity.

**Questions**
* *Any problematic samples?*

* *Anything else worth discussing?*
