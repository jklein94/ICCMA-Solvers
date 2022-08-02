%
% Compute the cone of influence
%
%coneArg(a129).

coneAtt(X,Y):- coneArg(Y), att(X,Y).
coneArg(X) :- coneAtt(X,Y).

#show coneArg/1. 
#show coneAtt/2. 
