#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=3-0
#SBATCH --ntasks=24 # Number of cores
#SBATCH --mem=120000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --output=slurmout/mk-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/mk-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"


THREADS=${SLURM_NTASKS}


aklog
module load bwa/0.7.16a
module load samtools/1.9
module load pilon/1.23

export PILON_JAVAOPTS=-Xmx120g

hostname

export baseP=/share/biocore/workshops/Genome-Assembly-Workshop-Jun2020/Nanopore
export asmP=$baseP/04-MEDAKA
export seqP=$baseP/00-RawData/Illumina
export outP=$baseP/05-PILON

if [ ! -d "$outP" ]
then
  mkdir -p $outP
fi

THREADS=${SLURM_NTASKS}

# index medaka polished assembly for bwa
bwa index $asmP/consensus.fasta

# align Illumina reads to medaka polished assembly
bwa mem -t ${THREADS} -M -B 8 $asmP/consensus.fasta <(zcat $seqP/*_R1_001.fastq.gz) <(zcat $seqP/*_R2_001.fastq.gz) |samtools view - -Sb |samtools sort - -@ 12 -m 20G -o $outP/${name}.sorted.bam 2> $outP/${name}.log

samtools index $outP/${name}.sorted.bam

# run pilon polishing snps/indels
pilon --genome $asmP/consensus.fasta --frags $outP/${name}.sorted.bam --output pilon.polished --outdir $outP --vcf --fix bases --threads 48 --minmq 30 --minqual 30 


end=`date +%s`
runtime=$((end - start ))
echo $runtime


