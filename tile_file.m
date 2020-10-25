%
% NAME
%   tile_file - name and path for tile files
%
% SYNOPSIS
%   [tname, tpath] = tile_file(ilat, ilon, latB, lonB, iset, tpre)
%
% INPUTS
%   ilat  - latitude index, range 1 to m
%   ilon  - longitude index, range 1 to n
%   latB  - m+1 vector, latitude tile boundaries
%   lonB  - n+1 vector, longitude tile boundaries
%   iset  - integer set index (1-23)
%   tpre  - optional file prefex, default is "tile"
%
% OUTPUTS
%   tpath - path to tiles
%   tname - tile filename
%
% FILENAME FORMAT
%   lat and lon filename fields are of the form CNNpNN_CNNNpNN,
%   where C is a compass point (N, S, E, W) and N are decimal
%   digits.  So for example the tile file for ilat 23, ilon 40,
%   set 31, would be tile_2003_s031_S27p50_E015p00.nc.  The 16-day
%   sets are numbered starting at 1 Sep 2002.  lat and lon values
%   are discretized in steps of 0.25 degrees for the semi-Mercator
%   (SM) grid.  The default prefix "tile" can be changed with the
%   optional input field tpre.
%
%   The tile path tpath has the form YYYY_sNNN/CNNpNN, year, 16-day
%   set, and latitude directory name, for example 2003_s031_S27p50.
%   The latitude directory name matches the filename latitude field.
%
%   filename lat/lon fields are the lower bounds for the associated
%   tile boundaries.
%

function [tname, tpath] = ...
  tile_file(ilat, ilon, latB, lonB, iset, tpre)

% default tile file prefix
if nargin == 5
  tpre = 'tile';
end

% get year for this set
dlist = set2dlist(iset);
dvec = datevec(dlist(1));
year = dvec(1);

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

tname = sprintf('%s_%d_s%03d_%s_%s.nc', ...
          tpre, year, iset, lat_str, lon_str);

tpath = sprintf('%d_s%03d/%s', year, iset, lat_str);

