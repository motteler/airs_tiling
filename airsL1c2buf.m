%
% NAME
%   airsL1c2buf - AIRS buffered tiling main function
%
% SYNOPSIS
%   airsL1c2buf(iset, thome)
%
% INPUTS
%   iset   - 16-day set number
%   thome  - output tree home
%
% NOTES
%   airsL1c2buf takes a 16-day set number and loops on the relevant
%   days, granules, and obs within a granule.  It calls write_buf
%   for each obs.  write_buf saves the obs in one of a set buffers.
%   When a buffer is full or has aged out due to not being used for
%   a while, the values there are written to the appropriate tile
%   file.  There are many more tiles than buffers, and as buffers
%   age out they are assigned to new tiles.
%
% AUTHOR
%   H. Motteler, 10 Oct 2020
%
% EDITS
%   1 Feb 2022: modified to change AIRS source directory after 
%   the 23 Sep 2021 (doy 266) calibration shift

function airsL1c2buf(iset, thome)

% set up source paths
addpath /home/motteler/shome/chirp_test
addpath /home/motteler/cris/ccast/motmsc/utils
addpath /home/motteler/cris/ccast/motmsc/time
addpath /home/motteler/cris/ccast/source

% start runtime clock
tic  

% this function name
fstr = mfilename;

% initial empty netCDF file
nc_init = './airs_tile.nc';

% get latitude bands
% dLat = 3;
% latB = -90 : dLat : 90;    
d1 = load('latB64');
latB = d1.latB2;  
nlat = length(latB) - 1;

% get longitude bands
dLon = 5;
lonB = -180 : dLon : 180;
nlon = length(lonB) - 1;

% AIRS source 
airs_home1 = '/asl/airs/l1c_v672';  % before 23 Sep 2021
airs_home2 = '/asl/airs/l1c_v674';  % after  23 Sep 2021

% fixed AIRS parameters
nchan = 2645;     % L1c channels
nobs = 90 * 135;  % xtrack x atrack obs

% get L1c channel indices
ixv = 1 : nchan;
d1 = load('airs_l1c_wnum');
wnum = d1.wnum;

% write_buf flags
do_init = true;    % initialize buffers
do_close = false;  % close all buffers

% get datenums for this set
dlist =  set2dlist(iset);

% loop on datenums
for dn = dlist

  % get year and day-of-year
  dvec = datevec(dn);
  year = dvec(1);
  doy = datenum(dn) - datenum(year, 1, 1) + 1;

  % fix for 23 Sep 2021 calibration shift
  if year < 2021 | (year == 2021 & doy < 266)
    airs_home = airs_home1;
  else
    airs_home = airs_home2;
  end

  fprintf(1, '%s: processing set %d year %d doy %d\n', ...
    fstr, iset, year, doy)
  airs_dir = fullfile(airs_home, sprintf('%d/%03d', year, doy));

  % check that the source path exists
  if exist(airs_dir) ~= 7
    fprintf(1, '%s: bad source path %s\n', fstr, airs_dir)
    continue
  end

  % loop on AIRS granules
% flist = dir(fullfile(airs_dir, 'AIRS*L1C*.hdf'));
  flist = airs_glist(airs_dir);
  for fi = 1 : length(flist);

    airs_l1c = flist(fi).name;
    airs_gran = fullfile(airs_dir, airs_l1c);

    % read a "flattened" granule
    [d2, a2] = airs_flat(airs_gran);
    if isempty(d2)
      fprintf(1, '%s: no data in %s\n', fstr, airs_l1c)
      continue
    end

    % use QC from airs_flat
    iOK = d2.rad_qc == 0;
    rad = d2.rad(ixv,iOK);
    lat = d2.lat(iOK,1);
    lon = d2.lon(iOK,1);
    tai93 = d2.obs_time_tai93(iOK,1);
    sat_zen = d2.sat_zen(iOK,1);
    sol_zen = d2.sol_zen(iOK,1);
    asc_flag = d2.asc_flag(iOK,1);
    land_frac = d2.land_frac(iOK,1);

%   % old latitude subsample
%   nxt = length(ixt);
%   lat_rad = deg2rad(lat);
%   jx = rand(nxt, 135) < abs(cos(lat_rad));
%   jx = jx & iOK;

    % get tile indices
    [ilat, ilon, latB, lonB] = tile_index(latB, dLon, lat, lon);

    % loop on obs, write tiles
    nobs = length(ilat);
    for j = 1 : nobs

      write_buf(ilat(j), ilon(j), nlat, nlon, nchan, ...
        latB, lonB, iset, do_init, do_close, thome, ...
        nc_init, rad(:,j), tai93(j), lat(j), lon(j), ...
        sat_zen(j), sol_zen(j), asc_flag(j), land_frac(j))

      do_init = false;

    end % loop on obs
  end % loop on granules
end % loop on days

% write out non-empty buffers and quit
do_close = true;
write_buf(ilat(j), ilon(j), nlat, nlon, nchan, ...
  latB, lonB, iset, do_init, do_close, thome,  ...
  nc_init, rad(:,j), tai93(j), lat(j), lon(j), ...
  sat_zen(j), sol_zen(j), asc_flag(j), land_frac(j))

% report runtime
fprintf(1, 'runtime %.2f hours\n', toc / 3600)

