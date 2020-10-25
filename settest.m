
for y = 2002 : 2020

  [s1, s2] = setspan(y);

  d1 = set2dlist(s1);
  d2 = set2dlist(s2);

  fprintf(1, '%d %02d %s %s %s %s\n', y, s2 - s1 + 1, ...
    datestr(d1(1)), datestr(d1(end)), datestr(d2(1)), datestr(d2(end)))

end

