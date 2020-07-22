#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --time=120
#SBATCH --mem=2000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production
#SBATCH --output=slurmout/cleaning_%A_%a.out # File to which STDOUT will be written
#SBATCH --error=slurmout/cleaning_%A_%a.err # File to which STDERR will be written

start=`date +%s`
echo $HOSTNAME
echo "My SLURM_JOB_ID: " $SLURM_JOB_ID

module load spades/3.13.0

outpath='01-HTS_Preproc'

if [ ! -d $outP ]
then
  mkdir -p $outP
fi

hts_Stats -L ${outpath}/${sample}.log -1 00-RawData/${sample}_R1.fastq.gz -2 00-RawData/${sample}_R2.fastq.gz | \
hts_SeqScreener -A ${outpath}/${sample}.log | \
hts_AdapterTrimmer -A ${outpath}/${sample}.log | \
hts_SuperDeduper -A ${outpath}/${sample}.log | \
hts_Stats -A ${outpath}/${sample}.log -F -f ${outpath}/${sample}
