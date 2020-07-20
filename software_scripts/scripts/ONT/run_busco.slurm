#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=3-0
#SBATCH --ntasks=24 # Number of cores
#SBATCH --mem=80000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --reservation=genome_workshop
#SBATCH --account=genome_workshop
#SBATCH --output=slurmout/bsc-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/bsc-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"

module load busco/4.0.2
module load prodigal/2.6.3
module load augustus/3.3.2
module load hmmer/3.1b2

export AUGUSTUS_CONFIG_PATH=/share/workshop/genome_assembly/jli/Nanopore/Augustus/config

export baseP=/share/workshop/genome_assembly/${USER}/Nanopore
export outP=$baseP/08-BUSCO
export asm1P=/share/workshop/genome_assembly/jli/06-PILON

if [ ! -d $outP ]
then
  mkdir -p $outP
fi

#cp /share/workshop/genome_assembly/jli/Nanopore/scripts/config.ini /share/workshop/genome_assembly/${USER}/Nanopore/scripts/
export BUSCO_CONFIG_FILE=$baseP/scripts/config.ini

cd $outP
ln -s /share/workshop/genome_assembly/jli/Nanopore/06-PILON/pilon.polished.fasta .
## run busco for assembly before purge haplotigs
busco -i pilon.polished.fasta -o assembly.before.purge -l embryophyta_odb10 -m genome -c 24 --augustus_species arabidopsis -f


end=`date +%s`
runtime=$((end - start ))
echo $runtime


