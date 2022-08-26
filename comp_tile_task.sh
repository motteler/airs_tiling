#!/bin/bash
#
# usage: sbatch --array=<set_list>%1 comp_tile_task.sh
#
# <set_list> should count in ntasks steps, for example for ntasks=4,
# sbatch --array=53,57,61,65,69,73,77%1 comp_tile_task.sh

# sbatch options
#SBATCH --job-name=comp_tile
#SBATCH --partition=high_mem
# #SBATCH --partition=batch
# #SBATCH --constraint=lustre
# #SBATCH --constraint=hpcf2009
#SBATCH --qos=medium+
# #SBATCH --qos=short+
#SBATCH --account=pi_strow
#SBATCH --mem-per-cpu=26000
#SBATCH --oversubscribe
#SBATCH --ntasks=8
#SBATCH --ntasks-per-node=2
#SBATCH --time=14:00:00

# bad node list
# #SBATCH --exclude=cnode040

# matlab options
MATLAB=/usr/ebuild/software/MATLAB/2020a/bin/matlab
MATOPT='-nojvm -nodisplay -nosplash'

srun --output=comp_%A_%a_%t.out \
   $MATLAB $MATOPT -r "comp_tile_task; exit"

