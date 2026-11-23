:- module(adaptation_io, [
    get_adaptation_timestamp/1,
    get_adaptation_timestamp/2,
    clean_feedback_text/2,
    clean_feedback_text/3,
    is_valid_confidence_val/2,
    is_valid_confidence_val/3,
    save_feedback_records/3,
    load_feedback_records/3,
    save_adaptation_rules/3,
    load_adaptation_rules/3,
    save_adaptation_history/3,
    load_adaptation_history/3,
    save_adaptation_evals/3,
    load_adaptation_evals/3,
    clear_adaptation_file/2,
    check_instruction_adaptation_conflict/3,
    check_instruction_adaptation_conflict/4,
    is_adaptation_relevant_to_query/4,
    is_adaptation_relevant_to_query/5,
    aggregate_feedback_in_space/3,
    aggregate_feedback_in_space/4,
    get_supporting_feedback_ids/4,
    get_supporting_feedback_ids/5,
    detect_adaptation_rule_conflicts_in_space/2,
    detect_adaptation_rule_conflicts_in_space/3
]).

% Get current ISO-8601 timestamp string
get_adaptation_timestamp(IsoStr) :-
    get_time(Stamp),
    format_time(string(IsoStr), "%FT%T%:z", Stamp).

get_adaptation_timestamp(_, IsoStr) :-
    get_adaptation_timestamp(IsoStr).

% Clean and normalize feedback string
clean_feedback_text(Input, Cleaned) :-
    (   string(Input) -> Str = Input
    ;   atom(Input) -> atom_string(Input, Str)
    ;   format(string(Str), "~w", [Input])
    ),
    split_string(Str, "\n\r", " \t", Parts),
    atomics_to_string(Parts, " ", Norm),
    normalize_space(string(Cleaned), Norm).

clean_feedback_text(Input, _, Cleaned) :-
    clean_feedback_text(Input, Cleaned).

% Confidence validation: must be a number between 0.0 and 1.0
is_valid_confidence_val(Val, true) :-
    number(Val),
    Val >= 0.0,
    Val =< 1.0, !.
is_valid_confidence_val(_, false).

is_valid_confidence_val(Val, _, Res) :-
    is_valid_confidence_val(Val, Res).

% Clear a storage file
clear_adaptation_file(FilePath, true) :-
    (   exists_file(FilePath)
    ->  delete_file(FilePath)
    ;   true
    ).

% Save feedback records from AtomSpace to file
save_feedback_records(FilePath, Space, Count) :-
    open(FilePath, write, Out, [encoding(utf8)]),
    findall(['FeedbackRecord', Id, Cat, Pol, TType, TId, Txt, Ctx, Src, Conf, Ts, St],
            'match'(Space, ['FeedbackRecord', Id, Cat, Pol, TType, TId, Txt, Ctx, Src, Conf, Ts, St],
                           ['FeedbackRecord', Id, Cat, Pol, TType, TId, Txt, Ctx, Src, Conf, Ts, St], _),
            Records),
    sort(Records, UniqueRecords),
    length(UniqueRecords, Count),
    forall(member(['FeedbackRecord', Id, Cat, Pol, TType, TId, Txt, Ctx, Src, Conf, Ts, St], UniqueRecords),
           (   writeq(Out, fb_rec(Id, Cat, Pol, TType, TId, Txt, Ctx, Src, Conf, Ts, St)),
               format(Out, ".~n", [])
           )),
    close(Out).

% Load feedback records from file into AtomSpace
load_feedback_records(FilePath, Space, Count) :-
    (   \+ exists_file(FilePath)
    ->  Count = 0
    ;   open(FilePath, read, In, [encoding(utf8)]),
        read_fb_lines_and_insert(In, Space, 0, Count),
        close(In)
    ).

