#OptOrch.mod
#Parameters and sets
param nc > 0;
set S := 1..nc by 1;
param ns > 0;
param b {i in S};
param l {i in S} >= 0, <= 1;
param u {i in S} >= 0, <= 1;
param c {i in S, j in S};

#Variables
var p {i in S} >= 0, <= 1;
var r {i in S} binary; 

#Objective function
maximize gain: sum{i in S} b[i] * p[i];

#Constraints
s.t. c1: sum {i in S,j in S} 
     c[i,j] * p[i] * p[j] <= 1/(2*ns);
s.t. c2: sum {i in S} p[i] = 1;
s.t. c3a {i in S}: p[i] >= r[i] * l[i];
s.t. c3b {i in S}: p[i] <= r[i] * u[i];

