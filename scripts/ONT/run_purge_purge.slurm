#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --time=2:00:00
#SBATCH --ntasks=2 # Number of cores
#SBATCH --mem=40000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production # Partition to submit to
#SBATCH --reservation=genome_workshop
#SBATCH --account=genome_workshop
#SBATCH --output=slurmout/prg-pg-%N-%j.out # File to which STDOUT will be written
#SBATCH --error=slurmout/prg-pg-%N-%j.err # File to which STDERR will be written

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
else
  export asmP=$baseP/06-PILON
fi


cd $outP
/software/purge_dups/ca23030/lssc0-linux/bin/pbcstat *.paf.gz
/software/purge_dups/ca23030/lssc0-linux/bin/calcuts PB.stat > cutoffs 2> calcults.log

minimap2 -x asm5 $asmP/pilon.polished.fasta $asmP/pilon.polished.fasta | gzip -c - > $outP/asm.self.paf.gz

python3 /software/purge_dups/1.0.1/lssc0-linux/scripts/hist_plot.py -x 2 PB.stat PB.coverage.png

/software/purge_dups/ca23030/lssc0-linux/bin/purge_dups -T cutoffs -c PB.base.cov asm.self.paf.gz > dups.bed 2> purge_dups.log
/software/purge_dups/ca23030/lssc0-linux/bin/get_seqs -l 500 dups.bed pilon.polished.fasta > haplotype.fasta



end=`date +%s`
runtime=$((end - start ))
echo $runtime


