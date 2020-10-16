%
% uniform_bands - uniform sampling latitude bands for polar orbiter
%
% output is a file latB<n> for <n> bands
%

addpath /asl/packages/ccast/source
addpath /asl/packages/ccast/motmsc/time

year = 2019;
iset = 8;

% load the 16-day set
afile = sprintf('obs_%d_s%0.2d.mat', year, iset);
c1 = load(afile);

dLat = 1/4; dLon = 1;  % fine grid for building sampling bands

[ilat, ilon, latB, lonB] =  tile_index(dLat, dLon, c1.lat_list, c1.lon_list);

nobs = length(ilat);       % total obs
nlat = length(latB) - 1;   % number of latitude bands
nlon = length(lonB) - 1;   % number of longitude bands
gtot = zeros(nlat, nlon);  % binned obs count

% get a count table
for i = 1 : nobs
  gtot(ilat(i), ilon(i)) = gtot(ilat(i), ilon(i)) + 1;
end

% equal_area_map(1, latB, lonB, gtot, 'test map');

% figure(2); clf
% plot(latB(1:end-1), mean(gtot, 2), 'o', 'linewidth', 2)
% xlabel('Latitude')
% ylabel('obs count')
% grid on

% target band structure
nband = 64;                    % desired number of bands (even)
latB2 = zeros(nband+1, 1);     % desired band boundaries
latB2(nband/2+1) = 0;          % start at equator

total_obs = sum(gtot(:));      % total of all obs
obs_band = total_obs / nband;  % desired obs/band
band_cnt = zeros(nband, 1);    % band obs counter

% fine grid working map
[nlat, nlon] = size(gtot);
sum_by_lat = sum(gtot,2);     % sum over longitude bins
half_bin = sum_by_lat(nlat/2)/2;   % half fine bin size

% start at the equator, loop south to north on bot fine-grid and
% target latitude bands, count obs in target bands, and mark target
% band edges

i = nband/2+1;           % target band initial index
for j = nlat/2+1 : nlat  % source band initial and max indices

  band_cnt(i) = band_cnt(i) + sum_by_lat(j);
  if band_cnt(i) >= obs_band - half_bin && i < nband+1
    i = i + 1;
    latB2(i) = latB(j+1);
    if i == nband+1, break, end
  end
end

band_cnt(55:end)
latB2(55:end)

% clean up and flip
latB2(end) = 90;
k = nband/2;
latB2(1:k) = -flipud(latB2(k+2:end));

figure(3)
plot(latB2(1:end-1), diff(latB2), 'o', ...
     latB2(1:end-1), diff(latB2), 'linewidth', 2)
title('band size by latitude')
xlabel('latitude ')
ylabel('band size')
grid on; zoom on

% save as a bin edge file
save(sprintf('latB%d', nband), 'latB2', 'band_cnt', 'nband', 'dLon')

return

%---------------
% mean(yy) / yy
%---------------

yy = mean(setx,2);     % mean by latitude
zz = mean(yy)./yy;     % multiplicative inverse
zz = sqrt(zz);         % ad hoc scaling
zz = zz ./ mean(zz);   % normalize
sum(zz * dLat)         % check sum of weights

latB2 = zeros(61,1);
latB2(1) = -90;
for i = 2 : 61
  latB2(i) = latB2(i-1) + dLat * zz(i-1);
end
save latB2 dLat latB2 zz latB

return

%---------------
%  max(yy) - yy
%---------------

yy = mean(setx,2);     % mean by latitude
yy = max(yy) - yy;     % arithmetic inverse
zz = yy ./ mean(yy);   % normalize
sum(zz * dLat)         % check sum of weights

latB2 = zeros(61,1);
latB2(1) = -90;
for i = 2 : 61
  latB2(i) = latB2(i-1) + dLat * zz(i-1);
end
save latB2 dLat latB2 zz latB

%--------
% ad hoc
%--------

zz = ones(60,1) * 3;
% w = [9, 2, 2, 2, 2, 2, 2];
% zz(1:7) = w;
% zz(54:60) = fliplr(w);

zz(1:5) = w;
zz(56:60) = fliplr(w);
latB2 = zeros(61,1);
latB2(1) = -90;
for i = 2 : 61
  latB2(i) = latB2(i-1) + zz(i-1);
end
save latB2 latB2

