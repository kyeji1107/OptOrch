#OptOrch_supp4.mod
#Variables
var f {i in S} >= 0, <= 1;
var m {i in S} >= 0, <= 1;

#Contraints
s.t. femaleandmalecontribution {i in S}: p[i] = (f[i]+m[i])/2;