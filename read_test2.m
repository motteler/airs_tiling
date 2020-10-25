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
  thome = '/asl/isilon/airs/tile_test7'
  tpre = 'tile';
  iset = 32;

lat = input('lat > ');
lon = input('lon > ');
[ilat, ilon, latB, lonB] = tile_index(latB, dLon, lat, lon);

[tname, tpath] = tile_file(ilat, ilon, latB, lonB, iset, tpre);
tfull = fullfile(thome, tpath, tname);
d1 = read_netcdf_h5(tfull)
k = d1.total_obs;

figure(1)
subplot(3,1,1)
plot(d1.tai93(1:k))
title('time')
xlim([0,k])
grid on

subplot(3,1,2)
plot(d1.lat(1:k))
title('latitude')
xlim([0,k])
grid on

subplot(3,1,3)
plot(d1.lon(1:k))
title('longitude')
xlabel('obs index')
xlim([0,k])
grid on


