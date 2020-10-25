%
% airs_glist - clean up an AIRS L1c directory
%
% SYNOPSIS
%   glist = airs_glist(adir)
%
% INPUT
%   adir  - AIRS 1-day granule directory
%
% OUTPUT
%   glist - matlab dir struct with duplicates removed
%
% DISCUSSION
%   AIRS.2013.08.18.010.L1C.AIRS_Rad.v6.7.2.0.G20028025441.hdf
%   AIRS.2013.08.18.011.L1C.AIRS_Rad.v6.7.2.0.G20028025442.hdf
%   AIRS.2013.08.18.012.L1C.AIRS_Rad.v6.7.2.0.G20028025442.hdf
%   12345678901234567890123456789012345678901234567890123456789
%   0        1         2         3         4         5
%

function glist = airs_glist(adir)

% our function name
fstr = mfilename;

% get the initial list of files
glist = dir(fullfile(adir, 'AIRS.*.L1C.AIRS_Rad.*.hdf'));

if isempty(glist)
  fprintf(1, '%s: no files found in %s\n', fstr, adir)
  return
end

% use the last value if we have duplicate start times
tlist = {};
qlist = glist;
n1 = length(glist);
for j = 1 : n1
  tlist{j} = glist(j).name(6:19);
end
[~, ix] = unique(tlist, 'last');
glist = glist(ix);
n2 = length(glist);

if n2 < n1
  fprintf(1, '%s: dropping %d duplicate file(s):\n', fstr, n1 - n2)
  for j = setdiff(1:n1, ix)
    fprintf(1, '%s\n', qlist(j).name)
  end
end

if isempty(glist)
  fprintf(1, '%s: no valid files in %s\n', fstr, rdir)
end

