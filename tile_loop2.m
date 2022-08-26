%
% tile_loop2 -- read timing test for one 16-day set
%

% set up source paths
addpath /home/motteler/shome/chirp_test
addpath /home/motteler/cris/ccast/motmsc/utils
addpath /home/motteler/cris/ccast/motmsc/time
addpath /home/motteler/cris/ccast/source

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

% data home & tile prefix
thome = '/asl/isilon/airs/tile_test7';
tpre = 'tile';

% tabulate max obs/tile
max_obs = zeros(nlat, nlon); 

tic
iset = 101;

% outer loop on tiles
% for ilat = 1 : nlat
for ilat = 33 : 64
  for ilon = 1 : nlon
   
    [tname, tpath] = tile_file(ilat, ilon, latB, lonB, iset, tpre);
%   tpath = strrep(tpath, '2007_s101', '2007_s101.bak');
    tfull = fullfile(thome, tpath, tname);
    d1 = read_netcdf_h5(tfull);

    if ~issorted(d1.tai93)
      fprintf(1, 'tile %d %d time not sorted\n', ilat, ilon)
    end
    if ~unique(d1.tai93)
      fprintf(1, 'tile %d %d time not unique\n', ilat, ilon)
    end

    % find max obs for this tile
    if max_obs(ilat, ilon) < d1.total_obs
      max_obs(ilat, ilon) = d1.total_obs;
    end

  end % loop on lon
  fprintf(1, '.')
end % loop on lat
fprintf(1, '\n')

fprintf(1, 'max tile obs %d\n', max(max_obs(:)))

toc

