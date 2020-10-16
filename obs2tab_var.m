%
% NAME
%   obs2tab_var - mean and variance for equal area trapezoids
%
% SYNOPSIS
%   [latB, lonB, M1, W1, N1] = ...
%          obs2tab_var(nLat, dLon, lat, lon, obs, M1, W1, N1)
%
% INPUTS
%   dLat  - latitude tile width in degrees, should divide 90
%   dLon  - longitude tile width in degrees, should divide 180
%   lat   - k-vector, latitude list, values -90 to 90
%   lon   - k-vector, longitude list, values -180 to 180
%   obs   - k-vector, associated data values
%   M1    - m x n array, previous recursive mean
%   W1    - m x n array, previous sum((x - mean(x))^2)
%   N1    - m x n array, previous recursive count
%
%   note: if dLat is an m+1 vector, use it as the latitude tile
%   boundaries rather than a constant latitude tile width.
%
% OUTPUTS
%   latB  - m+1 vector, latitude bin boundaries
%   lonB  - n+1 vector, longitude bin boundaries
%   M1    - m x n array, current recursive mean
%   W1    - m x n array, current sum((x - mean(x))^2)
%   N1    - m x n array, current recursive count
%
% DISCUSSION
%   obs2tab_var takes a list of lat, lon, and obs values and
%   updates incremental mean and variance for a set of bins
%   bins as specified by latB and dLon.
%
%   The output parameters latB and lonB are the grid boundaries.
%
%   This is a relatively minor variaion of equal_area_var.m
%

function [latB, lonB, M1, W1, N1] = ...
         obs2tab_var(nLat, dLon, lat, lon, obs, M1, W1, N1)

[ilat, ilon, latB, lonB] = tile_index(dLat, dLon, lat, lon);

nobs = length(lat);
nlat = length(latB) - 1;   % number of latitude bands
nlon = length(lonB) - 1;   % number of longitude bands

if isempty(N1)
  % initialize input bins
  M1 = zeros(nlat, nlon);
  W1 = zeros(nlat, nlon);
  N1 = zeros(nlat, nlon);
else
  % check bin sizes
  [m, n] = size(M1);
  if m ~= nlat | n ~= nlon
    error('M1 does not conform with nLat or dLon')
  end
  [m, n] = size(W1);
  if m ~= nlat | n ~= nlon
    error('W1 does not conform with nLat or dLon')
  end
  [m, n] = size(N1);
  if m ~= nlat | n ~= nlon
    error('N1 does not conform with nLat or dLon')
  end
end

% loop on lat/lon/obs values
for i = 1 : nobs

  jlat = ilat(i);
  jlon = ilon(i);

  [M1(jlat,jlon), W1(jlat,jlon), N1(jlat,jlon)] = ...
     rec_var(M1(jlat,jlon), W1(jlat,jlon), N1(jlat,jlon), obs(i));

end

