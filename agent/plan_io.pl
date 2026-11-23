:- module(plan_io, [
    clean_plan_string/2,
    get_plan_timestamp/1,
    validate_plan_graph/2,
    validate_plan_graph/3,
    compute_topological_sort/2,
    is_planning_required/2,
    is_planning_required/3
]).

:- use_module(library(ugraphs)).

%% clean_plan_string(+Raw, -Clean)
%% Strips Markdown code blocks, trims whitespace, and extracts canonical (plan-proposal ...)
clean_plan_string(Raw, Clean) :-
    atom_string(RawAtom, Raw),
    (   sub_atom(RawAtom, Before, _, _, '(plan-proposal ')
    ->  sub_atom(RawAtom, Before, _, 0, FromPlan),
        (   findall(P, sub_atom(FromPlan, P, 1, _, ')'), Parens),
            Parens \= []
        ->  last(Parens, LastParen),
            Len is LastParen + 1,
            sub_atom(FromPlan, 0, Len, _, PlanAtom),
            atom_string(PlanAtom, Clean)
        ;   atom_string(FromPlan, Clean)
        )
    ;   normalize_space(atom(Trimmed), RawAtom),
        atom_string(Trimmed, Clean)
    ).

%% get_plan_timestamp(-Timestamp)
get_plan_timestamp(Timestamp) :-
    get_time(T),
    Timestamp is round(T).

%% validate_plan_graph(+Tasks, -Result)
validate_plan_graph(Tasks, [Status, Message]) :-
    validate_plan_graph(Tasks, Status, Message).

%% validate_plan_graph(+Tasks, -Status, -Message)
validate_plan_graph(Tasks, Status, Message) :-
    (   \+ is_list(Tasks)
    ->  Status = error, Message = "Tasks must be a list."
    ;   Tasks == []
    ->  Status = error, Message = "Plan contains no tasks."
    ;   length(Tasks, N), N > 10
    ->  Status = error, Message = "Task count exceeds maximum limit of 10 tasks."
    ;   extract_task_ids(Tasks, Ids)
    ->  (   has_duplicates(Ids)
        ->  Status = error, Message = "Duplicate task IDs detected in plan."
        ;   check_dependencies(Tasks, Ids, DepError)
        ->  (   DepError \= ok
            ->  Status = error, Message = DepError
            ;   build_plan_edges(Tasks, Edges),
                add_vertices([], Ids, G0),
                add_edges(G0, Edges, G),
                (   top_sort(G, _)
                ->  Status = valid, Message = "Plan graph is valid."
                ;   Status = error, Message = "Circular dependency detected in plan."
                )
            )
        )
    ;   Status = error, Message = "Malformed task structure in plan."
    ).

extract_task_ids([], []).
extract_task_ids([[task, Id, _, _, _, _]|Rest], [Id|RestIds]) :-
    extract_task_ids(Rest, RestIds).

has_duplicates(List) :-
    sort(List, Unique),
    length(List, N),
    length(Unique, UN),
    N \= UN.

check_dependencies([], _, ok).
check_dependencies([[task, Id, _, _, _, RawDeps]|Rest], AllIds, Status) :-
    (   \+ is_list(RawDeps)
    ->  Status = "Task dependencies must be a list."
    ;   maplist(normalize_dep, RawDeps, Deps),
        member(Id, Deps)
    ->  Status = "Self-dependency detected: task cannot depend on itself."
    ;   maplist(normalize_dep, RawDeps, Deps),
        find_missing_dep(Deps, AllIds, Missing)
    ->  (   Missing \= none
        ->  format(string(MissingStr), "~w", [Missing]),
            string_concat("Missing dependency reference: ", MissingStr, Status)
        ;   check_dependencies(Rest, AllIds, Status)
        )
    ).

normalize_dep([ref, Tid], Tid) :- !.
normalize_dep(Tid, Tid).

find_missing_dep([], _, none).
find_missing_dep([D|Ds], AllIds, Missing) :-
    (   member(D, AllIds)
    ->  find_missing_dep(Ds, AllIds, Missing)
    ;   Missing = D
    ).

build_plan_edges([], []).
build_plan_edges([[task, Id, _, _, _, RawDeps]|Rest], AllEdges) :-
    maplist(normalize_dep, RawDeps, Deps),
    build_edges_for_task(Deps, Id, TaskEdges),
    build_plan_edges(Rest, RestEdges),
    append(TaskEdges, RestEdges, AllEdges).

build_edges_for_task([], _, []).
build_edges_for_task([D|Ds], Id, [D-Id|Rest]) :-
    build_edges_for_task(Ds, Id, Rest).

%% compute_topological_sort(+Tasks, -SortedIds)
compute_topological_sort(Tasks, SortedIds) :-
    extract_task_ids(Tasks, Ids),
    build_plan_edges(Tasks, Edges),
    add_vertices([], Ids, G0),
    add_edges(G0, Edges, G),
    top_sort(G, SortedIds).

%% is_planning_required(+Query, -Result)
is_planning_required(Query, [Decision, Reason]) :-
    is_planning_required(Query, Decision, Reason).

%% is_planning_required(+Query, -Decision, -Reason)
%% Determines whether a query requires multi-step planning or direct action
is_planning_required(Query, Decision, Reason) :-
    downcase_atom(Query, QLower),
    (   % Keywords indicating multi-step workflows
        (   sub_atom(QLower, _, _, _, ' and then ')
        ;   sub_atom(QLower, _, _, _, ', then ')
        ;   sub_atom(QLower, _, _, _, 'workflow')
        ;   sub_atom(QLower, _, _, _, 'pipeline')
        ;   sub_atom(QLower, _, _, _, 'multi-step')
        ;   sub_atom(QLower, _, _, _, 'step by step')
        ;   sub_atom(QLower, _, _, _, 'plan and execute')
        ;   (sub_atom(QLower, _, _, _, 'analyze') , sub_atom(QLower, _, _, _, 'and') , sub_atom(QLower, _, _, _, 'calculate'))
        ;   (sub_atom(QLower, _, _, _, 'calculate') , sub_atom(QLower, _, _, _, 'and') , sub_atom(QLower, _, _, _, 'summarize'))
        ;   (sub_atom(QLower, _, _, _, 'count words') , sub_atom(QLower, _, _, _, 'and') , sub_atom(QLower, _, _, _, 'analyze'))
        ;   (sub_atom(QLower, _, _, _, 'count') , sub_atom(QLower, _, _, _, 'analyze') , sub_atom(QLower, _, _, _, 'compare'))
        ;   (sub_atom(QLower, _, _, _, 'prepare a report') ; sub_atom(QLower, _, _, _, 'prepare a text analysis report'))
        )
    ->  Decision = true,
        Reason = "Multi-step request requiring decomposition, scheduling, and dependency execution."
    ;   Decision = false,
        Reason = "Direct answer or single action sufficient."
    ).
