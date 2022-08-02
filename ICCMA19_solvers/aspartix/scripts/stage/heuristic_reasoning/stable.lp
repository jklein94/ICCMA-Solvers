%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Encoding for conflict-free set with specific range
% 
% Range is given by undec() atoms in the input
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Encoding for stable extensions
% using conditional literals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

in(Y) :- arg(Y), not undec(Y), not in(X): att(X,Y).
:- in(X), undec(Y), att(X,Y).
stbExt.

%#show stbExt.
#show in/1.
