%
% airs tiling read tests
%
% tile_2007_s101_S68p25_W155p00.nc
% 123456789012345678901234567890
%          1         2         3
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

% tile path from name
tname = input('tname > ', 's');
tset = tname(6:14);
tdir = tname(16:21);
tfull = fullfile(thome, tset, tdir, tname);

% read the data
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

if ~issorted(d1.tai93(1:k))
  fprintf(1, 'warning: time out of order\n')
end

display(datestr(airs2dnum(d1.tai93(1))))
display(datestr(airs2dnum(d1.tai93(k))))

