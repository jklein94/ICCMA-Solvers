%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some comp-encoding which gives in out undec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


in(X)|out(X)|undec(X) :- arg(X).
:- in(X), out(X).
:- in(X), undec(X).
:- out(X), undec(X).

% X is in iff all attackers are out
in(X) :- arg(X), out(Y) : att(Y,X).
:- in(X), arg(Y), not out(Y), att(Y,X).

% X is out iff exists attacker which is in
out(X) :- in(Y), att(Y,X).
exists_in_attacker(X) :- in(Y), att(Y,X).
:- out(X), not exists_in_attacker(X).



#show in/1.
%#show out/1.
#show undec/1.
