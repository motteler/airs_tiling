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
%     (this replaces the airsL1c2til array tile_count)
%
%   buf_cnt - nbuf vector, count of values in each buffer (0 to bmax)
%     buf_cnt = 0, buffer is empty, and so free
%     buf_cnt = n, for n > 0, buffer has valid data from 1 to n
%
%   buf_age - nbuf vector, buffer age in write_buf calls
%
%   buf_tile - 2 x nbuf array of lat/lon values for buffer tile
%     if buf_cnt = 0, buf_tile should also be 0
%
% INPUT VALUES
%   ilat - lat index for current obs
%   ilog - lon index for current obs
%   buf_init - true if buffer has been initialized
%

function write_buf(ilat, ilon, nlat, nlon, nchan, ...
  latB, lonB, year, iset, do_init, tile_home, nc_init, ...
  rad, tai93, lat, lon, sat_zen, sol_zen, asc_flag)

% number of buffers
nbuf = 4;

% buffer size
bmax = 12; 

%-----------------------------
% set up persistent variables
%-----------------------------

% persistent buffers, pointers, and table
persistent rad_b tai93_b lat_b lon_b sat_zen_b sol_zen_b asc_flag_b
persistent tile_buf tile_cnt buf_cnt buf_age buf_tile

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

  % pointers and counters
  tile_buf = zeros(nlat, nlon);    % buffers pointers
  tile_cnt = -1*ones(nlat, nlon);  % obs written count
  buf_cnt = zeros(bmax, 1);        % buffer counts
  buf_age = zeros(bmax, 1);        % buffer age
  buf_tile = zeros(2,bmax);        % buffer tile indices
end

%-----------------------------------
% get a buffer for the current tile
%-----------------------------------

if tile_buf(ilat, ilon) == 0
  % no buffer is allocated to this tile
  % see if there is a free buffer
  found = false;
  for j = 1 : nbuf
    if buf_cnt(j) == 0
       if buf_age(j) ~= 0, error('bad value for buf_age'), end
       % allocate the buffer to this tile
       tile_buf(ilat, ilon) = j;    % save buffer index in tile
       buf_tile(1,j) = ilat;        % save tile indices in buffer
       buf_tile(2,j) = ilon;
       found = true;
       break
    end
  end
  % if found, we have a buffer for the current tile
  if found
    fprintf(1, 'found buffer %d for tile %d %d\n', j, ilat, ilon)
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
    fprintf(1, 'aging out buffer %d\n', iold)

    % write out the old buffer
    write_file(iold);

    % allocate the buffer to this tile
    tile_buf(ilat, ilon) = iold;    % save buffer index in tile
    buf_tile(1,iold) = ilat;        % save tile indices in buffer
    buf_tile(2,iold) = ilon;
    buf_age(iold) = 0;
    found = true;
  
  end % if ~found
end % if tile_buf(ilat, ilon) == 0

% buf_id is our write buffer
buf_id = tile_buf(ilat, ilon);

% but do some sanity checks....
if buf_id < 1 | nbuf < buf_id, error('bad value for buf_id'), end
if buf_cnt(buf_id) > bmax, error('bad value for buf_cnt'), end
fprintf(1, 'tile %d %d is using buffer %d\n', ilat, ilon, buf_id)

%---------------------------------
% write the obs to the tile buffer
%----------------------------------

if buf_cnt(buf_id) == bmax
  % buffer is full, so write to file first
  write_file(buf_id);

  % keep this buffer
  tile_buf(ilat, ilon) = buf_id;  % save buffer index in tile
  buf_tile(1,buf_id) = ilat;      % save tile indices in buffer
  buf_tile(2,buf_id) = ilon;
end

% increment buffer pointer;
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
 
% age the buffers
ix = buf_cnt > 0;  % index of non-empty buffers
buf_age(ix) = buf_age(ix) + 1;

%--------------------------
% write a buffer to netCDF
%--------------------------
% write buffer iout to the associated tile at jlat, jlon, reset
% buffer iout, reset tile_buff pointer, and update the write count
% tile_cnt

function write_file(iout)

% get lat and lon indices from the iout buffer.  these may 
% differ from ilat and ilon if we are writing out an old buffer
jlat = buf_tile(1, iout);
jlon = buf_tile(2, iout);

% get tile filename
[tname, latdir] = tile_file(jlat, jlon, latB, lonB, year, iset);

% full path to the tile
tfull = fullfile(tile_home, latdir, tname);

% check tile state, -1 means no file yet
if tile_cnt(jlat, jlon) == -1
  % create a new tile file

  % no tile home is fatal
  if ~exist(tile_home) == 7
    error([tile_home, ' does not exist'])
  end

  % if latdir does not exits, create it        
  if ~exist(fullfile(tile_home, latdir))
    mkdir(tile_home, latdir)
  % fprintf(1, 'creating lat dir %s\n', latdir)
  end

  % copy the netcdf tile file template to the new file
  % and change the tile state to 0 (new, empty file).
  copyfile(nc_init, tfull)
  tile_cnt(jlat, jlon) = 0;
  fprintf(1, 'creating tile file %s\n', tname)
end

jx = 1 : buf_cnt(iout);   % index span of values in buffer
icount = length(jx);      % number of values to write to file
istart = tile_cnt(jlat, jlon) + 1;  % write start in tile file

fprintf(1, 'writing %d values to tile %d %d\n', icount, jlat, jlon)
% h5write(tfile, '/rad', rad_b(:,jx), [1,istart], [nchan,icount]);
% h5write(tfile, '/tai93', tai93_b(jx), istart, icount);
% h5write(tfile, '/lat',   lat_b(jx),   istart, icount);
% h5write(tfile, '/lon',   lon_b(jx),   istart, icount);
% h5write(tfile, '/sat_zen', sat_zen_b(jx), istart, icount);
% h5write(tfile, '/sol_zen', sol_zen_b(jx), istart, icount);
% h5write(tfile, '/asc_flag', uint8(asc_flag_b(jx)), istart, icount);

% reset the buffer
buf_cnt(iout) = 0;
buf_age(iout) = 0;
buf_tile(:,iout) = [0,0]';

% reset the tile buffer pointer
tile_buf(jlat, jlon) = 0;

% update the tile write pointer
tile_cnt(jlat, jlon) = tile_cnt(jlat, jlon) + icount;

end % function write_file

end % function write_buf

