#!/bin/bash
#
# usage: sbatch --array=<year_list>%1 airs_sdr_task.sh
#

# sbatch options
#SBATCH --job-name=airs_scan
#SBATCH --partition=high_mem
# #SBATCH --partition=batch
# #SBATCH --constraint=lustre
# #SBATCH --constraint=hpcf2009
# #SBATCH --qos=medium+
#SBATCH --qos=short+
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=24000
#SBATCH --oversubscribe
#SBATCH --ntasks=23
#SBATCH --ntasks-per-node=4

# bad node list
#SBATCH --exclude=cnode021

# matlab options
MATLAB=/usr/ebuild/software/MATLAB/2020a/bin/matlab
MATOPT='-nojvm -nodisplay -nosplash'

srun --output=airs_%A_%a.out \
   $MATLAB $MATOPT -r "airs_sdr_task; exit"

