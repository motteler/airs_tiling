
% fixed AIRS parameters
nchan = 2645;  % L1c channels
nobs = 90 * 135;    % xtrack x atrack obs

% initial empty netCDF file
nc_init = './airs_tile.nc';

tfull = './tile_test.nc';

copyfile(nc_init, tfull)

rtmp = ones(2645,1) * -1;

h5write(tfull, '/rad', single(rtmp), [1,2], [nchan,1]);

% h5write(tfull, '/tai93',   s,   s, c);
% h5write(tfull, '/lat',      single(lat(j)), s, c);
% h5write(tfull, '/lon',      single(lon(j)), s, c);
% h5write(tfull, '/sat_zen',  sat_zen(j),     s, c);
% h5write(tfull, '/sol_zen',  sol_zen(j),     s, c);
% h5write(tfull, '/asc_flag', uint8(asc_flag(j)), s, c);

d1 = read_netcdf_h5(tfull);

%----------------------------------------------------------

p1 = '/asl/isilon/airs/tile_test/N49p50';
t1 = 'airs_test_tile_2020_s02_N49p50_E030p00.nc';
f1 = fullfile(p1,t1);
d1 = read_netcdf_h5(f1);

p1 = '/asl/lustre/airs/tile_test/N49p50';
t1 = 'airs_test_tile_2018_s16_N49p50_E030p00.nc';
f1 = fullfile(p1,t1);
d1 = read_netcdf_h5(f1);

p1 = '/asl/lustre/airs/tile_test/N81p75';
t1 = 'airs_test_tile_2018_s16_N81p75_W025p00.nc';
f1 = fullfile(p1,t1);
d1 = read_netcdf_h5(f1);

