:- module(persistence_helper, [write_atom_to_file/3, clear_file/2]).

clear_file(FilePath, true) :-
    open(FilePath, write, Stream, [encoding(utf8)]),
    close(Stream).

write_atom_to_file(FilePath, AtomString, true) :-
    open(FilePath, append, Stream, [encoding(utf8)]),
    format(Stream, "~w~n", [AtomString]),
    close(Stream).
