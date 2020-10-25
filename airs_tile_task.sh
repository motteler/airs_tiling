#!/bin/bash
#
# usage: sbatch --array=<set_list>%1 airs_tile_task.sh
#
# <set_list> should count in ntasks steps, for example
# sbatch --array=9,13,17,21%1 airs_tile_task.sh

# sbatch options
#SBATCH --job-name=airs_tile
#SBATCH --partition=high_mem
# #SBATCH --partition=batch
# #SBATCH --constraint=lustre
# #SBATCH --constraint=hpcf2009
#SBATCH --qos=medium+
# #SBATCH --qos=short+
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=24000
#SBATCH --oversubscribe
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=2

# bad node list
#SBATCH --exclude=cnode021

# matlab options
MATLAB=/usr/ebuild/software/MATLAB/2020a/bin/matlab
MATOPT='-nojvm -nodisplay -nosplash'

srun --output=tile_%A_%a_%t.out \
   $MATLAB $MATOPT -r "airs_tile_task; exit"

