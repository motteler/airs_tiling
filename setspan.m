%
% setspan - return AIRS 16-day setnums spanning a year
%

function [s1, s2] = setspan(year)

% AIRS 16-day set start date
abase = datenum('1 sep 2002');

% datenums for all set starts
aseq = abase + ((1:500) - 1) * 16;

% years alone for all set starts
dvec = datevec(aseq);
yseq = dvec(:, 1);

% sets that start in the selected year
ix = find(yseq == year);

s1 = ix(1);
s2 = ix(end);

% s1 never falls on falls on 1 Jan during the AIRs mission, so to
% cover the tail from the previous year, we can simply decrement it.
if year > 2002
  s1 = s1 - 1;
end

