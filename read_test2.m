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

% buffered tests
  thome = '/asl/lustre/airs/tile_test5'
  year = 2018;
  tpre = 'tile';
  iset = 8;  % full data set
  nobs = 8900;
% iset = 7;  % just lat, lon, and time (but done)
% nobs = 10000;

% unbuffered tests
% thome = '/asl/isilon/airs/tile_test1'
% year = 2020;
% iset = 2;  % full data set
% tpre = 'airs_test_tile';
% nobs = 6800;

ilat = 10;
ilon = 10;

[tname, tpath] = tile_file(ilat, ilon, latB, lonB, year, iset, tpre);

tfull = fullfile(thome, tpath, tname);

tname

d1 = read_netcdf_h5(tfull)

figure(1)
subplot(3,1,1)
plot(d1.tai93(1:nobs))
subplot(3,1,2)
plot(d1.lat(1:nobs))  
subplot(3,1,3)
plot(d1.lon(1:nobs))

