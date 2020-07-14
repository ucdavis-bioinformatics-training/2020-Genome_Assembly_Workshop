#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=3-0
#SBATCH --ntasks=16 # Number of cores
#SBATCH --mem=120000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --output=slurmout/mk-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/mk-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"


THREADS=${SLURM_NTASKS}


aklog
module load medaka/1.0.3
module load minimap2/2.17
module load samtools/1.9
source activate medaka-1.0.3

hostname

export baseP=/share/biocore/workshops/Genome-Assembly-Workshop-Jun2020/Nanopore
export asmP=$baseP/03-RACON
export seqP=$baseP/01-QC
export outP=$baseP/04-MEDAKA

if [ ! -d "$outP" ]
then
  mkdir -p $outP
fi



medaka_consensus -i $asmP/input.fq -d $asmP/racon.polished.fa -o $outP -t ${THREADS} -m r941_prom_high_g303 -f -t ${THREADS}


end=`date +%s`
runtime=$((end - start ))
echo $runtime


