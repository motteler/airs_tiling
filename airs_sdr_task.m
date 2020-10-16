%
% airs_sdr_task - batch wrapper for airs_sdr2obs and airs_sdr2tab
%

function airs_sdr_task

addpath ../source
addpath /asl/packages/ccast/source
addpath /asl/packages/ccast/motmsc/time

jobid = str2num(getenv('SLURM_JOB_ID'));          % job ID
jarid = str2num(getenv('SLURM_ARRAY_TASK_ID'));   % job array ID
procid = str2num(getenv('SLURM_PROCID'));         % relative process ID
nprocs = str2num(getenv('SLURM_NTASKS'));         % number of tasks
nodeid = sscanf(getenv('SLURMD_NODENAME'), '%s'); % node name

taskid = procid;
year   = jarid;

fprintf(1, 'airs_sdr_task: year %d taskid %d node %s\n', year, taskid, nodeid);

% taskid is the 16-day set number
if ~(1 <= taskid & taskid <= 23)
  error('set index out of range')
end

% take 16-day set number to doy list
if ~isleap(year), yend = 365; else, yend = 366; end
dlist = (taskid - 1) * 16 + 1 : taskid * 16;
if dlist(end) > yend
  dlist = dlist(1) : yend;
end

% set the output filename 
tfile = sprintf('airs_map_all_y%ds%0.2d', year, taskid);

% run the target script
% airs_sdr2tab(year, dlist, tfile)

% only for tests
display(tfile)
pause(5)



