:- module(memory_io, [
    save_records_from_space/3,
    load_records_into_space/3,
    sub_string_match/3,
    is_sensitive_text/2,
    get_timestamp/1,
    clear_storage_file/2,
    compute_record_relevance/5,
    rank_records_in_space/5,
    detect_preference_conflict/3,
    detect_statement_conflict/4,
    string_length_utf8/2,
    truncate_string_to_budget/3,
    find_preference_conflicts_in_space/2,
    find_statement_conflicts_in_space/3
]).

% Safe serialization of memory atoms from an AtomSpace to disk file
save_records_from_space(FilePath, Space, Count) :-
    open(FilePath, write, Out, [encoding(utf8)]),
    findall(['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, St],
            'match'(Space, ['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, St],
                           ['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, St], _),
            Atoms),
    sort(Atoms, UniqueAtoms),
    length(UniqueAtoms, Count),
    forall(member(['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, St], UniqueAtoms),
           (   writeq(Out, mem_rec(Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, St)),
               format(Out, ".~n", [])
           )),
    close(Out).

% Safe loading of records into space with malformed record resilience
load_records_into_space(FilePath, Space, Count) :-
    (   \+ exists_file(FilePath)
    ->  Count = 0
    ;   open(FilePath, read, In, [encoding(utf8)]),
        read_lines_and_insert(In, Space, 0, Count),
        close(In)
    ).

read_lines_and_insert(In, Space, Acc, Count) :-
    read_line_to_string(In, Line),
    (   Line == end_of_file
    ->  Count = Acc
    ;   % Safely parse term from line without executing and skipping syntax errors
        (   catch(read_term_from_atom(Line, Term, [syntax_errors(quiet)]), _, fail),
            Term = mem_rec(Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, St)
        ->  Atom = ['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, St],
            (   'match'(Space, ['MemoryRecord', _, Cat, _, Content, _, _, _, _, _, active], found, _)
            ->  Acc1 = Acc
            ;   'add-atom'(Space, Atom, _),
                Acc1 is Acc + 1
            )
        ;   Acc1 = Acc
        ),
        read_lines_and_insert(In, Space, Acc1, Count)
    ).

% Case-insensitive substring matching
sub_string_match(Haystack, Needle, true) :-
    downcase_atom(Haystack, HLower),
    downcase_atom(Needle, NLower),
    sub_atom(HLower, _, _, _, NLower), !.
sub_string_match(_, _, false).

% Detection of sensitive information or secret keys
is_sensitive_text(Text, true) :-
    downcase_atom(Text, L),
    (   sub_atom(L, _, _, _, "api_key")
    ;   sub_atom(L, _, _, _, "sk-")
    ;   sub_atom(L, _, _, _, "aiza")
    ;   sub_atom(L, _, _, _, "password")
    ;   sub_atom(L, _, _, _, "secret")
    ;   sub_atom(L, _, _, _, "bearer ")
    ;   sub_atom(L, _, _, _, "token=")
    ), !.
is_sensitive_text(_, false).

% Get integer UNIX timestamp
get_timestamp(Timestamp) :-
    get_time(T),
    Timestamp is round(T).

% Empty file
clear_storage_file(FilePath, true) :-
    (   exists_file(FilePath)
    ->  open(FilePath, write, Stream, [encoding(utf8)]),
        close(Stream)
    ;   true
    ).

% Keyword tokenization for semantic matching
tokenize_to_keywords(Text, Keywords) :-
    split_string(Text, " \t\n,?.!;:()[]\"'", " \t\n,?.!;:()[]\"'", RawTokens),
    StopWords = ["the", "a", "an", "is", "in", "of", "that", "to", "my", "your",
                 "me", "for", "what", "and", "with", "are", "was", "were", "it",
                 "this", "please", "can", "you", "tell", "about", "our"],
    findall(T, (member(Raw, RawTokens),
                string_lower(Raw, Lower),
                atom_string(T, Lower),
                atom_length(T, L),
                L >= 3,
                \+ member(T, StopWords)),
            Keywords).

count_matching_keywords([], _, Acc, Acc).
count_matching_keywords([K|Ks], Text, Acc, Count) :-
    (   sub_atom(Text, _, _, _, K)
    ->  Acc1 is Acc + 1
    ;   Acc1 = Acc
    ),
    count_matching_keywords(Ks, Text, Acc1, Count).

% Record relevance scoring
compute_record_relevance(Content, Query, Priority, _Timestamp, Score) :-
    downcase_atom(Content, C),
    downcase_atom(Query, Q),
    (   (Q == '' ; Q == '*' ; Q == 'all' ; Q == 'any')
    ->  Base = 50
    ;   C == Q
    ->  Base = 100
    ;   sub_atom(C, _, _, _, Q)
    ->  Base = 80
    ;   tokenize_to_keywords(Q, Keywords),
        Keywords \= [],
        count_matching_keywords(Keywords, C, 0, Matched),
        Matched > 0
    ->  length(Keywords, Total),
        Base is round(35 + 35 * (Matched / Total))
    ;   Base = 0
    ),
    (   Base > 0
    ->  (   integer(Priority) -> P = Priority ; P = 1 ),
        PrioBonus is min(15, max(0, (P - 1) * 3)),
        Score is Base + PrioBonus
    ;   Score = 0
    ).

% Rank active records from space
rank_records_in_space(Space, Query, CatFilter, Limit, RankedResults) :-
    downcase_atom(CatFilter, CatLower),
    findall(['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, active],
            'match'(Space, ['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, active],
                           ['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, active], _),
            AllActive),
    sort(AllActive, UniqueActive),
    filter_by_category(UniqueActive, CatLower, Eligible),
    score_and_wrap(Eligible, Query, ScoredList),
    sort(ScoredList, SortedDesc),
    take_n(Limit, SortedDesc, TopItems),
    unwrap_items(TopItems, RankedResults).

filter_by_category([], _, []).
filter_by_category([['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, active]|Rest], Filter, Eligible) :-
    downcase_atom(Cat, CLower),
    (   (Filter == all ; Filter == any ; Filter == CLower)
    ->  Eligible = [['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, active]|RestEligible]
    ;   Eligible = RestEligible
    ),
    filter_by_category(Rest, Filter, RestEligible).

score_and_wrap([], _, []).
score_and_wrap([['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, active]|Rest], Query, Scored) :-
    compute_record_relevance(Content, Query, Prio, Cr, Score),
    score_and_wrap(Rest, Query, RestScored),
    (   Score > 0
    ->  NegScore is -Score,
        (   integer(Cr) -> NegCr is -Cr ; NegCr = 0 ),
        Scored = [cand(NegScore, NegCr, Id, Score, ['MemoryRecord', Id, Cat, Type, Content, Cr, Up, Src, Prio, Tags, active])|RestScored]
    ;   Scored = RestScored
    ).

take_n(N, _, []) :- N =< 0, !.
take_n(_, [], []) :- !.
take_n(N, [X|Xs], [X|Rest]) :-
    N1 is N - 1,
    take_n(N1, Xs, Rest).

unwrap_items([], []).
unwrap_items([cand(_, _, _, Score, Record)|Rest], [['RankedMemory', Score, Record]|RestUnwrapped]) :-
    unwrap_items(Rest, RestUnwrapped).

% String length helper
string_length_utf8(String, Len) :-
    atom_string(Atom, String),
    atom_length(Atom, Len).

% Truncate string to budget
truncate_string_to_budget(Input, MaxLen, Output) :-
    atom_string(Atom, Input),
    atom_length(Atom, Len),
    (   Len =< MaxLen
    ->  Output = Input
    ;   MaxLen > 3
    ->  SubLen is MaxLen - 3,
        sub_atom(Atom, 0, SubLen, _, Sub),
        atom_concat(Sub, "...", TruncAtom),
        atom_string(TruncAtom, Output)
    ;   sub_atom(Atom, 0, MaxLen, _, Sub),
        atom_string(Sub, Output)
    ).

% Preference conflicts
opposite_preference_terms("concise", "detailed").
opposite_preference_terms("concise", "verbose").
opposite_preference_terms("brief", "detailed").
opposite_preference_terms("short", "long").
opposite_preference_terms("dark mode", "light mode").
opposite_preference_terms("dark theme", "light theme").
opposite_preference_terms("formal", "casual").
opposite_preference_terms("formal", "informal").

detect_preference_conflict(Text1, Text2, true) :-
    downcase_atom(Text1, T1),
    downcase_atom(Text2, T2),
    (   opposite_preference_terms(A, B),
        (   (sub_atom(T1, _, _, _, A), sub_atom(T2, _, _, _, B))
        ;   (sub_atom(T1, _, _, _, B), sub_atom(T2, _, _, _, A))
        )
    ), !.
detect_preference_conflict(_, _, false).

detect_statement_conflict(Statement, ExistingText, preference, true) :-
    detect_preference_conflict(Statement, ExistingText, true), !.
detect_statement_conflict(_, _, _, false).

% Find all preference conflict pairs in space
find_preference_conflicts_in_space(Space, Conflicts) :-
    findall(['PreferenceConflict', Id1, Id2, C1, C2],
            ( 'match'(Space, ['MemoryRecord', Id1, preference, _, C1, _, _, _, _, _, active],
                             ['MemoryRecord', Id1, preference, _, C1, _, _, _, _, _, active], _),
              'match'(Space, ['MemoryRecord', Id2, preference, _, C2, _, _, _, _, _, active],
                             ['MemoryRecord', Id2, preference, _, C2, _, _, _, _, _, active], _),
              Id1 @< Id2,
              detect_preference_conflict(C1, C2, true)
            ),
            RawList),
    sort(RawList, Conflicts).

% Find conflicts between a statement and records in space
find_statement_conflicts_in_space(Space, Statement, Conflicts) :-
    findall(['StatementConflict', Id, C, Statement],
            ( 'match'(Space, ['MemoryRecord', Id, preference, _, C, _, _, _, _, _, active],
                             ['MemoryRecord', Id, preference, _, C, _, _, _, _, _, active], _),
              detect_statement_conflict(Statement, C, preference, true)
            ),
            RawList),
    sort(RawList, Conflicts).