read_fb_lines_and_insert(In, Space, Acc, Count) :-
    read_line_to_string(In, Line),
    (   Line == end_of_file
    ->  Count = Acc
    ;   (   catch(read_term_from_atom(Line, Term, [syntax_errors(quiet)]), _, fail),
            Term = fb_rec(Id, Cat, Pol, TType, TId, Txt, Ctx, Src, Conf, Ts, St)
        ->  Atom = ['FeedbackRecord', Id, Cat, Pol, TType, TId, Txt, Ctx, Src, Conf, Ts, St],
            (   'match'(Space, ['FeedbackRecord', Id, _, _, _, _, _, _, _, _, _, _], found, _)
            ->  Acc1 = Acc
            ;   'add-atom'(Space, Atom, _),
                Acc1 is Acc + 1
            )
        ;   Acc1 = Acc
        ),
        read_fb_lines_and_insert(In, Space, Acc1, Count)
    ).

% Save adaptation rules from AtomSpace to file
save_adaptation_rules(FilePath, Space, Count) :-
    open(FilePath, write, Out, [encoding(utf8)]),
    findall(['AdaptationRule', Id, Cat, Desc, Trig, Rec, Supp, Score, Conf, Cr, Up, St],
            'match'(Space, ['AdaptationRule', Id, Cat, Desc, Trig, Rec, Supp, Score, Conf, Cr, Up, St],
                           ['AdaptationRule', Id, Cat, Desc, Trig, Rec, Supp, Score, Conf, Cr, Up, St], _),
            Rules),
    sort(Rules, UniqueRules),
    length(UniqueRules, Count),
    forall(member(['AdaptationRule', Id, Cat, Desc, Trig, Rec, Supp, Score, Conf, Cr, Up, St], UniqueRules),
           (   writeq(Out, adapt_rec(Id, Cat, Desc, Trig, Rec, Supp, Score, Conf, Cr, Up, St)),
               format(Out, ".~n", [])
           )),
    close(Out).

% Load adaptation rules from file into AtomSpace
load_adaptation_rules(FilePath, Space, Count) :-
    (   \+ exists_file(FilePath)
    ->  Count = 0
    ;   open(FilePath, read, In, [encoding(utf8)]),
        read_adapt_lines_and_insert(In, Space, 0, Count),
        close(In)
    ).

read_adapt_lines_and_insert(In, Space, Acc, Count) :-
    read_line_to_string(In, Line),
    (   Line == end_of_file
    ->  Count = Acc
    ;   (   catch(read_term_from_atom(Line, Term, [syntax_errors(quiet)]), _, fail),
            Term = adapt_rec(Id, Cat, Desc, Trig, Rec, Supp, Score, Conf, Cr, Up, St)
        ->  Atom = ['AdaptationRule', Id, Cat, Desc, Trig, Rec, Supp, Score, Conf, Cr, Up, St],
            (   'match'(Space, ['AdaptationRule', Id, _, _, _, _, _, _, _, _, _, _], found, _)
            ->  Acc1 = Acc
            ;   'add-atom'(Space, Atom, _),
                Acc1 is Acc + 1
            )
        ;   Acc1 = Acc
        ),
        read_adapt_lines_and_insert(In, Space, Acc1, Count)
    ).

% Save adaptation history events from AtomSpace to file
save_adaptation_history(FilePath, Space, Count) :-
    open(FilePath, write, Out, [encoding(utf8)]),
    findall(['AdaptationHistoryEvent', EvId, Ts, EvType, TargetId, Details],
            'match'(Space, ['AdaptationHistoryEvent', EvId, Ts, EvType, TargetId, Details],
                           ['AdaptationHistoryEvent', EvId, Ts, EvType, TargetId, Details], _),
            Events),
    sort(Events, UniqueEvents),
    length(UniqueEvents, Count),
    forall(member(['AdaptationHistoryEvent', EvId, Ts, EvType, TargetId, Details], UniqueEvents),
           (   writeq(Out, hist_rec(EvId, Ts, EvType, TargetId, Details)),
               format(Out, ".~n", [])
           )),
    close(Out).

% Load adaptation history events from file into AtomSpace
load_adaptation_history(FilePath, Space, Count) :-
    (   \+ exists_file(FilePath)
    ->  Count = 0
    ;   open(FilePath, read, In, [encoding(utf8)]),
        read_hist_lines_and_insert(In, Space, 0, Count),
        close(In)
    ).

