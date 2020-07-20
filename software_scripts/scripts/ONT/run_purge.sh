#!/bin/bash
#

finished=$1

jid1=$(sbatch -J pgm.${USER} run_purge_map.slurm ${finished} |cut -d' ' -f4)

if [ "$jid1" != "" ]
then
  jid2=$(sbatch -J pgp.${USER} --dependency=afterok:$jid1 run_purge_purge.slurm ${finished} |cut -d' ' -f4)
else
  echo "something is wrong"
fi

