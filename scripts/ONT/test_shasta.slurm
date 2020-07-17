#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=3-0
#SBATCH --ntasks=32 # Number of cores
#SBATCH --mem=500000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --reservation=jli.assembly.test
#SBATCH --output=slurmout/test-sta-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/test-sta-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"


THREADS=${SLURM_NTASKS}


export baseP=/share/workshop/genome_assembly/${USER}/Nanopore
export outP=$baseP/03-SHASTA-test
export toolsP=/share/biocore/projects/Internal_Jessie_UCD/software
export fastq=$baseP/02-QC



if [ ! -d $outP ]
then
  mkdir -p $outP
fi


# marker kmer=10, the default
call="$toolsP/shasta-Linux-0.5.0 --assemblyDirectory $outP/run1 --command assemble --threads $THREADS --input $fastqP/*.fastq"

echo $call
eval $call



end=`date +%s`
runtime=$((end - start ))
echo $runtime