read_hist_lines_and_insert(In, Space, Acc, Count) :-
    read_line_to_string(In, Line),
    (   Line == end_of_file
    ->  Count = Acc
    ;   (   catch(read_term_from_atom(Line, Term, [syntax_errors(quiet)]), _, fail),
            Term = hist_rec(EvId, Ts, EvType, TargetId, Details)
        ->  Atom = ['AdaptationHistoryEvent', EvId, Ts, EvType, TargetId, Details],
            (   'match'(Space, ['AdaptationHistoryEvent', EvId, _, _, _, _], found, _)
            ->  Acc1 = Acc
            ;   'add-atom'(Space, Atom, _),
                Acc1 is Acc + 1
            )
        ;   Acc1 = Acc
        ),
        read_hist_lines_and_insert(In, Space, Acc1, Count)
    ).

% Save adaptation evaluation records from AtomSpace to file
save_adaptation_evals(FilePath, Space, Count) :-
    open(FilePath, write, Out, [encoding(utf8)]),
    findall(['AdaptationEvaluation', RId, AppC, PosC, NegC, CorrC, LastApp, St],
            'match'(Space, ['AdaptationEvaluation', RId, AppC, PosC, NegC, CorrC, LastApp, St],
                           ['AdaptationEvaluation', RId, AppC, PosC, NegC, CorrC, LastApp, St], _),
            Evals),
    sort(Evals, UniqueEvals),
    length(UniqueEvals, Count),
    forall(member(['AdaptationEvaluation', RId, AppC, PosC, NegC, CorrC, LastApp, St], UniqueEvals),
           (   writeq(Out, eval_rec(RId, AppC, PosC, NegC, CorrC, LastApp, St)),
               format(Out, ".~n", [])
           )),
    close(Out).

% Load adaptation evaluation records from file into AtomSpace
load_adaptation_evals(FilePath, Space, Count) :-
    (   \+ exists_file(FilePath)
    ->  Count = 0
    ;   open(FilePath, read, In, [encoding(utf8)]),
        read_eval_lines_and_insert(In, Space, 0, Count),
        close(In)
    ).

read_eval_lines_and_insert(In, Space, Acc, Count) :-
    read_line_to_string(In, Line),
    (   Line == end_of_file
    ->  Count = Acc
    ;   (   catch(read_term_from_atom(Line, Term, [syntax_errors(quiet)]), _, fail),
            Term = eval_rec(RId, AppC, PosC, NegC, CorrC, LastApp, St)
        ->  Atom = ['AdaptationEvaluation', RId, AppC, PosC, NegC, CorrC, LastApp, St],
            (   'match'(Space, ['AdaptationEvaluation', RId, _, _, _, _, _, _], found, _)
            ->  Acc1 = Acc
            ;   'add-atom'(Space, Atom, _),
                Acc1 is Acc + 1
            )
        ;   Acc1 = Acc
        ),
        read_eval_lines_and_insert(In, Space, Acc1, Count)
    ).

