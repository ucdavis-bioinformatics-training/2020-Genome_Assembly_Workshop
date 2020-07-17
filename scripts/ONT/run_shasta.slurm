#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=3-0
#SBATCH --ntasks=48 # Number of cores
#SBATCH --mem=400000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --reservation=genome_workshop
#SBATCH --account=genome_workshop
#SBATCH --output=slurmout/sta-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/sta-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"


THREADS=${SLURM_NTASKS}


export baseP=/share/workshop/genome_assembly/${USER}/Nanopore
export outP=$baseP/03-SHASTA
export toolsP=/share/biocore/projects/Internal_Jessie_UCD/software

finished=$1

if [ $finished == "NO" ]
then
  export fastqP=$baseP/02-QC-Linked
  mkdir -p $fastqP
  ln -s /share/workshop/genome_assembly/jli/Nanopore/02-QC/* /share/workshop/genome_assembly/${USER}/Nanopore/02-QC-Linked/
else
  export fastqP=$baseP/02-QC
fi


if [ ! -d $outP ]
then
  mkdir -p $outP
fi


# marker kmer=10, the default
call="$toolsP/shasta-Linux-0.5.0 --assemblyDirectory $outP/run1 --command assemble --threads $THREADS --input $fastqP/*.fastq"

echo $call
eval $call


## if you want to try to use different kmer size then uncomment the following commands.
## but please be advised that this will triple the run time, which will be just below 3 hours on a 32 cpu usage.
## marker kmer=12
#call="$toolsP/shasta-Linux-0.5.0 --assemblyDirectory $outP/run2 --command assemble --Kmers.k 12 --threads $THREADS --input $fastqP/*.fastq"

#echo $call
#eval $call

## marker kmer=8
#call="$toolsP/shasta-Linux-0.5.0 --assemblyDirectory $outP/run3 --command assemble --Kmers.k 8 --threads $THREADS --input $fastqP/*.fastq"

#echo $call
#eval $call

end=`date +%s`
runtime=$((end - start ))
echo $runtime


