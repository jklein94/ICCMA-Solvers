%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Encoding for stage extensions
%  
%  Uses clingo heuristics to compute a stage extension.
%
%  Use for Enumeration is limited as for each range set it only computes one extension.
%
%  CLingo call:

%  >./clingo --heuristic=domain --enum=domRec --out-hide af_instance.dl stage.dl 0
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% We first define conflict-free labellings

%% Guess a label for each argument
in(X) | out(X) | undec(X) :- arg(X).

%% An argument attacked by an in argument is out
out(X):-in(Y), att(Y,X).

%% If an argument is out then one of its attackers must be in
:- out(X),not in (Y): att(Y,X).

%% Each argument has exactly one label
:- in(X),out(X).
:- undec(X),out(X).
:- undec(X),in(X).

%% the set in(.) must be conflict-free (redundant rule)
:- in(X),att(X,Y),in(Y).

%%% We now apply heuristics to get the conflict-free labeling with subset-minimal undec(.) set

#heuristic undec(X):arg(X). [1,false]

range.
#show range.
#show undec/1.