% Conflict checking between current user instruction (Query) and Adaptation Recommendation
check_instruction_adaptation_conflict(Query, Recommendation, [conflict, Msg]) :-
    downcase_atom(Query, QLower),
    (   % Conflict: Rule recommends concise, but user explicitly asked for detailed/elaborate/comprehensive
        (Recommendation == prefer_concise ; Recommendation == "prefer_concise"),
        (   sub_atom(QLower, _, _, _, "detail")
        ;   sub_atom(QLower, _, _, _, "in-depth")
        ;   sub_atom(QLower, _, _, _, "in depth")
        ;   sub_atom(QLower, _, _, _, "elaborate")
        ;   sub_atom(QLower, _, _, _, "comprehensive")
        ;   sub_atom(QLower, _, _, _, "thorough")
        ;   sub_atom(QLower, _, _, _, "long answer")
        )
    ->  Msg = "User instruction explicitly requests detailed explanation, overriding concise adaptation rule."
    ;   % Conflict: Rule recommends detailed, but user explicitly asked for brief/concise/short/summary
        (Recommendation == prefer_detailed ; Recommendation == "prefer_detailed"),
        (   sub_atom(QLower, _, _, _, "concise")
        ;   sub_atom(QLower, _, _, _, "brief")
        ;   sub_atom(QLower, _, _, _, "short")
        ;   sub_atom(QLower, _, _, _, "summary only")
        ;   sub_atom(QLower, _, _, _, "quick answer")
        )
    ->  Msg = "User instruction explicitly requests brief/concise answer, overriding detailed adaptation rule."
    ;   % Conflict: Rule avoids tables, but user asks for a table
        (Recommendation == avoid_markdown_table ; Recommendation == "avoid_markdown_table"),
        (   sub_atom(QLower, _, _, _, "table")
        ;   sub_atom(QLower, _, _, _, "tabular")
        )
    ->  Msg = "User instruction explicitly requests table format, overriding avoid_markdown_table rule."
    ;   % Conflict: Rule prefers plain text, but user requests JSON
        (Recommendation == prefer_plain_text ; Recommendation == "prefer_plain_text"),
        sub_atom(QLower, _, _, _, "json")
    ->  Msg = "User instruction explicitly requests JSON, overriding plain text adaptation rule."
    ;   % Conflict: Rule omits calculations, but user asks for calculations/steps
        (Recommendation == omit_calculations ; Recommendation == "omit_calculations"),
        (   sub_atom(QLower, _, _, _, "calculation")
        ;   sub_atom(QLower, _, _, _, "show steps")
        ;   sub_atom(QLower, _, _, _, "step-by-step")
        ;   sub_atom(QLower, _, _, _, "working")
        )
    ->  Msg = "User instruction explicitly requests calculation steps, overriding omit_calculations rule."
    ), !.

check_instruction_adaptation_conflict(_, _, [no_conflict, "none"]).

check_instruction_adaptation_conflict(Query, Recommendation, _, Res) :-
    check_instruction_adaptation_conflict(Query, Recommendation, Res).

% Query relevance check: does this adaptation rule apply to this user query?
is_adaptation_relevant_to_query(RuleCat, Trigger, _Query, true) :-
    (   Trigger == all_queries ; Trigger == "all_queries" ),
    RuleCat \== math_queries,
    RuleCat \== tool_preference,
    RuleCat \== skill_preference, !.

is_adaptation_relevant_to_query(RuleCat, Trigger, Query, true) :-
    downcase_atom(Query, QLower),
    (   (RuleCat == verbosity ; RuleCat == "verbosity")
    ->  true
    ;   (RuleCat == format_preference ; RuleCat == "format_preference")
    ->  true
    ;   (RuleCat == explanation_detail ; RuleCat == "explanation_detail")
    ->  true
    ;   (Trigger == math_queries ; Trigger == "math_queries" ; RuleCat == tool_preference ; RuleCat == "tool_preference")
    ->  (   sub_atom(QLower, _, _, _, "calc")
        ;   sub_atom(QLower, _, _, _, "math")
        ;   sub_atom(QLower, _, _, _, "compute")
        ;   sub_atom(QLower, _, _, _, "*")
        ;   sub_atom(QLower, _, _, _, "+")
        ;   sub_atom(QLower, _, _, _, "/")
        ;   sub_atom(QLower, _, _, _, "-")
        )
    ;   (Trigger == text_queries ; Trigger == "text_queries" ; RuleCat == skill_preference ; RuleCat == "skill_preference")
    ->  (   sub_atom(QLower, _, _, _, "text")
        ;   sub_atom(QLower, _, _, _, "words")
        ;   sub_atom(QLower, _, _, _, "count")
        ;   sub_atom(QLower, _, _, _, "analyze")
        )
    ), !.

is_adaptation_relevant_to_query(_, _, _, false).

is_adaptation_relevant_to_query(RuleCat, Trigger, Query, _, Res) :-
    is_adaptation_relevant_to_query(RuleCat, Trigger, Query, Res).

