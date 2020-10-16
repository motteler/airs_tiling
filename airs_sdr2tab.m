%
% NAME
%   airs_sdr2tab - take AIRS SDRs to map tables
%
% SYNOPSIS
%   airs_sdr2tab(year, dlist, ofile)
%
% INPUTS
%   year   - integer year
%   dlist  - integer vector of days-of-the-year
%   ofile  - save file for obs lists
%
% DISCUSSION
%   mainly from airs_sdr2obs and equal_area_bins
%
% AUTHOR
%   H. Motteler, 1 Aug 2020
%

function airs_sdr2tab(year, dlist, ofile)

% set up source paths
addpath /home/motteler/shome/chirp_test
addpath /home/motteler/cris/ccast/motmsc/utils

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
% ixv = interp1(d1.wnum, 1:nchan, vlist, 'nearest');
ixv = 1 : nchan;
d1 = load('airs_l1c_wnum');
wnum = d1.wnum;

% this function name
fstr = mfilename;  

% set up map table working variables
gtot = zeros(nlat, nlon);         % binned obs count
gavg = zeros(nchan, nlat, nlon);  % binned obs means
gvar = zeros(nchan, nlat, nlon);  % binned obs variance

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
% for fi = 1 : 20       % ******** TEMPORARY ******** 

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

%   % old latitude subsample
%   nxt = length(ixt);
%   lat_rad = deg2rad(lat);
%   jx = rand(nxt, 135) < abs(cos(lat_rad));
%   jx = jx & iOK;

    % get tile indices
    [ilat, ilon, latB, lonB] = tile_index(latB, dLon, lat, lon);

    % loop on obs, do recursive stats
    nobs = length(ilat);
    for j = 1 : nobs

      % working variables
      jlat = ilat(j);
      jlon = ilon(j);
      x = rad(:, j);
      n2 = gtot(jlat, jlon) + 1;
      gtot(jlat, jlon) = n2;
      m1 = gavg(:, jlat, jlon);
      w1 = gvar(:, jlat, jlon);
 
      % update mean and variance
      d1 = x - m1;
      m2 = m1 + d1 ./ n2;
      w2 = w1 + d1 .* (x - m2);
      gavg(:, jlat, jlon) = m2;
      gvar(:, jlat, jlon) = w2;

    end % loop on obs

    if mod(fi, 10) == 0, fprintf(1, '.'), end
  end % loop on granules
  fprintf(1, '\n')
end % loop on days

for i = 1 : nchan
  gvar(i,:,:) = squeeze(gvar(i,:,:)) ./ (gtot - 1);
end

save(ofile, 'year', 'dlist', 'airs_home', 'gvar', 'gavg', 'gtot', ...
            'latB', 'lonB', 'wnum')

