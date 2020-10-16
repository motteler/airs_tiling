%
% NAME
%   tile_index - tile indices from lat/lon lists
%
% SYNOPSIS
%   [ilat, ilon, latB, lonB] = tile_index(dLat, dLon, lat, lon)
%
% INPUTS
%   dLat  - latitude tile width in degrees, should divide 90
%   dLon  - longitude tile width in degrees, should divide 180
%   lat   - k-vector, latitude list, values -90 to 90
%   lon   - k-vector, longitude list, values -180 to 180
%
%   note: if dLat is an m+1 vector, use it as the latitude tile
%   boundaries rather than a constant latitude tile width.
%
% OUTPUTS
%   ilat  - k-vector, latitude indices
%   ilon  - k-vector, longitude indices
%   latB  - m+1 vector, latitude tile boundaries
%   lonB  - n+1 vector, longitude tile boundaries
%

function [ilat, ilon, latB, lonB] = tile_index(dLat, dLon, lat, lon)

% check inputs
lat = lat(:);
lon = lon(:);
nobs = length(lat);
if length(lon) ~= nobs
  error('length of lat and lon lists must match')
end

% get latitude band edges
if isscalar(dLat)
  latB = -90 : dLat : 90;    
else
  latB = dLat;
end

lonB = -180 : dLon : 180;  % longitude band edges
nlat = length(latB) - 1;   % number of latitude bands
nlon = length(lonB) - 1;   % number of longitude bands

ilat = zeros(nobs,1);
ilon = zeros(nobs,1);

% loop on lat/lon values
for i = 1 : nobs

  % latitude index
  if isscalar(dLat)
    jlat = floor((lat(i) - latB(1)) / dLat) + 1;
  else
    jlat = find(lat(i) < latB, 1) - 1;
  end
  if jlat > nlat, jlat = nlat; end

  % longitude index
  jlon = floor((lon(i) - lonB(1)) / dLon) + 1;
  if jlon > nlon, jlon = nlon; end

  % check for valid ranges
  if ~(1 <= jlat & jlat <= nlat)
    error('latitude index out of range')
  elseif ~(1 <= jlon & jlon <= nlon)
    error('longitude index out of range')
  end

  ilat(i) = jlat;
  ilon(i) = jlon;
end

