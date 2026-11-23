:- module(tool_primitives, [
    eval_math_expression/2,
    count_words/2,
    analyze_text/2,
    reverse_string/2,
    get_current_datetime_str/1
]).

%% is_safe_arithmetic(+Term)
%% Allowlist of pure arithmetic operators and numbers only.
is_safe_arithmetic(N) :- number(N), !.
is_safe_arithmetic(+ A) :- is_safe_arithmetic(A), !.
is_safe_arithmetic(- A) :- is_safe_arithmetic(A), !.
is_safe_arithmetic(A + B) :- is_safe_arithmetic(A), is_safe_arithmetic(B), !.
is_safe_arithmetic(A - B) :- is_safe_arithmetic(A), is_safe_arithmetic(B), !.
is_safe_arithmetic(A * B) :- is_safe_arithmetic(A), is_safe_arithmetic(B), !.
is_safe_arithmetic(A / B) :- is_safe_arithmetic(A), is_safe_arithmetic(B), !.

%% eval_math_expression(+Input, -Result)
eval_math_expression(Input, Result) :-
    (   number(Input)
    ->  Result = Input
    ;   atom_string(Atom, Input),
        catch(term_string(Term, Atom), _, fail),
        is_safe_arithmetic(Term)
    ->  catch(
            ( Val is Term,
              ( integer(Val) -> Result = Val ; Result is float(Val) )
            ),
            error(evaluation_error(zero_divisor), _),
            Result = "error: division by zero"
        )
    ;   Result = "error: malformed or unsupported mathematical expression"
    ).

%% count_words(+Input, -Count)
count_words(Input, Count) :-
    atom_string(Atom, Input),
    (   Atom == ''
    ->  Count = 0
    ;   split_string(Atom, " \t\n\r", " \t\n\r", Words),
        length(Words, Count)
    ).

%% analyze_text(+Input, -StatsList)
analyze_text(Input, [text_stats, CharCount, WordCount, LineCount, SentenceCount]) :-
    atom_string(Atom, Input),
    string_length(Atom, CharCount),
    (   CharCount == 0
    ->  WordCount = 0,
        LineCount = 0,
        SentenceCount = 0
    ;   split_string(Atom, " \t\n\r", " \t\n\r", Words),
        length(Words, WordCount),
        split_string(Atom, "\n", "", Lines),
        length(Lines, LineCount),
        split_string(Atom, ".!?", " \t\n\r", Sentences),
        length(Sentences, SentenceCount)
    ).

%% reverse_string(+Input, -Reversed)
reverse_string(Input, Reversed) :-
    atom_string(Atom, Input),
    atom_chars(Atom, Chars),
    reverse(Chars, RevChars),
    atom_chars(RevAtom, RevChars),
    atom_string(RevAtom, Reversed).

%% get_current_datetime_str(-DateTimeStr)
get_current_datetime_str(DateTimeStr) :-
    get_time(Stamp),
    format_time(string(DateTimeStr), '%Y-%m-%d %H:%M:%S UTC', Stamp, posix).
