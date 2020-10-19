%
% write_buf - buffered write for tiles
%
% BUFFER PARAMETERS 
%   bmax - max buffer size
%   nbuf - number of buffers
%
%   tile_buf - nlat x nlon array of pointers to current tile buffer
%     tile_buf = 0, no buffer for this tile
%     tile_buf = k, 0 < k <= nbuf, buffer k is allocated to this tile
%
%   tile_cnt - nlat x nlon array, number of obs written to this tile
%     tile_cnt = -1, no file created for this tile yet
%     tile_cnt = k, 0 < k,  k obs written to the tile
%
%   buf_tile - 2 x nbuf array of the lat/lon index of the tile using
%     this buffer.  If zero, buffer is free
%
%   buf_cnt - nbuf vector, count of values in each buffer (0 to bmax)
%     buf_cnt = 0, buffer is empty, and so free
%     buf_cnt = n, for n > 0, buffer has valid data from 1 to n
%
%   buf_age - nbuf vector, buffer age in write_buf calls
%
% INPUT VALUES
%   ilat - lat index for current obs
%   ilon - lon index for current obs
%   buf_init - true if buffer has been initialized
%   obs  - current obs index (from current granule)

function write_buf(ilat, ilon, nlat, nlon, nchan, ...
  latB, lonB, year, iset, do_init, thome, nc_init, ...
  obs, rad, tai93, lat, lon, sat_zen, sol_zen, asc_flag, land_frac)

% number of buffers
nbuf = 4;

% buffer size
bmax = 4; 

%-----------------------------
% set up persistent variables
%-----------------------------

% persistent buffers, pointers, and tables
persistent rad_b tai93_b lat_b lon_b sat_zen_b sol_zen_b 
persistent asc_flag_b land_frac_b 
persistent tile_buf tile_cnt buf_tile buf_cnt buf_age

% initialize persistent data on first call
if do_init
  fprintf(1, 'initializing buffers\n')

  % tile data buffers
  rad_b     = single(zeros(nchan, bmax));
  tai93_b   = zeros(bmax, 1);
  lat_b     = single(zeros(bmax, 1));
  lon_b     = single(zeros(bmax, 1));
  sat_zen_b = single(zeros(bmax, 1));
  sol_zen_b = single(zeros(bmax, 1));
  asc_flag_b = uint8(zeros(bmax, 1));
  land_frac_b = single(zeros(bmax, 1));

  % pointers and counters
  tile_buf = zeros(nlat, nlon);    % buffers pointers
  tile_cnt = -1*ones(nlat, nlon);  % obs written count
  buf_tile = zeros(2,bmax);        % buffer tile indices
  buf_cnt = zeros(bmax, 1);        % buffer counts
  buf_age = zeros(bmax, 1);        % buffer age

  % buffer space summary
  fprintf(1, 'buffer space %.2f MB\n', nbuf*bmax*(nchan+8)*4 / 1e6 )
end

%-----------------------------------
% get a buffer for the current tile
%-----------------------------------

if tile_buf(ilat, ilon) == 0
  % no buffer is allocated to this tile
  % see if there is a free buffer
  found = false;
  for j = 1 : nbuf
    if buf_tile(1,j) == 0
       % allocate the buffer to this tile
       tile_buf(ilat, ilon) = j;    % save buffer index in tile
       buf_tile(1,j) = ilat;        % save tile indices in buffer
       buf_tile(2,j) = ilon;
       buf_age(j) = 0;              % zero out buffer age and count
       buf_cnt(j) = 0;
       found = true;
       break
    end
  end
  % if found, we have a buffer for the current tile
  if found
    fprintf(1, 'found free buffer %d for tile %d %d\n', j, ilat, ilon)
  end

  if ~found
    % we need to free up a buffer, so find the oldest
    atmp = 0; iold = 0;
    for j = 1 : nbuf
      if buf_age(j) > atmp
        atmp = buf_age(j);
        iold = j;
      end
    end
    % iold is index of oldest buffer
    if iold == 0, error('could not find oldest buffer'), end
    fprintf(1, 'aging out buffer %d for tile %d %d\n', ...
                iold, buf_tile(1,iold), buf_tile(2,iold))

    % write out the old buffer
    write_file(iold);

    % clear the tile from the iold buffer/tile pair
    xlat = buf_tile(1,iold);
    xlon = buf_tile(2,iold);
    tile_buf(xlat, xlon) = 0;

    % allocate the buffer with this tile
    tile_buf(ilat, ilon) = iold;    % save buffer index in tile
    buf_tile(1,iold) = ilat;        % save tile indices in buffer
    buf_tile(2,iold) = ilon;
    found = true;
  
  end % if ~found
end % if tile_buf(ilat, ilon) == 0

% buf_id is our write buffer
buf_id = tile_buf(ilat, ilon);

% at this point we have a valid tile/buffer pair
fprintf(1, 'tile %d %d obs %d buffer %d\n', ilat, ilon, obs, buf_id)

%---------------------------------
% write the obs to the tile buffer
%----------------------------------

if buf_cnt(buf_id) == bmax
  % if the buffer is full, write it out first.  write_file keeps the
  % tile/buffer pairing, but resets buf_cnt and buf_age.
  write_file(buf_id);
end

% increment the buffer counter
buf_cnt(buf_id) = buf_cnt(buf_id) + 1;
j = buf_cnt(buf_id);

% write to the buffers
rad_b(:,j)   = rad;
tai93_b(j)   = tai93;
lat_b(j)     = lat;
lon_b(j)     = lon;
sat_zen_b(j) = sat_zen;
sol_zen_b(j) = sol_zen;
asc_flag_b(j) = asc_flag;
land_frac_b(j) = land_frac;
 
