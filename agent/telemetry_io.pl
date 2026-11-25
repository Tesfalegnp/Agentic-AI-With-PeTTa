% =============================================================================
% STAGE D - MILESTONE 13: UI Telemetry & Safe Gateway I/O
% Module: agent/telemetry_io.pl
% =============================================================================

:- module(telemetry_io, [
    emit_telemetry_event/5,
    clear_telemetry_events/1,
    read_session_query/1,
    write_session_result/4,
    save_session_conversation/2,
    load_session_conversation/1,
    clear_session_conversation/1,
    read_session_feedback/1
]).

:- use_module(library(json)).
:- use_module(library(readutil)).

telemetry_file("memory/session_events.jsonl").
conversation_file("memory/session_conversation.tsv").
query_file("memory/session_query.txt").
result_file("memory/session_result.json").
feedback_file("memory/session_feedback.json").

% Ensure directory exists
ensure_memory_dir :-
    (   exists_directory("memory")
    ->  true
    ;   catch(make_directory("memory"), _, true)
    ).

% Helper to sanitize and stringify terms
stringify_term(Var, "") :- var(Var), !.
stringify_term(String, Clean) :-
    string(String), !,
    normalize_space(string(Clean), String).
stringify_term(Atom, Clean) :-
    atom(Atom), !,
    atom_string(Atom, Str),
    normalize_space(string(Clean), Str).
stringify_term(Number, Str) :-
    number(Number), !,
    number_string(Number, Str).
stringify_term(List, Str) :-
    is_list(List), !,
    term_string(List, Str).
stringify_term(Term, Str) :-
    term_string(Term, Str).

% Emit single-line JSON telemetry event
emit_telemetry_event(EventType, Stage, Message, Details, true) :-
    ensure_memory_dir,
    telemetry_file(File),
    get_time(Timestamp),
    stringify_term(EventType, TypeStr),
    stringify_term(Stage, StageStr),
    stringify_term(Message, MsgStr),
    stringify_term(Details, DetailsStr),
    Event = json([
        timestamp=Timestamp,
        event_type=TypeStr,
        stage=StageStr,
        message=MsgStr,
        details=DetailsStr
    ]),
    catch((
        open(File, append, Stream, [encoding(utf8)]),
        json_write(Stream, Event, [width(0)]),
        nl(Stream),
        flush_output(Stream),
        close(Stream)
    ), _, true).

% Clear telemetry events file
clear_telemetry_events(true) :-
    ensure_memory_dir,
    telemetry_file(File),
    catch((
        open(File, write, Stream, [encoding(utf8)]),
        close(Stream)
    ), _, true).

% Safely read user query from file (immune to shell escaping/injection)
read_session_query(QueryString) :-
    ensure_memory_dir,
    query_file(File),
    catch((
        exists_file(File),
        read_file_to_string(File, Raw, [encoding(utf8)]),
        normalize_space(string(QueryString), Raw)
    ), _, QueryString = "").

% Safely write execution result to JSON
write_session_result(Status, Action, Content, true) :-
    ensure_memory_dir,
    result_file(File),
    get_time(Timestamp),
    stringify_term(Status, StatusStr),
    stringify_term(Action, ActionStr),
    stringify_term(Content, ContentStr),
    Result = json([
        status=StatusStr,
        action=ActionStr,
        content=ContentStr,
        timestamp=Timestamp
    ]),
    catch((
        open(File, write, Stream, [encoding(utf8)]),
        json_write(Stream, Result, [width(0)]),
        nl(Stream),
        flush_output(Stream),
        close(Stream)
    ), _, true).

% Save conversation history records to TSV
save_session_conversation(Records, true) :-
    ensure_memory_dir,
    conversation_file(File),
    catch((
        open(File, write, Stream, [encoding(utf8)]),
        write_conversation_records(Stream, Records),
        close(Stream)
    ), _, true).

write_conversation_records(_, []) :- !.
write_conversation_records(Stream, [Record|Rest]) :-
    (   Record = ['UserMessage', Msg]
    ->  clean_msg_for_tsv(Msg, CleanMsg),
        format(Stream, "user\t~w~n", [CleanMsg])
    ;   Record = ['AssistantMessage', Msg]
    ->  clean_msg_for_tsv(Msg, CleanMsg),
        format(Stream, "assistant\t~w~n", [CleanMsg])
    ;   Record = ['ClarificationState', 'awaiting', Q]
    ->  clean_msg_for_tsv(Q, CleanQ),
        format(Stream, "clarification\t~w~n", [CleanQ])
    ;   Record = ['PendingGoal', G]
    ->  clean_msg_for_tsv(G, CleanG),
        format(Stream, "pending_goal\t~w~n", [CleanG])
    ;   Record = ['PendingPlan', P]
    ->  clean_msg_for_tsv(P, CleanP),
        format(Stream, "pending_plan\t~w~n", [CleanP])
    ;   true
    ),
    write_conversation_records(Stream, Rest).

clean_msg_for_tsv(Msg, Clean) :-
    stringify_term(Msg, Str),
    % Replace tabs and newlines with spaces or escaped representation
    re_replace("\t"/g, " ", Str, S1),
    re_replace("\n"/g, "\\n", S1, Clean).

% Load conversation history records from TSV
load_session_conversation(Records) :-
    conversation_file(File),
    catch((
        exists_file(File),
        read_file_to_string(File, Content, [encoding(utf8)]),
        split_string(Content, "\n", "\r", Lines),
        parse_conv_lines(Lines, Records)
    ), _, Records = []).

parse_conv_lines([], []) :- !.
parse_conv_lines([Line|Rest], Records) :-
    (   normalize_space(string(Trimmed), Line),
        Trimmed \= "",
        split_string(Trimmed, "\t", "", [Role, RawMsg])
    ->  re_replace("\\\\n"/g, "\n", RawMsg, Msg),
        (   Role == "user"
        ->  Records = [['UserMessage', Msg]|More]
        ;   Role == "assistant"
        ->  Records = [['AssistantMessage', Msg]|More]
        ;   Role == "clarification"
        ->  Records = [['ClarificationState', 'awaiting', Msg]|More]
        ;   Role == "pending_goal"
        ->  Records = [['PendingGoal', Msg]|More]
        ;   Role == "pending_plan"
        ->  Records = [['PendingPlan', Msg]|More]
        ;   Records = More
        ),
        parse_conv_lines(Rest, More)
    ;   parse_conv_lines(Rest, Records)
    ).

% Clear conversation state file
clear_session_conversation(true) :-
    ensure_memory_dir,
    conversation_file(File),
    catch((
        open(File, write, Stream, [encoding(utf8)]),
        close(Stream)
    ), _, true).

% Read session feedback JSON into a list of parameters
read_session_feedback([Category, Polarity, TargetType, TargetId, Text, Rating]) :-
    ensure_memory_dir,
    feedback_file(File),
    catch((
        exists_file(File),
        read_file_to_string(File, Content, [encoding(utf8)]),
        atom_json_dict(Content, Dict, []),
        Category = Dict.get(category, answer_quality),
        Polarity = Dict.get(polarity, positive),
        TargetType = Dict.get(target_type, answer),
        TargetId = Dict.get(target_id, none),
        Text = Dict.get(text, ""),
        Rating = Dict.get(rating, 1.0)
    ), _, (
        Category = answer_quality,
        Polarity = positive,
        TargetType = answer,
        TargetId = none,
        Text = "",
        Rating = 1.0
    )).
