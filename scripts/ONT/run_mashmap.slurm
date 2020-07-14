#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=3:00:00
#SBATCH --ntasks=16 # Number of cores
#SBATCH --mem=20000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --output=slurmout/msm-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/msm-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"


THREADS=${SLURM_NTASKS}


export baseP=/share/biocore/workshops/Genome-Assembly-Workshop-Jun2020/Nanopore
export asmP=$baseP/02-SHASTA
export outP=$baseP/03-Mashmap
export PATH=/share/biocore/projects/Internal_Jessie_UCD/software/MashMap/:$PATH

if [ ! -d $outP ]
then
  mkdir -p $outP
fi


# align assembly with kmer=10 and assembly with kmer=12
call="mashmap -r $asmP/run1/Assembly.fasta -q $asmP/run2/Assembly.fasta -t 16 -o $outP/kmer10.vs.kmer12.out --perc_identity 95"


echo $call
eval $call

end=`data +%s`

runtime=$((end-start))

echo $runtime
