%
% comp_tiles -- compress and test a 16-day tile set
%
% INPUTS
%   iset   - 16-day set number
%   thome  - tile tree home dir
%

function comp_tiles(iset, thome)

% set up source paths
addpath /home/motteler/shome/chirp_test
addpath /home/motteler/cris/ccast/motmsc/utils
addpath /home/motteler/cris/ccast/motmsc/time
addpath /home/motteler/cris/ccast/source

% start runtime clock
tic 

% get latitude bands
d1 = load('latB64');
latB = d1.latB2;  
nlat = length(latB) - 1;

% get longitude bands
dLon = 5;
lonB = -180 : dLon : 180;
nlon = length(lonB) - 1;

% initialize counters
ntile = 0;  % total tiles checked
ncomp = 0;  % tiles compressed this pass
ndone = 0;  % tiles already compressed
max_obs = zeros(nlat, nlon);  % max obs/tile

% loop on tiles
for ilat = 1 : nlat
  for ilon = 1 : nlon
   
    % get name and path for the current tile
    [tname, tpath] = tile_file(ilat, ilon, latB, lonB, iset);
    tfull = fullfile(thome, tpath, tname);

    % check that the tile file exists and we can read it
    if exist(tfull) ~= 2
      fprintf(1, 'no file, tile %s\n', tname)
      continue
    end

    try
      ni = ncinfo(tfull);
    catch
      fprintf(1, 'info read error, tile %s\n', tname)
      continue
    end

    try
      d1 = read_netcdf_h5(tfull);
    catch
      fprintf(1, 'full read error, tile %s\n', tname)
      continue
    end
    ntile = ntile + 1;  % tile read counter

    % some basic sanity checks
    if ~issorted(d1.tai93)
      fprintf(1, 'tile %d %d time not sorted\n', ilat, ilon)
    end
    if ~unique(d1.tai93)
      fprintf(1, 'tile %d %d time not unique\n', ilat, ilon)
    end

    % find max obs for this tile
    if max_obs(ilat, ilon) < d1.total_obs
      max_obs(ilat, ilon) = d1.total_obs;
    end

    % check for compression
    DeflateLevel = ni.Variables(1).DeflateLevel;
    if isempty(DeflateLevel)

      % compress the tile to a temp file
      ftmp = strrep(tfull, '.nc', '.tmp');
%     fprintf(1, 'compressing %s\n', tname)
      [u,e] = unix(sprintf('nccopy -d 4 %s %s', tfull, ftmp));
      if u ~= 0, error(e), end  

      % check the compressed data
      d2 = read_netcdf_h5(ftmp);
      if isequal(d1, d2)
        % move the temp to tile file
        [u,e] = unix(sprintf('mv %s %s', ftmp, tfull));
        if u ~= 0, error(e), end  
        ncomp = ncomp + 1;
      else
        fprintf(1, 'compression failure, %s\n', tname)
        delete(ftmp)
      end

    % sanity check for the deflate level
    elseif 0 < DeflateLevel & DeflateLevel <= 9
      ndone = ndone + 1;
%     fprintf(1, 'already compressed %s\n', tname)
    else
      error(sprintf('bad deflate value %d', DeflateLevel))
    end

  end % loop on lon
end % loop on lat

% status summary
if ndone > 0
  fprintf(1, 'skipped %d compressed tiles\n', ndone);
end
fprintf(1, 'compressed %d of %d tiles\n', ncomp, ntile);
if ndone + ncomp ~= ntile
  fprintf(1, 'warning: %d tiles unaccounted for\n', ntile - (ndone + ncomp))
end
fprintf(1, 'max tile obs %d\n', max(max_obs(:)))
fprintf(1, 'runtime %.2f hours\n', toc / 3600)

