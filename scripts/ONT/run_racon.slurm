#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=3-0
#SBATCH --ntasks=24 # Number of cores
#SBATCH --mem=120000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --output=slurmout/rc-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/rc-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"


THREADS=${SLURM_NTASKS}


aklog
module load racon/1.4.3
module load minimap2/2.17
module load samtools/1.9
hostname

export baseP=/share/biocore/workshops/Genome-Assembly-Workshop-Jun2020/Nanopore
export asmP=$baseP/02-SHASTA
export seqP=$baseP/01-QC
export outP=$baseP/03-RACON

if [ ! -d "$outP" ]
then
  mkdir -p $outP
fi

## align
#minimap2 -t ${THREADS} -a $asmP/run3/Assembly.fasta $seqP/*.fastq |samtools sort -@ ${THREADS} -m 10G -O SAM -o $outP/minialign.sorted.sam - 
#cat $seqP/Set*/*.fastq > $outP/input.fq

cd $outP
racon -m 8 -x -6 -g -8 -w 500 -t ${THREADS} -u ./input.fq ./minialign.sorted.sam $asmP/run3/Assembly.fasta > racon.polished.fa



end=`date +%s`
runtime=$((end - start ))
echo $runtime


