%
% explore sampling stats for mercator and related tilings
%

addpath /asl/packages/ccast/source
addpath /asl/packages/ccast/motmsc/time

year = 2019;
iset = 8;

% load the 16-day set
afile = sprintf('obs_%d_s%0.2d.mat', year, iset);
c1 = load(afile);

% get tile indices from file or spec
  d1 = load('latB64');
  latx = d1.latB2;  
% latx = 3; 
  dLon = 5;

[ilat, ilon, latB, lonB] = tile_index(latx, dLon, c1.lat_list, c1.lon_list);

nobs = length(ilat);       % total obs
nlat = length(latB) - 1;   % number of latitude bands
nlon = length(lonB) - 1;   % number of longitude bands
gtot = zeros(nlat, nlon);  % binned obs count

% get a count table
for i = 1 : nobs
  gtot(ilat(i), ilon(i)) = gtot(ilat(i), ilon(i)) + 1;
end

equal_area_map(1, latB, lonB, gtot, 'test map');

figure(2); clf
plot(latB(1:end-1), mean(gtot, 2), 'o', 'linewidth', 2)
title('obs per tile')
xlabel('Latitude')
ylabel('obs count')
grid on

