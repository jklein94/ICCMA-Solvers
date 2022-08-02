%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Encoding for ideal sets that are complete
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Guess a set S \subseteq A
in(X) :- not out(X), arg(X).
out(X) :- not in(X), arg(X).

%% S has to be conflict-free
:- in(X), in(Y), att(X,Y).

%% The argument x is defeated by the set S
defeated(X) :- in(Y), att(Y,X).

%% The argument x is not defended by S
not_defended(X) :- att(Y,X), not defeated(Y).

%% admissible
:- in(X), not_defended(X).

%% Every argument which is defended by S belongs to S
:- out(X), not not_defended(X).

not_trivial :- in(Y).

%% Guess a set E \subseteq A attacking S
sAtt(X) : in(X) :- not_trivial.
spoil | sIn(Y) : att(Y,X) :- sAtt(X).
spoil | sIn(Z) : att(Z,Y) :- sIn(X), att(Y,X).
spoil :- sIn(X), sIn(Y), att(X,Y).
sIn(X) :- spoil, arg(X).
sAtt(X) :- spoil, arg(X).
:- not spoil, not_trivial.

#show in/1.
