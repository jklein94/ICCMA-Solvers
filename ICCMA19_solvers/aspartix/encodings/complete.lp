%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Encoding for complete extensions
%
% using conditional literals in the body of the rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% An argument is in the complete extension if all attackers are labelled out
in(X):-arg(X), defeated(Y):att(Y,X).

%% An argument is labelled out if one of its attackers is labelled in 
defeated(X):-in(Y), att(Y,X).
out(X):-defeated(X).


%% Guess a set S \subseteq A
in(X) :- not out(X), arg(X).
out(X) :- not in(X), arg(X).

%% S has to be conflict-free
:- in(X), defeated(X).

%% The argument x is not defended by S
:- in(X), att(Y,X), not defeated(Y).
#show in/1.
