%
% comp_tile_task - batch wrapper for comp_tiles
%

function comp_tile_task

more off
addpath /asl/packages/ccast/source
addpath /asl/packages/ccast/motmsc/time

jarid = str2num(getenv('SLURM_ARRAY_TASK_ID'));    % job array ID
procid = str2num(getenv('SLURM_PROCID'));          % relative process ID
nprocs = str2num(getenv('SLURM_NTASKS'));          % number of tasks
nodeid = sscanf(getenv('SLURMD_NODENAME'), '%s');  % node name

% get the 16-day set for this task.  jarid is from the job array
% spec, while procid is 0 to nprocs-1

iset = jarid + procid;

fprintf(1, 'comp_tile_task: set %d node %s\n', iset, nodeid);
fprintf(1, 'comp_tile_task: jarid %d procid %d nprocs %d\n', ...
  jarid, procid, nprocs)

% specify the output directory
thome = '/asl/isilon/airs/tile_test7';

% run the target script
comp_tiles(iset, thome);

