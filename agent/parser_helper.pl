:- module(parser_helper, [clean_action_string/2]).

%% clean_action_string(+Raw, -Clean)
%% Strips Markdown code blocks, trims whitespace, and extracts canonical (action ...)
clean_action_string(Raw, Clean) :-
    atom_string(RawAtom, Raw),
    % Search for (action substring
    (   sub_atom(RawAtom, Before, _, _, '(action ')
    ->  sub_atom(RawAtom, Before, _, 0, FromAction),
        % Find the last closing parenthesis across the entire string
        (   findall(P, sub_atom(FromAction, P, 1, _, ')'), Parens),
            Parens \= []
        ->  last(Parens, LastParen),
            Len is LastParen + 1,
            sub_atom(FromAction, 0, Len, _, ActionAtom),
            atom_string(ActionAtom, Clean)
        ;   atom_string(FromAction, Clean)
        )
    ;   % If no (action found, normalize spaces and strip
        normalize_space(atom(Trimmed), RawAtom),
        atom_string(Trimmed, Clean)
    ).
