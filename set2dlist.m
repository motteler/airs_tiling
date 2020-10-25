%
%  set2dlist -- take AIRS 16-day set number to datenum list
%

function dlist = set2dlist(iset);

% AIRS 16-day set start date
abase = datenum('1 sep 2002');

d1 = abase + (iset - 1) * 16;
d2 = abase + (iset) * 16 - 1;

dlist = d1 : d2;

