#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=3-0
#SBATCH --ntasks=4 # Number of cores
#SBATCH --mem=80000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --reservation=genome_workshop
#SBATCH --account=genome_workshop
#SBATCH --output=slurmout/mm-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/mm-%N-%j.err # File to which STDERR will be written

hostname

start=`date +%s`

echo "My SLURM_JOB_ID: $SLURM_JOB_ID"

module load mummer/4.0.0beta2


export baseP=/share/workshop/genome_assembly/${USER}/Nanopore
export shastaP=$baseP/05-MEDAKA-Linked
export canuP=$baseP/03-CANU-Linked
export outP=$baseP/06-Mummer

mkdir -p $shastaP
mkdir -p $canuP

ln -s /share/workshop/genome_assembly/jli/Nanopore/05-MEDAKA/consensus.fasta $shastaP/.
ln -s /share/workshop/genome_assembly/jli/Nanopore/03-CANU/asm.contigs.fasta $canuP/. 


## canu assembly vs. polished shasta assembly
call="nucmer --maxmatch -p $outP/canu.vs.shasta $canuP/asm.contigs.fasta $shastaP/consensus.fasta"

echo $call
eval $call


call="mummerplot --filter --layout -p $outP/canu.vs.shasta -l $outP/canu.vs.shasta.delta"

echo $call
eval $call

sed -i 's/^set mouse/#set mouse/g' $outP/canu.vs.shasta.gp
sed -i 's/^if/#if/g' $outP/canu.vs.shasta.gp

gnuplot $outP/canu.vs.shasta.gp > $outP/canu.vs.shasta.png


end=`date +%s`
runtime=$((end - start ))
echo $runtime


