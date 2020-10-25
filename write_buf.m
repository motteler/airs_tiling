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
  latB, lonB, iset, do_init, do_close, thome, nc_init, ...
  rad, tai93, lat, lon, sat_zen, sol_zen, asc_flag, land_frac)

%------------------
% local parameters
%------------------

bmax = 300;     % buffer size
nbuf = 200;     % number of buffers
verbose = 0;    % print lots of status messages
do_checks = 0;  % do several buffer sanity checks

%-----------------------------
% set up persistent variables
%-----------------------------

% persistent buffers, pointers, and tables
persistent rad_b tai93_b lat_b lon_b sat_zen_b sol_zen_b 
persistent asc_flag_b land_frac_b 
persistent tile_buf tile_cnt buf_tile buf_cnt buf_age call_cnt

% initialize persistent data on first call
if do_init
  fprintf(1, 'initializing buffers\n')

  % tile data buffers
  rad_b     = single(zeros(nchan, bmax, nbuf));
  tai93_b   = zeros(bmax, nbuf);
  lat_b     = single(zeros(bmax, nbuf));
  lon_b     = single(zeros(bmax, nbuf));
  sat_zen_b = single(zeros(bmax, nbuf));
  sol_zen_b = single(zeros(bmax, nbuf));
  asc_flag_b = uint8(zeros(bmax, nbuf));
  land_frac_b = single(zeros(bmax, nbuf));

  % pointers and counters
  tile_buf = zeros(nlat, nlon);    % buffers pointers
  tile_cnt = -1*ones(nlat, nlon);  % obs written count
  buf_tile = zeros(2,bmax);        % buffer tile indices
  buf_cnt = zeros(bmax, 1);        % buffer counts
  buf_age = zeros(bmax, 1);        % buffer age
  call_cnt = 0;                    % call counter

  % buffer space summary
  fprintf(1, 'buffer space %.2f MB\n', nbuf*bmax*(nchan+8)*4 / 1e6 )
end

%---------------------------------------
% option to write all buffers and return
%----------------------------------------

if do_close
  fprintf(1, 'writing out all buffers...\n')

  % find all non-empty buffers
  for j = 1 : nbuf
    if buf_cnt(j) > 0;
      buf_msg(sprintf('closing buffer %d', j))
      write_file(j);
    end
  end
  % compare counts
  tc = tile_cnt(:);
  s1 = sum(tc(tc > 0));
  if s1 == call_cnt
    fprintf(1, 'call and write counts agree\n')
  else
    fprintf(1, 'call count %d, write count %d\n', call_cnt, s1)
  end
  return % all done
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
    buf_msg(sprintf('found free buffer %d for tile %d %d', j, ilat, ilon))
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
    buf_msg(sprintf('aging out buffer %d for tile %d %d', ...
                    iold, buf_tile(1,iold), buf_tile(2,iold)))

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

% increment call counter
call_cnt = call_cnt + 1;

% at this point we have a valid tile/buffer pair
% buf_msg(sprintf('writing L1c obs %d to tile %d %d buffer %d...', ...
%              call_cnt, ilat, ilon, buf_id))

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
rad_b(:,j, buf_id)     = rad;
tai93_b(j, buf_id)     = tai93;
lat_b(j, buf_id)       = lat;
lon_b(j, buf_id)       = lon;
sat_zen_b(j, buf_id)   = sat_zen;
sol_zen_b(j, buf_id)   = sol_zen;
asc_flag_b(j, buf_id)  = asc_flag;
land_frac_b(j, buf_id) = land_frac;
 
% age the buffers; increment buf_age for all non-empty buffers
% and set age for the current buffer to zero
ix = buf_cnt > 0;
buf_age(ix) = buf_age(ix) + 1;
buf_age(buf_id) = 0;

% buffer sanity checks
if do_checks
  buffer_check

  % more buffer sanity check
  dLon = lonB(2)-lonB(1);
  [ilat2, ilon2] = tile_index(latB, dLon, lat, lon);
  if ilat2 ~= ilat | ilon2 ~= ilon
    fprintf(1, 'lat/lon mismatch on buffer write\n')
    fprintf(1, 'tile: %.2f %.2f  buffer %.2f %.2f\n', ...
      latB(ilat), lonB(ilon), latB(ilat2), lonB(ilon2))
  end
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
[tname, tpath] = tile_file(jlat, jlon, latB, lonB, iset);

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
    buf_msg(sprintf('creating tile path %s', tpath))
  end

  % copy the netcdf tile file template to the new file and update
  % tile_cnt to 0 (no obs written yet)
  copyfile(nc_init, tfull)
  tile_cnt(jlat, jlon) = 0;
  buf_msg(sprintf('creating tile file %s', tname))
end

jx = 1 : buf_cnt(iout);   % index span of values in buffer
icount = length(jx);      % number of values to write to file
istart = tile_cnt(jlat, jlon) + 1;  % write start in tile file

buf_msg(sprintf('writing %d values from buffer %d to tile %d %d', ...
                icount, iout, jlat, jlon))

% buffer sanity check
if do_checks
  dLon = lonB(2)-lonB(1);
  for j = jx
    [ilat2, ilon2] = tile_index(latB, dLon, lat_b(j, iout), lon_b(j, iout));
    if ilat2 ~= jlat | ilon2 ~= jlon
      buf_msg('lat/lon mismatch on file write')
      buf_msg(sprintf('tile: %.2f %.2f  buffer %.2f %.2f', ...
        latB(jlat), lonB(jlon), latB(ilat2), lonB(ilon2)))
%     keyboard
    end
  end
end

if exist(tfull) ~= 2
  fprintf(1, 'can''t find tile file %s', tfull)
  keyboard
  error(sprintf('can''t find tile file %s', tfull))
end

  h5write(tfull, '/rad', rad_b(:,jx, iout), [1,istart], [nchan,icount]);
  h5write(tfull, '/tai93',    tai93_b(jx, iout),   istart, icount);
  h5write(tfull, '/lat',      lat_b(jx, iout),     istart, icount);
  h5write(tfull, '/lon',      lon_b(jx, iout),     istart, icount);
  h5write(tfull, '/sat_zen',  sat_zen_b(jx, iout), istart, icount);
  h5write(tfull, '/sol_zen',  sol_zen_b(jx, iout), istart, icount);
  h5write(tfull, '/asc_flag', uint8(asc_flag_b(jx, iout)), istart, icount);
  h5write(tfull, '/land_frac', land_frac_b(jx, iout), istart, icount);
  h5write(tfull, '/total_obs', int32(tile_cnt(jlat, jlon) + icount));

% update the tile write counter
tile_cnt(jlat, jlon) = tile_cnt(jlat, jlon) + icount;

% reset the buffer count and age
buf_cnt(iout) = 0;
buf_age(iout) = 0;

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

%------------------------
% buffer status messages
%------------------------
function buf_msg(msg)

if verbose
  fprintf(1, '%s\n', msg)
end

end % function buf_msg

end % function write_buf

