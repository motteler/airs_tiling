%
% set2dlist -- take 16-day set number to doy list
%

function dlist = set2dlist(year, iset);

if ~(1 <= iset & iset <= 23)
  error(sprintf('iset = %g out of range\n', iset))
end

if ~isleap(year) 
  yend = 365; 
else 
  yend = 366; 
end

dlist = (iset - 1) * 16 + 1 : iset * 16;

if dlist(end) > yend
  dlist = dlist(1) : yend;
end

