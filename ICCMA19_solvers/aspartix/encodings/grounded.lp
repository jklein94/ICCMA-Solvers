%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Encoding for grounded extension
%
% using conditional literals in the body of the rules
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% An argument is in the grounded extension if all attackers are labelled out
in(X):-arg(X), defeated(Y):att(Y,X).

% An argument is labelled out if one of its attackers is labelled in 
defeated(X):-arg(X), in(Y), att(Y,X).

% If used as part of other semantics' encodings
% out(X):-defeated(X).

#show in/1.
