%
% NAME
%   airsL1c2buf - AIRS buffered tiling main function
%
% SYNOPSIS
%   airsL1c2buf(year, iset, thome)
%
% INPUTS
%   year   - integer year
%   iset   - 16-day set number (1-23)
%   thome  - output tree home
%
% AUTHOR
%   H. Motteler, 10 Oct 2020
%

function airsL1c2buf(year, iset, thome)

% this function name
fstr = mfilename;  

% set up source paths
addpath /home/motteler/shome/chirp_test
addpath /home/motteler/cris/ccast/motmsc/utils
addpath /home/motteler/cris/ccast/motmsc/time
addpath /home/motteler/cris/ccast/source

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
airs_home = '/asl/airs/l1c_v672';
airs_year = fullfile(airs_home, sprintf('%d', year));

% fixed AIRS parameters
nchan = 2645;  % L1c channels
nobs = 90 * 135;    % xtrack x atrack obs

% get L1c channel indices
ixv = 1 : nchan;
d1 = load('airs_l1c_wnum');
wnum = d1.wnum;

% flag to initialize buffers
do_init = true;

% get dlist from 16-day set index
dlist =  set2dlist(year, iset);

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
        latB, lonB, year, iset, do_init, thome, nc_init, ...
        j, rad(:,j), tai93(j), lat(j), lon(j), ...
        sat_zen(j), sol_zen(j), asc_flag(j), land_frac(j))

      do_init = false;

%     pause(0.1);  %** temporary ** 

    end % loop on obs

    if mod(fi, 10) == 0, fprintf(1, '.'), end
  end % loop on granules
  fprintf(1, '\n')
end % loop on days

