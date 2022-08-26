%
% read_test4 -- compare compressed and uncompressed tile
%

% set up source paths
addpath /home/motteler/shome/chirp_test
addpath /home/motteler/cris/ccast/motmsc/utils
addpath /home/motteler/cris/ccast/motmsc/time
addpath /home/motteler/cris/ccast/source

% get latitude bands
d1 = load('latB64');
latB = d1.latB2;  
nlat = length(latB) - 1;

% get longitude bands
dLon = 5;
lonB = -180 : dLon : 180;
nlon = length(lonB) - 1;

% tile home & prefix
thome = '/asl/isilon/airs/tile_test7';
tpre = 'tile';

iset = 101
lat = input('lat > ');
lon = input('lon > ');
[ilat, ilon, latB, lonB] = tile_index(latB, dLon, lat, lon);

[tname, tpath] = tile_file(ilat, ilon, latB, lonB, iset, tpre);
tfull = fullfile(thome, tpath, tname);
d1 = read_netcdf_h5(tfull);
k = d1.total_obs;

tpath = strrep(tpath, '2007_s101', '2007_s101.bak');
tfull = fullfile(thome, tpath, tname);
d2 = read_netcdf_h5(tfull);

isequal(d1, d2)

return

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

if ~issorted(d1.tai93(1:k))
  fprintf(1, 'warning: time out of order\n')
end

display(datestr(airs2dnum(d1.tai93(1))))
display(datestr(airs2dnum(d1.tai93(k))))

