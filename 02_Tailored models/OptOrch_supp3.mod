#OptOrch_supp3.mod
#Variables
var y {i in S, j in S} binary;

#Constraints
s.t. pairwiseexcludej {i in S, j in S : i < j and c[i,j] > cu}: 
p[j] <= 1 - y[i,j];
s.t. pairwiseexcludei {i in S, j in S : i < j and c[i,j] > cu}: 
p[i] <= y[i,j];
