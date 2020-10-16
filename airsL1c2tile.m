%
% NAME
%   airsL1c2tile - take AIRS SDRs to map tables
%
% SYNOPSIS
%   airsL1c2tile(year, iset, odir)
%
% INPUTS
%   year   - integer year
%   iset   - 16-day set number (1-23)
%   odir  -  output tree home
%
% AUTHOR
%   H. Motteler, 10 Oct 2020
%

function airsL1c2tile(year, iset, odir)

% this function name
fstr = mfilename;  

% set up source paths
addpath /home/motteler/shome/chirp_test
addpath /home/motteler/cris/ccast/motmsc/utils
addpath /home/motteler/cris/ccast/source

% initial empty netCDF file
nc_init = './airs_tile.nc';

% tile home directory
tile_home = '/asl/lustre/airs/tile_test2';

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

% tile file count values
%  -1 is no file, 0 is empty file, n > 0 is n obs written
tile_count = ones(nlat, nlon) * -1;  

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

      % working variables
      jlat = ilat(j);
      jlon = ilon(j);
      rtmp = rad(:, j);

      % get tile filename
      [tname, latdir] = tile_file(jlat, jlon, latB, lonB, year, iset);

      % full path to the tile
      tfull = fullfile(tile_home, latdir, tname);

      % check tile state, -1 means no file yet
      if tile_count(jlat, jlon) == -1
        % create a new tile file

        % no tile home is fatal
        if ~exist(tile_home) == 7
          error([tile_home, ' does not exist'])
        end
          
        % if latdir does not exits, create it        
        if ~exist(fullfile(tile_home, latdir))
          mkdir(tile_home, latdir)
%         fprintf(1, 'creating lat dir %s\n', latdir)
        end

        % copy the netcdf tile file template to the new file
        % and change the tile state to 0 (new, empty file).
        copyfile(nc_init, tfull)
        tile_count(jlat, jlon) = 0;
%       fprintf(1, 'creating tile file %s\n', tname)
      end

      % increment obs count for this tile
      tile_count(jlat, jlon) = tile_count(jlat, jlon) + 1;

      % copy out the data for this obs and tile
      tc = tile_count(jlat, jlon);

%     fprintf(1, 'writing %s obs %d\n', tname, tc)
      h5write(tfull, '/rad', single(rtmp), [1,tc], [nchan,1]);
      h5write(tfull, '/tai93',    tai93(j),        tc, 1);
      h5write(tfull, '/lat',      single(lat(j)),  tc, 1);
      h5write(tfull, '/lon',      single(lon(j)),  tc, 1);
      h5write(tfull, '/sat_zen',  sat_zen(j),      tc, 1);
      h5write(tfull, '/sol_zen',  sol_zen(j),      tc, 1);
      h5write(tfull, '/asc_flag', uint8(asc_flag(j)), tc, 1);

    end % loop on obs

    if mod(fi, 10) == 0, fprintf(1, '.'), end
  end % loop on granules
  fprintf(1, '\n')
end % loop on days

