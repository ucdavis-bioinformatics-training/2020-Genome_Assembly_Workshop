#!/bin/bash
#
#SBATCH --array=1-200
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=4 # Number of cores
#SBATCH --mem=10000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --reservation=jli.assembly.test
#SBATCH --output=slurmout/pc-%A-%a.out # File to which STDOUT will be written
#SBATCH --error=slurmout/pc-%A-%a.err # File to which STDERR will be written

start=`date +%s`
hostname

module load anaconda3/4.5.12
export PYTHONPATH=/share/biocore/projects/Internal_Jessie_UCD/software/Porechop-Jul2020/Porechop/lib/python3.6/site-packages/:$PYTHONPATH

export baseP=/share/workshop/genome_assembly/${USER}/Nanopore
export outP=$baseP/02-QC
export fastqP=$baseP/00-RawData

if [ ! -d "$outP" ]
then
  mkdir -p $outP
fi

READS=`head -n ${SLURM_ARRAY_TASK_ID} input.fofn | tail -1`
echo $READS


name=$(echo "$READS" |awk 'BEGIN{FS="\\/"}{print $NF}' - )
call="/share/biocore/projects/Internal_Jessie_UCD/software/Porechop-Jul2020/Porechop/bin/porechop \
	-i $READS --min_trim_size 6 -o $outP/${name} -t 4"

echo $call
eval $call


end=`date +%s`
runtime=$((end - start ))
echo $runtime


