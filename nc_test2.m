%
% test incremental vs block writes
%

% fixed AIRS parameters
nchan = 2645;  % L1c channels
nobs = 90 * 135;    % xtrack x atrack obs

% initial empty netCDF file
nc_init = './airs_tile.nc';

file1 = './tile_test1.nc';
file2 = './tile_test2.nc';

rtmp = rand(nchan, nobs);

copyfile(nc_init, file1)
copyfile(nc_init, file2)

tic
for i = 1 : nobs
  h5write(file1, '/rad', single(rtmp(:,i)), [1,i], [nchan,1]);
end
toc

k = 100;
tic
for i = 1 : k : nobs
  t = min(i+k-1, nobs);
  s = i : t;
  h5write(file1, '/rad', single(rtmp(:,s)), [1,i], [nchan,length(s)]);
end
toc

tic
h5write(file2, '/rad', single(rtmp));
toc

% h5write(tfull, '/tai93',   s,   s, c);
% h5write(tfull, '/lat',      single(lat(j)), s, c);
% h5write(tfull, '/lon',      single(lon(j)), s, c);
% h5write(tfull, '/sat_zen',  sat_zen(j),     s, c);
% h5write(tfull, '/sol_zen',  sol_zen(j),     s, c);
% h5write(tfull, '/asc_flag', uint8(asc_flag(j)), s, c);

% d1 = read_netcdf_h5(tfull);