% Feedback aggregation over space
aggregate_feedback_in_space(Space, Category, [agg_res, Category, Total, Pos, Neg, Corr, Explicit, Inferred, Score, Dominant, Contradictory, ThresholdMet]) :-
    findall([Id, Cat, Pol, Src, Conf],
            (   Category == all
            ->  'match'(Space, ['FeedbackRecord', Id, Cat, Pol, _, _, _, _, Src, Conf, _, active],
                               [Id, Cat, Pol, Src, Conf], _)
            ;   'match'(Space, ['FeedbackRecord', Id, Category, Pol, _, _, _, _, Src, Conf, _, active],
                               [Id, Category, Pol, Src, Conf], _)
            ),
            Records),
    sort(Records, UniqueRecords),
    length(UniqueRecords, Total),
    count_stats(UniqueRecords, 0, Pos, 0, Neg, 0, Corr, 0, Explicit, 0, Inferred, 0.0, Score),
    (   (Pos > 0, (Neg + Corr) > 0)
    ->  Contradictory = true, Dominant = mixed
    ;   Pos > (Neg + Corr)
    ->  Contradictory = false, Dominant = positive
    ;   (Neg + Corr) > Pos
    ->  Contradictory = false,
        (   Neg >= Corr -> Dominant = negative ; Dominant = correction )
    ;   Contradictory = false, Dominant = neutral
    ),
    (   (Explicit >= 2 ; Score >= 2.0)
    ->  ThresholdMet = true
    ;   ThresholdMet = false
    ).

count_stats([], P, P, N, N, C, C, E, E, I, I, S, S).
count_stats([[_, _, Pol, Src, Conf]|Rest], PAcc, P, NAcc, N, CAcc, C, EAcc, E, IAcc, I, SAcc, S) :-
    ( Pol == positive -> P1 is PAcc + 1 ; P1 = PAcc ),
    ( Pol == negative -> N1 is NAcc + 1 ; N1 = NAcc ),
    ( Pol == correction -> C1 is CAcc + 1 ; C1 = CAcc ),
    ( Src == explicit_user -> E1 is EAcc + 1, Weight = 1.0 ; E1 = EAcc, Weight = 0.5 ),
    ( Src == inferred_signal -> I1 is IAcc + 1 ; I1 = IAcc ),
    S1 is SAcc + (Weight * Conf),
    count_stats(Rest, P1, P, N1, N, C1, C, E1, E, I1, I, S1, S).

aggregate_feedback_in_space(Space, Category, _, Res) :-
    aggregate_feedback_in_space(Space, Category, Res).

% Query supporting feedback IDs
get_supporting_feedback_ids(Space, Category, Polarity, Ids) :-
    findall(Id,
            (   Polarity == all
            ->  'match'(Space, ['FeedbackRecord', Id, Category, _, _, _, _, _, _, _, _, active], Id, _)
            ;   'match'(Space, ['FeedbackRecord', Id, Category, Polarity, _, _, _, _, _, _, _, active], Id, _)
            ),
            RawIds),
    sort(RawIds, Ids).

get_supporting_feedback_ids(Space, Category, Polarity, _, Res) :-
    get_supporting_feedback_ids(Space, Category, Polarity, Res).

% Detect conflict between active adaptation rules in space
detect_adaptation_rule_conflicts_in_space(Space, Conflicts) :-
    findall([conflict, Id1, Id2, Cat, Rec1, Rec2],
            (   'match'(Space, ['AdaptationRule', Id1, Cat, _, _, Rec1, _, _, _, _, _, active], found, _),
                'match'(Space, ['AdaptationRule', Id2, Cat, _, _, Rec2, _, _, _, _, _, active], found, _),
                Id1 @< Id2,
                is_opposing_recommendation(Rec1, Rec2)
            ),
            RawConflicts),
    sort(RawConflicts, Conflicts).

is_opposing_recommendation(prefer_concise, prefer_detailed).
is_opposing_recommendation(prefer_detailed, prefer_concise).
is_opposing_recommendation(include_calculations, omit_calculations).
is_opposing_recommendation(omit_calculations, include_calculations).
is_opposing_recommendation(prefer_bullet_format, prefer_plain_text).
is_opposing_recommendation(prefer_plain_text, prefer_bullet_format).
is_opposing_recommendation(prefer_tool_execution, prefer_skill_execution).
is_opposing_recommendation(prefer_skill_execution, prefer_tool_execution).

detect_adaptation_rule_conflicts_in_space(Space, _, Res) :-
    detect_adaptation_rule_conflicts_in_space(Space, Res).
