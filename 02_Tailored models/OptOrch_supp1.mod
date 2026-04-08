#OptOrch_supp1.mod
#Constraints
s.t. selectiondependentbounds {i in S}: 
     p[i] == 0 or l[i] <= p[i] <= u[i];