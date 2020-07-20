#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=1-0
#SBATCH --ntasks=16 # Number of cores
#SBATCH --mem=50000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --reservation=genome_workshop
#SBATCH --account=genome_workshop
#SBATCH --output=slurmout/anp-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/anp-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"


THREADS=${SLURM_NTASKS}

ID=$1

module load nanoplot/1.20.0

export baseP=/share/workshop/genome_assembly/${USER}/Nanopore
export outP=$baseP/01-Nanoplot
export fastqP=$baseP/02-QC

if [ ! -d $outP ]
then
  mkdir -p $outP
fi


call="NanoPlot -p $ID -t $THREADS -o $outP --fastq $fastqP/*.fastq"


echo $call
eval $call

end=`date +%s`
runtime=$((end - start))

echo $runtime

