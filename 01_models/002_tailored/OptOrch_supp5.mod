#OptOrch_supp5.mod
#Parameters and sets
param nd > 0;

#Constraints
s.t. nofemaleexternal {i in (nc-nd+1)..nc}: f[i] = 0;
s.t. orchardparent {i in 1..(nc-nd)}: p[i] = (f[i]+m[i])/2;
s.t. externaldonor {i in (nc-nd+1)..nc}: p[i] = m[i];
