#OptOrch_supp6.mod
#Parameters
param nd > 0;
param C > 0, < 1;

#Constraints
s.t. effectivecontribution:
     sum {i in S} p[i] = 1 - C/2;
s.t. contamstatusnumber:
     sum {i in S, j in S} c[i,j] * p[i] * p[j] <= (1 / (2 * ns)) - (C^2 / (8 * nd)); 
# These constraints replace the corresponding total-contribution and status-number constraints in OptOrch_core.mod.
# They should not be imposed simultaneously with the original versions of those constraints.
