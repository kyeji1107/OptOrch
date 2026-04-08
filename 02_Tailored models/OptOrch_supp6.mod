#OptOrch_supp6.mod
#Parameters
param np > 0;
param C > 0, < 1;

#Constraints
s.t. effectivecontribution:
     sum {i in S} p[i] = 1 - C/2;
s.t. contamstatusnumber:
     sum {i in S, j in S} c[i,j] * p[i] * p[j] <= (1 / (2 * ns)) - (C^2 / (8 * np)); 