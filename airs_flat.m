%
% NAME
%   airs_flat - flatten an AIRS granule into lists
%
% SYNOPSIS
%   [d2, a2] = airs_flat(airs_gran)
%
% INPUTS
%   airs_gran  - AIRS input granule file
%
% OUTPUTS
%   d2  - flattened AIRS data
%   a2  - optional AIRS attributes
%
% DISCUSSION
%   derived from the first part of airs2chirp
%   returns the empty struct for d2 on read errors or no data
%
% AUTHOR
%  H. Motteler, 1 Aug 2020
%

function [d2, a2] = airs_flat(airs_gran)

%--------------------------
% setup and default options
%---------------------------

% default parameters
verbose = 0;                  % 0=quiet, 1=talky, 2=plots
synlim = 0.15;                % syn channel warn threshold

% fixed AIRS parameters
nchan = 2645;  % L1c channels
nobs = 90 * 135;    % xtrack x atrack obs

% this function name
fstr = mfilename;  

% initialize outputs
d2 = struct([]);
a2 = struct([]);

% check for a source file 
if exist(airs_gran) ~= 2
  fprintf(1, '%s: missing source file %s\n', fstr, airs_gran)
  return
end

%---------------------
% read the AIRS data
%---------------------
try
  [d1, a2] = read_airs_h4(airs_gran);
catch
  fprintf(1, '%s: could not read %s\n', fstr, airs_gran)
  return
end

% get the AIRS granule number
% [~, gstr, ~] = fileparts(airs_gran);
% gran_num = str2double(gstr(17:19));
gran_num = double(a2.granule_number);

%----------------------------------
% reshape and rename the AIRS data
%----------------------------------

% initialize the output struct
d2 = struct;

% per-granule values
d2.wnum = d1.nominal_freq;
nsynth  = double(d1.L1cNumSynth);

% nchan x xtrack x atrack to nchan x nobs
d2.rad  = reshape(d1.radiances, [nchan, nobs]);
nedn    = reshape(d1.NeN,       [nchan, nobs]);

% xtrack x atrack to nobs
d2.obs_time_tai93   = reshape(d1.Time,      nobs, 1);
d2.obs_time_utc     = tai93_to_utc(d2.obs_time_tai93);
d2.lat              = reshape(d1.Latitude,  nobs, 1);
d2.lon              = reshape(d1.Longitude, nobs, 1);
d2.view_ang         = abs(reshape(d1.scanang,   nobs, 1));
d2.sat_zen          = reshape(d1.satzen,    nobs, 1);
d2.sat_azi          = reshape(d1.satazi,    nobs, 1);
d2.sol_zen          = reshape(d1.solzen,    nobs, 1);
d2.sol_azi          = reshape(d1.solazi,    nobs, 1);
d2.land_frac        = reshape(d1.landFrac,  nobs, 1);
d2.surf_alt         = reshape(d1.topog,     nobs, 1);
d2.surf_alt_sdev    = reshape(d1.topog_err, nobs, 1);
d2.instrument_state = reshape(d1.state,     nobs, 1);

% atrack to nobs (copy values across scans)
d2.subsat_lat     = reshape(repmat(d1.sat_lat',   90, 1), nobs, 1);
d2.subsat_lon     = reshape(repmat(d1.sat_lon',   90, 1), nobs, 1);
d2.scan_mid_time  = reshape(repmat(d1.nadirTAI',  90, 1), nobs, 1);
d2.sat_alt        = reshape(repmat(d1.satheight', 90, 1), nobs, 1) * 1000;
d2.sun_glint_lat  = reshape(repmat(d1.glintlat',  90, 1), nobs, 1);
d2.sun_glint_lon  = reshape(repmat(d1.glintlon',  90, 1), nobs, 1);
d2.asc_flag       = reshape(repmat(d1.scan_node_type', 90, 1), nobs, 1);

% clear d1

% basic AIRS atrack and xtrack indices
% airs_atrack = reshape(repmat(1:135, 90, 1), nobs, 1);
% airs_xtrack = reshape(repmat((1:90)', 1, 135), nobs, 1);

% CrIS-style 3 x 3 tiling (from Evan Manning)
% atrack = floor((airs_atrack - 1) / 3) + 1;
% xtrack = floor((airs_xtrack - 1) / 3) + 1;
% fov = mod(airs_xtrack-1, 3) + 3 * mod(airs_atrack-1, 3) + 1;

% generate an obs_id for AIRS 
% obs_id = airs_obs_id(obs_time_utc, airs_atrack, airs_xtrack);

synfrac = nsynth / max(nsynth);
synfrac = abs(synfrac);
synfrac(synfrac > 1) = 1;

% sOK is true if the synthetic fraction is within acceptable limits
sOK = synfrac < synlim;

% translate sOK to NASA-style 3-value flags, 0=OK, 1=warn, 2=bad
chan_qc = ~sOK;

% true if geo, radiance, and instrument_state are all OK
iOK = -90 <= d2.lat & d2.lat <= 90 & -180 <= d2.lon & d2.lon <= 180 ...
      & cAND(-1 < d2.rad & d2.rad < 250)' & d2.instrument_state == 0;

% translate iOK to NASA-style flags, 0=OK, 1=warn, 2=bad.  
% Note rad_qc set this way does not give a "warn"; just OK or bad.
rad_qc = ~iOK * 2;

% copy out QC fields
d2.synfrac = synfrac;
d2.chan_qc = chan_qc;
d2.rad_qc = rad_qc;

% take the mean of valid NEdN values over the full granule
nOK = zeros(nchan, 1);
sOK = zeros(nchan, 1);
for j = 1 : nobs
  iOK = nedn(:, j) < 2;  % flag per-obs valid NEdN values
  nOK = nOK + iOK;
  sOK = sOK + iOK .* nedn(:, j);
end
jOK = nOK > 0;         % flag valid AIRS NEdN values
ntmp1 = sOK ./ nOK;    % mean of all AIRS NEdN values

% interpolate the missing values
ntmp2 = interp1(d2.wnum(jOK), ntmp1(jOK), d2.wnum, 'linear', 'extrap');

% copy out granule average
d2.nedn = ntmp2;

% QC summary checks
radOK = sum(d2.rad_qc == 0);
if radOK == 0
  fprintf(1, '%s: granule %d no valid obs\n', gran_num, fstr)
  d2 = struct([]);
  return
elseif radOK < nobs
  fprintf(1, '%s: granule %d %d/%d valid obs\n', fstr, gran_num, radOK, nobs)
end

chanBAD = sum(d2.chan_qc == 2);
if chanBAD == nchan
  fprintf(1, '%s: granule %d no valid channels\n', gran_num, fstr)
  d2 = struct([]);
  return
end