% age the buffers
ix = buf_cnt > 0;  % index of non-empty buffers
buf_age(ix) = buf_age(ix) + 1;

% buffer sanity check
buffer_check

% more buffer sanity check
dLon = lonB(2)-lonB(1);
[ilat2, ilon2] = tile_index(latB, dLon, lat, lon);
if ilat2 ~= ilat | ilon2 ~= ilon
  fprintf(1, 'lat/lon mismatch on buffer write\n')
  fprintf(1, 'tile: %.2f %.2f  buffer %.2f %.2f\n', ...
     latB(ilat), lonB(ilon), latB(ilat2), lonB(ilon2))
end

%-----------------------
% begin local functions
%-----------------------

%--------------------------
% write a buffer to netCDF
%--------------------------
% write buffer iout to the tile at jlat, jlon, update the tile write
% count, and udate buffer iout age and count.  don't reset tile_buff
% or buf_tile here, we want to keep the tile/buffer pair.

function write_file(iout)

% get lat and lon indices from the iout buffer.  these may differ
% from the current ilat and ilon if we are writing out an old buffer
jlat = buf_tile(1, iout);
jlon = buf_tile(2, iout);

% get the tile filename
[tname, tpath] = tile_file(jlat, jlon, latB, lonB, year, iset);

% full path to the tile
tfull = fullfile(thome, tpath, tname);

% check tile state, -1 means no file yet
if tile_cnt(jlat, jlon) == -1
  % create a new tile file

  % no tile home is fatal
  if ~exist(thome) == 7
    error([thome, ' does not exist'])
  end

  % if tpath does not exits, create it        
  pfull = fullfile(thome, tpath);
  if ~exist(pfull)
    [s, w] = unix(sprintf('mkdir -p %s', pfull));
    if s ~= 0, error(sprintf('mkdir -p %s failed', pfull)), end
    fprintf(1, 'creating tile path %s\n', tpath)
  end

  % copy the netcdf tile file template to the new file and update
  % tile_cnt to 0 (no obs written yet)
  copyfile(nc_init, tfull)
  tile_cnt(jlat, jlon) = 0;
  fprintf(1, 'creating tile file %s\n', tname)
end

jx = 1 : buf_cnt(iout);   % index span of values in buffer
icount = length(jx);      % number of values to write to file
istart = tile_cnt(jlat, jlon) + 1;  % write start in tile file

fprintf(1, 'writing %d values from buffer %d to tile %d %d\n', ...
            icount, iout, jlat, jlon)

% buffer sanity check
dLon = lonB(2)-lonB(1);
for j = jx
  [ilat2, ilon2] = tile_index(latB, dLon, lat_b(j), lon_b(j));
  if ilat2 ~= jlat | ilon2 ~= jlon
    fprintf(1, 'lat/lon mismatch on file write\n')
    fprintf(1, 'tile: %.2f %.2f  buffer %.2f %.2f\n', ...
      latB(jlat), lonB(jlon), latB(ilat2), lonB(ilon2))
%   keyboard
  end
end

if exist(tfull) ~= 2, keyboard, end   % ****** test test test *****

  h5write(tfull, '/rad', rad_b(:,jx), [1,istart], [nchan,icount]);
  h5write(tfull, '/tai93', tai93_b(jx), istart, icount);
  h5write(tfull, '/lat',   lat_b(jx),   istart, icount);
  h5write(tfull, '/lon',   lon_b(jx),   istart, icount);
  h5write(tfull, '/sat_zen', sat_zen_b(jx), istart, icount);
  h5write(tfull, '/sol_zen', sol_zen_b(jx), istart, icount);
  h5write(tfull, '/asc_flag', uint8(asc_flag_b(jx)), istart, icount);
  h5write(tfull, '/land_frac', land_frac_b(jx), istart, icount);

% reset the buffer count and age
buf_cnt(iout) = 0;
buf_age(iout) = 0;

% update the tile write counter
tile_cnt(jlat, jlon) = tile_cnt(jlat, jlon) + icount;

end % function write_file

%---------------------------------
% sanity checks for valid buffers
%---------------------------------
% these checks are useful for debugging but maybe overkill 
% in production code, if called for every call of write_buf

function buffer_check

% for each tile, check that the associated buffer pointers match
for i = 1 : nlat
  for j = 1 : nlon
    bix = tile_buf(i,j);

    % range check
    if bix < 0 | nbuf < bix
        error(sprintf('tile %d %d bad buf val %d ', i, j, bix))
    end

    % check that tile lat/lon matches the buffer
    if bix ~= 0
      if buf_tile(1, bix) ~= i | buf_tile(2, bix) ~= j
        error(sprintf('tile %d %d buffer %d mismatch', i, j, bix))
      end
    end
  end
end

% for each buffer, check that the associated tile pointers match
for i = 1 : nbuf
  blat = buf_tile(1, i);
  blon = buf_tile(2, i);

  % range checks
  if blat < 0 | nlat < blat
    error(sprintf('tile %d %d bad lat ind %d ', i, j, blat))
  end
  if blon < 0 | nlon < blon
    error(sprintf('tile %d %d bad lat ind %d ', i, j, blon))
  end
  if (blat == 0 | blon == 0) & (blat ~= blon)
     error (sprintf('buffer %d lat ind %d %d ???', i, blat, blon))
  end

  % check that buffer lat/lon matches the tile 
  if blat ~= 0
    if tile_buf(blat, blon) ~= i
      error(sprintf('tile %d %d buffer %d mismatch', blat, blon, i))
    end
  end
end

end % function buffer_check

end % function write_buf

