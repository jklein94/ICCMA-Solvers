%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Encoding for semi-stable extensions
%  
%  Uses clingo heuristics to compute a semi-stable extension.
%
%  Use for Enumeration is limited as for each range set it only computes one extension.
%
%  CLingo call:
%
%  > ./clingo --heuristic=domain --enum=domRec --out-hide af_instance.dl semi.dl 0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% We first define complete labellings

%in(X):-not block(X), arg(X).
%block(X):-not out(Y),att(Y,X).

%% Guess a label for each argument
in(X) | out(X) | undec(X) :- arg(X).

%% If all attackers are out the argument is in
in(X):-arg(X), out(Y):att(Y,X).

%% An argument attacked by an in argument is out
out(X):-in(Y), att(Y,X).

%% If an argument is in then all of its attackers must be out
:- in(X),not out(Y), att(Y,X).

%% If an argument is out then one of its attackers must be in
:- out(X),not in (Y): att(Y,X).

%% Each argument has exactly one label
:- in(X),out(X).
:- undec(X),out(X).
:- undec(X),in(X).

%%% We now apply heuristics to get the complete labeling with subset-minimal undec(.) se

#heuristic undec(X):arg(X). [2,false]

%#show.
#show undec/1.
#show in/1.
%#show out/1.
