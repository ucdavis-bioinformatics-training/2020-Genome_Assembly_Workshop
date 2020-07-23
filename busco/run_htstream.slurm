#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --time=10
#SBATCH --mem=2000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production
#SBATCH --account genome_workshop
#SBATCH --reservation genome_workshop
#SBATCH --output=slurmout/cleaning_%A_%a.out # File to which STDOUT will be written
#SBATCH --error=slurmout/cleaning_%A_%a.err # File to which STDERR will be written

start=`date +%s`
echo $HOSTNAME
echo "My SLURM_JOB_ID: " $SLURM_JOB_ID

module load htstream/1.3.1

outpath='01-HTS_Preproc'

if [ ! -d $outpath ]
then
  mkdir -p $outpath
fi

# Clean reads:
hts_Stats -L ${outpath}/Bacteria.json -1 00-RawData/Bacteria_R1.fastq.gz -2 00-RawData/Bacteria_R2.fastq.gz | \
hts_SeqScreener -A ${outpath}/Bacteria.json | \
hts_AdapterTrimmer -A ${outpath}/Bacteria.json | \
hts_SuperDeduper -A ${outpath}/Bacteria.json | \
hts_Stats -A ${outpath}/Bacteria.json -F -f ${outpath}/Bacteria

# Assemble:
module load spades/3.13.0
spades.py -t 24 -1 ${outpath}/Bacteria_R1.fastq.gz -2 ${outpath}/Bacteria_R2.fastq -o 03-SpadesAssembly


