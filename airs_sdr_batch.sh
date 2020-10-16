#!/bin/bash
#
# usage: sbatch airs_sdr_batch.sh <year>
#

# sbatch options
#SBATCH --job-name=airs_sdr
#SBATCH --partition=high_mem
# #SBATCH --partition=batch
# #SBATCH --constraint=hpcf2009
#SBATCH --qos=medium+
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=24000
#SBATCH --oversubscribe
# #SBATCH --array=16-23%3
#SBATCH --array=1-16%4
# #SBATCH --array=1-23%6

# bad node list
#SBATCH --exclude=cnode021

# scheduling exclude list
#SBATCH --exclude=cnode006

# matlab options
MATLAB=/usr/ebuild/software/MATLAB/2020a/bin/matlab
MATOPT='-nojvm -nodisplay -nosplash'

srun --output=airs_$1_%A_%a.out \
   $MATLAB $MATOPT -r "airs_sdr_batch($1); exit"

