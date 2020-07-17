#!/bin/bash
#
#SBATCH --array=1-200
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1 # Number of cores
#SBATCH --mem=2000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --reservation=genome_workshop
#SBATCH --account=genome_workshop
#SBATCH --output=slurmout/prg-map-%A-%a.out # File to which STDOUT will be written
#SBATCH --error=slurmout/prg-map-%A-%a.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"

module load purge_dups/ca23030
module load anaconda3/4.5.12
module load minimap2/2.17


export baseP=/share/workshop/genome_assembly/${USER}/Nanopore
export outP=$baseP/07-PurgeHaplotigs
export seqP=$baseP/02-QC

if [ ! -d $outP ]
then
  mkdir -p $outP
fi

finished=$1

if [ $finished == "NO" ]
then
  export asmP=$baseP/06-PILON-Linked
  mkdir $asmP
  ln /share/workshop/genome_assembly/jli/Nanopore/06-PILON/pilon.polished.fasta $asmP/.
else
  export asmP=$baseP/06-PILON
fi


file=`sed "${SLURM_ARRAY_TASK_ID}q;d" input.fofn`

minimap2 -x map-ont $asmP/pilon.polished.fasta $file | gzip -c - > $outP/${SLURM_ARRAY_TASK_ID}.paf.gz


end=`date +%s`
runtime=$((end - start ))
echo $runtime


