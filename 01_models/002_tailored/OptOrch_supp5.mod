#OptOrch_supp5.mod
#Parameters and sets
param nd > 0;

#Constraints
s.t. nofemaleexternal {i in (nc-nd+1)..nc}: f[i] = 0;
s.t. orchardparent {i in 1..(nc-nd)}: p[i] = (f[i]+m[i])/2;
# External donors contribute only through the paternal gametic pool.
# Because the paternal contribution represents one-half of the seed-crop
# gene pool, their effective total contribution is p[i] = m[i]/2.
s.t. externaldonor {i in (nc-nd+1)..nc}: p[i] = m[i]/2;
