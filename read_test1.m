%
% airs tiling read tests
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

ilat = 10;
ilon = 10;

% unbuffered tests
% thome = '/asl/isilon/airs/tile_test1'
% year = 2020;
% iset = 2;  % full data set
% tpre = 'airs_test_tile';
% nobs = 6800;

% unbuffered tests
  thome1 = '/asl/lustre/airs/tile_test1'
  year = 2018
  iset = 16;  % full data set
  tpre1 = 'airs_test_tile';
  nobs1 = 5300;

[tname1, tpath1] = tile_file(ilat, ilon, latB, lonB, year, iset, tpre1);
tfull1 = fullfile(thome1, tpath1, tname1);
d1 = read_netcdf_h5(tfull1)

% buffered tests
  thome2 = '/asl/lustre/airs/tile_test2'
  year = 2018
  iset = 16;  % full data set
  tpre2 = 'tile';
  nobs2 = 3000;

[tname2, tpath2] = tile_file(ilat, ilon, latB, lonB, year, iset, tpre2);
tfull2 = fullfile(thome2, tpath2, tname2);
d2 = read_netcdf_h5(tfull2)

k = nobs2;

[ isequal(d1.tai93(1:k),  d2.tai93(1:k)), 
  isequal(d1.lat(1:k),    d2.lat(1:k)),
  isequal(d1.lon(1:k),    d2.lon(1:k)),
  isequal(d1.rad(:, 1:k), d2.rad(:, 1:k)) ]'

figure(1)
subplot(3,1,1)
plot(d1.tai93(1:k))
subplot(3,1,2)
plot(d1.lat(1:k))
subplot(3,1,3)
plot(d1.lon(1:k))

figure(2)
subplot(3,1,1)
plot(d2.tai93(1:k))
subplot(3,1,2)
plot(d2.lat(1:k))  
subplot(3,1,3)
plot(d2.lon(1:k))

