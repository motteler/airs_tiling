%
% simple compression check
%

addpath /home/motteler/shome/chirp_test
addpath /home/motteler/cris/ccast/motmsc/utils
addpath /home/motteler/cris/ccast/motmsc/time
addpath /home/motteler/cris/ccast/source

% profile clear
% profile on

p1 = '/asl/isilon/airs/tile_test7/2011_s212/N70p75';
t1 = 'tile_2011_s212_N70p75_W095p00.nc';
f1 = fullfile(p1, t1);

p2 = './';
t2 = 'test1.nc';
f2 = fullfile(p2, t2);

% tic
[s,w] = unix(sprintf('nccopy -d 4 %s %s', f1, f2));
% toc
if s ~= 0, error(w), end

t1 = dir(f1);
t2 = dir(f2);
fprintf(1, 'compressed size %.2f pct\n', t2.bytes/t1.bytes)

[d1, a1] = read_netcdf_h5(f1);
[d2, a2] = read_netcdf_h5(f2);

if ~isequal(d1, d2), error('compressed data differs'), end
if ~isequal(a1, a2), error('compressed attributes differ'), end

% profile report

% show deflate level
info1 = ncinfo(f1);
info2 = ncinfo(f2);
info2.Variables(8)
