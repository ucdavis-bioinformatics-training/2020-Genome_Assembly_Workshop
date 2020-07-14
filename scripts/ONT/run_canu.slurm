#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=10-0
#SBATCH --ntasks=2 # Number of cores
#SBATCH --mem=10g # total memory required
#SBATCH --partition=production # Partition to submit to
#SBATCH --output=slurmout/cn-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/cn-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"

module load canu/1.8

THREADS=${SLURM_NTASKS}


export baseP=/share/workshop/genome_assembly/${USER}/Nanopore
export outP=$baseP/03-CANU
export fastqP=$baseP/02-QC

if [ ! -d $outP ]
then
  mkdir -p $outP
fi



call='canu -p asm -d $outP useGrid=true gridOptions="--cpus-per-task=8 --mem-per-cpu=4g -p production --time=2-12" genomeSize=280m -nanopore-raw $fastqP/*.fastq'

echo $call
eval $call


end=`date +%s`
runtime=$((end - start ))
echo $runtime


