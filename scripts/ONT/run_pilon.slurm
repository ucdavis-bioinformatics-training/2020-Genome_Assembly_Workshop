#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=3-0
#SBATCH --ntasks=32 # Number of cores
#SBATCH --mem=200000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --reservation=genome_workshop
#SBATCH --account=genome_workshop
#SBATCH --output=slurmout/pln-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/pln-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"


THREADS=${SLURM_NTASKS}


aklog
module load bwa/0.7.16a
module load samtools/1.9
module load pilon/1.23

export PILON_JAVAOPTS=-Xmx180g

hostname

export baseP=/share/workshop/genome_assembly/${USER}/Nanopore
export seqP=$baseP/00-RawData/Illumina
export outP=$baseP/06-PILON
export asmP=$baseP/05-MEDAKA-Linked

if [ ! -d "$asmP" ]
then
  mkdir -p $baseP/05-MEDAKA-Linked
fi

ln -s /share/workshop/genome_assembly/jli/Nanopore/05-MEDAKA/consensus.fasta $baseP/05-MEDAKA-Linked/.


if [ ! -d "$outP" ]
then
  mkdir -p $outP
fi

THREADS=${SLURM_NTASKS}

# index medaka polished assembly for bwa
bwa index $asmP/consensus.fasta

name="Illumina"

# align Illumina reads to medaka polished assembly
bwa mem -t ${THREADS} -M -B 8 $asmP/consensus.fasta <(zcat $seqP/*_R1_001.fastq.gz) <(zcat $seqP/*_R2_001.fastq.gz) |samtools view - -Sb |samtools sort - -@ 12 -m 20G -o $outP/${name}.sorted.bam 2> $outP/${name}.log

samtools index $outP/${name}.sorted.bam

# run pilon polishing snps/indels
pilon --genome $asmP/consensus.fasta --frags $outP/${name}.sorted.bam --output pilon.polished --outdir $outP --vcf --changes --fix bases --threads 48 --minmq 30 --minqual 30 


end=`date +%s`
runtime=$((end - start ))
echo $runtime


