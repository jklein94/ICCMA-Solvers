%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Encoding for complete extensions with specific range
% 
% Range is given by undec() atoms in the input
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Guess in and out but no undec
in(X) :- arg(X), not out(X), not undec(X).
out(X) :- arg(X), not in(X), not undec(X).


%% An argument is in the complete extension if all attackers are labelled out
in(X):-arg(X), out(Y):att(Y,X).

% An attacker of an in argument is out
out(X):- in(Y), att(X,Y).

%% An argument is labelled out if one of its attackers is labelled in 
out(X):-in(Y), att(Y,X).

%% One attacker of each out argument has to be in
in(Y):att(Y,X) :-out(X).

%% Each argument has a unique label.
:- arg(X), in(X), out(X).
:- arg(X), in(X), undec(X).
:- arg(X), undec(X), out(X).

#show in/1.
%#show stbExt.

