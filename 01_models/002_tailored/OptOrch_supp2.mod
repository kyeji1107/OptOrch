#OptOrch_supp2.mod
#Parameters and sets
param cu >= 0, <= 1;

#Constraints
s.t. pairwisecoancestry {i in S, j in S: i < j}:
     if (p[i] * p[j]) > 0 then c[i,j] <= cu;
