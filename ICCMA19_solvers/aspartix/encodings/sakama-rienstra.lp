%
% Encoding adapted from
% Chiaki Sakama, Tjitze Rienstra:
% Representing Argumentation Frameworks in Answer Set Programming. Fundam. Inform. 155(3): 261-292 (2017)
% 

% each argument is either (i) defended ("IN"), (ii) defeated ("OUT"), or (iii) both ("UNDECIDED").
defended(X) | defeated(X) :- arg(X).

% an argument is defended if all its attackers are defeated
defended(X) :- arg(X), defeated(Y) : att(Y,X).

% an argument is defeated if one of its attackers is defended
defeated(X) :- defended(Y), att(Y,X).

% a defended argument cannot have a non-defeated attacker
:- defended(X), not defeated(Y), att(Y,X).

% a defeated argument cannot have all its attackers not defended
:- defeated(X), not defended(Y) : att(Y,X).

% preferred extensions
in(X) :- defended(X), not defeated(X).


#show in/1.
