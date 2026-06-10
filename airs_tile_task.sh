#!/bin/bash
#
# usage: sbatch --array=<set_list>%1 airs_tile_task.sh
#
# <set_list> should count in ntasks steps, for example for ntasks=8,
# sbatch --array=9,17,25,33,41%1 airs_tile_task.sh

# sbatch options
#SBATCH --job-name=airs_tile
#SBATCH --partition=cpu2021
# #SBATCH --partition=high_mem
# #SBATCH --partition=batch
# #SBATCH --constraint=lustre
# #SBATCH --constraint=hpcf2009
#SBATCH --qos=medium+
# #SBATCH --qos=short+
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=26000
#SBATCH --oversubscribe
# #SBATCH --ntasks=8
# #SBATCH --ntasks-per-node=2
#SBATCH --ntasks=3
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00

# bad node list
# #SBATCH --exclude=cnode021

# matlab options
MATLAB=/usr/ebuild/software/MATLAB/2020a/bin/matlab
# MATLAB=/usr/ebuild/software/MATLAB/2021b/bin/matlab
MATOPT='-nojvm -nodisplay -nosplash'

srun --output=tile_%A_%a_%t.out \
   $MATLAB $MATOPT -r "airs_tile_task; exit"

