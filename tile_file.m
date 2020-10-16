%
% NAME
%   tile_file - name and path for tile files
%
% SYNOPSIS
%   [tname, latdir] = tile_file(ilat, ilon, latB, lonB, year, iset)
%
% INPUTS
%   ilat  - latitude index, range 1 to m
%   ilon  - longitude index, range 1 to n
%   latB  - m+1 vector, latitude tile boundaries
%   lonB  - n+1 vector, longitude tile boundaries
%
% OUTPUTS
%   latdir - path to tile
%   tname  - tile filename
%
% FILENAME FORMAT
%   this is in a state of flux
%
%   lat and lon values are discretized in steps of 0.25 degrees for
%   the semi-Mercator (SM) grid.  lat and lon filename fields are of
%   the form XXXpXX_YYYYpYY, in hundredths of a degree, and are zero-
%   filled.  So for example the name for ilat = 40, ilon = 3 would be
%   airs_test_tile_2019_s03_lat019p25_lon-125p00.nc
%
%   filename lat/lon fields are the lower bounds for the associated
%   tile boundaries.
%

function [tname, latdir] = tile_file(ilat, ilon, latB, lonB, year, iset);

if ~(1 <= ilat & ilat < length(latB))
  error(sprintf('ilat value %d out of range', ilat))
end

if ~(1 <= ilon & ilon < length(lonB))
  error(sprintf('ilon value %d out of range', ilon))
end

if latB(ilat) >= 0, latpre = 'N'; else, latpre = 'S'; end
if lonB(ilon) >= 0, lonpre = 'E'; else, lonpre = 'W'; end

lat_str = sprintf('%s%05.2f', latpre, abs(latB(ilat)));
lon_str = sprintf('%s%06.2f', lonpre, abs(lonB(ilon)));
lat_str = strrep(lat_str, '.', 'p');
lon_str = strrep(lon_str, '.', 'p');

% lat_str = sprintf('lat%s%04d', latpre, abs(latB(ilat))*100);
% lon_str = sprintf('lon%s%04d', lonpre, abs(lonB(ilon))*100);

% lat_str = sprintf('lat%06.2f', latB(ilat)); 
% lat_str = strrep(lat_str, '-', 'm');
% lat_str = strrep(lat_str, '.', 'p');

% lon_str = sprintf('lon%07.2f', lonB(ilon)); 
% lon_str = strrep(lon_str, '-', 'm');
% lon_str = strrep(lon_str, '.', 'p');

latdir = lat_str;
tname = sprintf('airs_test_tile_%d_s%02d_%s_%s.nc', ...
          year, iset, lat_str, lon_str);

% if length(tname) ~= 47
%   error('file name length error')
% end

