
% get latitude bands
d1 = load('latB64');
latB = d1.latB2;  
nlat = length(latB) - 1;

% get longitude bands
dLon = 5;
lonB = -180 : dLon : 180;
nlon = length(lonB) - 1;

% latitude steps
dlat = diff(latB);

% latB midpoints
xtmp = (latB(1:end-1) + latB(2:end)) / 2;

plot(xtmp, dlat, '--', xtmp, dlat, 'o')
title('tile height by latitude')
xlim([-90, 90])
xlabel('latitude (degrees)')
ylabel('tile height (degrees)')
grid on

saveas(gcf, 'airs_tiling_lat_bands', 'png')

