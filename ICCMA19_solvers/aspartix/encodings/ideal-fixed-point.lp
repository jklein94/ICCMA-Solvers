%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Computes the ideal Extension when given an AF 
% together with its credulously accepted arguments
%
% Credulously accepted arguments are stored om the credIn/1 predicate
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%  Compute arguments not in the ideal extension

% Arguments that are not credulously accepted are not in the ideal extension
out(X) :- arg(X), not credIn(X).

%% Arguments that are credulously attacked are not in the ideal extension 
% we get these out already from the credulouse acceptance
% out(X) :- credIn(Y), att(Y,X).

% If all attackers of an argument X are out then none of the arguments attacked by X can be in the ideal extension
undefeated_attacker(X) :- arg(X), out(Y) : att(Y,X).
out(Z) :- arg(Z), att(X,Z), undefeated_attacker(X).

in(X) :- arg(X), not out(X).
#show in/1.

dummy(arg).
#show dummy/1.