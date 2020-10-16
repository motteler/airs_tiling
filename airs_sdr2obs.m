%
% NAME
%   new_obs_list - list selected AIRS obs
%
% SYNOPSIS
%   new_obs_list(year, dlist, ofile, opts)
%
% INPUTS
%   year   - integer year
%   dlist  - integer vector of days-of-the-year
%   ofile  - save file for obs lists
%   opts   - optional parameters
%
% DISCUSSION
%   derived from obs_source/airs_obs_list and the chrip script
%   umbc_airs_loop
%
% AUTHOR
%   H. Motteler, 1 Aug 2020
%

function new_obs_list(year, dlist, ofile)

% set up source paths
% addpath /home/motteler/cris/ccast/source
% addpath /home/motteler/cris/ccast/motmsc/time
% addpath /home/motteler/shome/airs_decon/source
  addpath /home/motteler/shome/chirp_test

% this function name
fstr = mfilename;  

% AIRS source 
airs_home = '/asl/airs/l1c_v672';
airs_year = fullfile(airs_home, sprintf('%d', year));

% default frequency list (LW and SW windows)
vlist = [902.040, 902.387, 2499.533, 2500.601];

% fixed AIRS parameters
nchan = 2645;  % L1c channels
nobs = 90 * 135;    % xtrack x atrack obs

% get L1c channel indices
d1 = load('airs_l1c_wnum');
ixv = interp1(d1.wnum, 1:nchan, vlist, 'nearest');
vlist = d1.wnum(ixv);

% initialize obs lists
rad_list = [];
lat_list = [];
lon_list = [];
tai93_list = [];
sat_zen_list = [];
sol_zen_list = [];
asc_flag_list = [];

% loop on days of the year
for di = dlist

  % add day-of-year to paths
  doy = sprintf('%03d', di);
  fprintf(1, '%s: processing %d doy %s\n', fstr, year, doy)
  airs_dir = fullfile(airs_year, doy);

  % check that the source path exists
  if exist(airs_dir) ~= 7
    fprintf(1, '%s: bad source path %s\n', fstr, airs_dir)
    continue
  end

  % loop on AIRS granules
  flist = dir(fullfile(airs_dir, 'AIRS*L1C*.hdf'));
  for fi = 1 : length(flist);
    airs_l1c = flist(fi).name;
    airs_gran = fullfile(airs_dir, airs_l1c);

    [d2, a2] = airs_flat(airs_gran);

    if isempty(d2), continue, end

    iOK = d2.rad_qc == 0;

%   % old latitude subsample
%   nxt = length(ixt);
%   lat_rad = deg2rad(lat);
%   jx = rand(nxt, 135) < abs(cos(lat_rad));
%   jx = jx & iOK;

    % add obs to lists
%   rad_list      = [rad_list,      d2.rad(ixv,iOK)];
    lat_list      = [lat_list;      d2.lat(iOK,1)];
    lon_list      = [lon_list;      d2.lon(iOK,1)];
    tai93_list    = [tai93_list;    d2.obs_time_tai93(iOK,1)];
    sat_zen_list  = [sat_zen_list;  d2.sat_zen(iOK,1)];
    sol_zen_list  = [sol_zen_list;  d2.sol_zen(iOK,1)];
    asc_flag_list = [asc_flag_list; d2.asc_flag(iOK,1)];

%   if mod(fi, 10) == 0, fprintf(1, '.'), end
  end % loop on granules
% fprintf(1, '\n')
end % loop on days

save(ofile, 'year', 'dlist', 'airs_home', 'ixv', 'vlist', ...
  'rad_list', 'lat_list', 'lon_list', 'tai93_list', 'sat_zen_list', ...
  'sol_zen_list', 'asc_flag_list');

