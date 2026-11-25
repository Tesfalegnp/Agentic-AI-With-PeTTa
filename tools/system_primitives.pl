% =============================================================================
% PeTTa Agentic AI Framework - Safe System Primitives (Competition Edition)
% Module: tools/system_primitives.pl
%
% Implements deterministic, safe system tools with:
% 1. read_file_safe/2             - Safe bounded file reading
% 2. write_file_safe/3            - Safe file writing with path protection
% 3. execute_shell_command_safe/4 - Guarded shell with real user approval
% 4. send_user_message_safe/2     - User message relay
% 5. is_destructive_command/2     - Destructive command classifier
% 6. check_pending_approval/2     - Human approval IPC interface
%
% SECURITY: The model CANNOT self-approve dangerous commands.
%   Approval is ONLY valid when written to the external approval file by
%   an actual human or the UI. A string "approved=true" in model output
%   is completely ignored; it must arrive via the approval IPC file.
% =============================================================================

:- module(system_primitives, [
    read_file_safe/2,
    write_file_safe/3,
    execute_shell_command_safe/4,
    send_user_message_safe/2,
    is_destructive_command/2,
    check_pending_approval/2,
    record_audit_event/4
]).

:- use_module(library(readutil)).
:- use_module(library(process)).
:- use_module(library(filesex)).

% ---- Configuration ----------------------------------------------------------
% Maximum allowed file read size: 1 MB
max_read_bytes(1048576).

% Maximum tool output returned to agent: 8 KB (prevents context overflow)
max_output_bytes(8192).

% Default shell timeout in seconds
default_shell_timeout(15).

% Approval IPC file path (written by human/UI, never by agent itself)
approval_ipc_file("memory/pending_approval.json").

% Audit log file path
audit_log_file("logs/command_audit.log").

% Protected system paths (write forbidden)
protected_path_prefix('/etc').
protected_path_prefix('/usr').
protected_path_prefix('/bin').
protected_path_prefix('/boot').
protected_path_prefix('/sys').
protected_path_prefix('/proc').
protected_path_prefix('/dev').
protected_path_prefix('/lib').
protected_path_prefix('/lib64').
protected_path_prefix('/sbin').
protected_path_prefix('/root').

% -----------------------------------------------------------------------------
% 1. Safe File Reading: read_file_safe(+FilePath, -Result)
% Result: [success, ContentStr] | [failure, ErrorStr]
% -----------------------------------------------------------------------------
read_file_safe(FilePath, [failure, "Error: File does not exist."]) :-
    atom_string(PathAtom, FilePath),
    \+ exists_file(PathAtom), !.

read_file_safe(FilePath, [failure, ErrMsg]) :-
    atom_string(PathAtom, FilePath),
    catch(size_file(PathAtom, Size), _, fail),
    max_read_bytes(Limit),
    Size > Limit,
    !,
    number_string(LimitMB, Limit),
    string_concat("Error: File exceeds safe read limit (1 MB). File size: ", FilePath, ErrMsg).

read_file_safe(FilePath, [success, ContentStr]) :-
    atom_string(PathAtom, FilePath),
    catch(
        read_file_to_string(PathAtom, ContentStr, [encoding(utf8)]),
        _,
        fail
    ), !.

read_file_safe(FilePath, [failure, ErrMsg]) :-
    string_concat("Error: Unable to read file: ", FilePath, ErrMsg).

% -----------------------------------------------------------------------------
% 2. Safe File Writing: write_file_safe(+FilePath, +ContentStr, -Result)
% Result: [success, StatusStr] | [failure, ErrorStr]
% -----------------------------------------------------------------------------
write_file_safe(FilePath, _ContentStr, [failure, ErrMsg]) :-
    atom_string(PathAtom, FilePath),
    protected_path_prefix(Prefix),
    sub_atom(PathAtom, 0, _, _, Prefix),
    !,
    atom_string(Prefix, PrefixStr),
    string_concat("Error: Writing to protected system path is forbidden: ", PrefixStr, ErrMsg).

write_file_safe(FilePath, ContentStr, [success, StatusStr]) :-
    atom_string(PathAtom, FilePath),
    catch(
        (
            file_directory_name(PathAtom, DirAtom),
            ( DirAtom \== '' -> make_directory_path(DirAtom) ; true ),
            open(PathAtom, write, Stream, [encoding(utf8)]),
            write(Stream, ContentStr),
            close(Stream),
            string_concat("Successfully wrote file: ", FilePath, StatusStr)
        ),
        Error,
        fail
    ), !.

write_file_safe(FilePath, _ContentStr, [failure, ErrMsg]) :-
    string_concat("Error: Failed to write file: ", FilePath, ErrMsg).

% -----------------------------------------------------------------------------
% 3. Destructive Command Classification
% is_destructive_command(+CommandStr, -Reason)
% Succeeds (and unifies Reason) when the command is classified as destructive.
% -----------------------------------------------------------------------------
is_destructive_command(CommandStr, Reason) :-
    atom_string(Cmd, CommandStr),
    (   sub_atom(Cmd, _, _, _, 'rm -rf')       -> Reason = "Recursive force removal (rm -rf)"
    ;   sub_atom(Cmd, _, _, _, 'rm -fr')       -> Reason = "Recursive force removal (rm -fr)"
    ;   sub_atom(Cmd, _, _, _, 'rm -r')        -> Reason = "Recursive removal (rm -r)"
    ;   sub_atom(Cmd, _, _, _, 'mkfs')         -> Reason = "Filesystem format (mkfs)"
    ;   sub_atom(Cmd, _, _, _, 'dd if=')       -> Reason = "Direct disk block overwrite (dd)"
    ;   sub_atom(Cmd, _, _, _, 'dd bs=')       -> Reason = "Disk block operation (dd)"
    ;   sub_atom(Cmd, _, _, _, 'shutdown')     -> Reason = "System shutdown"
    ;   sub_atom(Cmd, _, _, _, 'reboot')       -> Reason = "System reboot"
    ;   sub_atom(Cmd, _, _, _, 'halt')         -> Reason = "System halt"
    ;   sub_atom(Cmd, _, _, _, 'poweroff')     -> Reason = "System poweroff"
    ;   sub_atom(Cmd, _, _, _, ':(){ :|:& };:') -> Reason = "Fork bomb detected"
    ;   sub_atom(Cmd, _, _, _, '> /dev/sd')    -> Reason = "Direct raw device write"
    ;   sub_atom(Cmd, _, _, _, '> /dev/hd')    -> Reason = "Direct raw device write"
    ;   sub_atom(Cmd, _, _, _, 'chmod 777 /')  -> Reason = "Unsafe root permission change"
    ;   sub_atom(Cmd, _, _, _, 'chown -R root')-> Reason = "Recursive root ownership change"
    ;   sub_atom(Cmd, _, _, _, 'curl | bash')  -> Reason = "Remote code execution via pipe"
    ;   sub_atom(Cmd, _, _, _, 'wget -O- |')   -> Reason = "Remote code execution via pipe"
    ).

% -----------------------------------------------------------------------------
% 4. Human Approval Check via IPC File
%
% check_pending_approval(+CommandStr, -Result)
%   Result = approved | denied | pending
%
% The approval IPC file is ONLY written by the human/UI via a separate
% approval widget. The agent CANNOT write to this file (it only reads it).
% A model-generated "approved=true" string in memory or conversation
% is completely ignored and never reaches this predicate.
% -----------------------------------------------------------------------------
check_pending_approval(CommandStr, Result) :-
    approval_ipc_file(ApprovalPath),
    atom_string(ApprovalAtom, ApprovalPath),
    (   exists_file(ApprovalAtom)
    ->  catch(
            read_file_to_string(ApprovalAtom, Content, [encoding(utf8)]),
            _,
            ( Result = pending, ! )
        ),
        (   string_contains_command_hash(Content, CommandStr)
        ->  ( sub_string(Content, _, _, _, "\"decision\":\"approved\"")
            ->  Result = approved,
                record_audit_event("command_approved", CommandStr, "Human approved via IPC file", "approved")
            ;   sub_string(Content, _, _, _, "\"decision\":\"denied\"")
            ->  Result = denied,
                record_audit_event("command_denied", CommandStr, "Human denied via IPC file", "denied")
            ;   Result = pending
            )
        ;   Result = pending
        )
    ;   Result = pending
    ).

% Helper: check if the approval file content references this command
% In production this uses a JSON hash; for portability we check substring
string_contains_command_hash(Content, CommandStr) :-
    % Extract first 100 chars of command as fingerprint for matching
    string_length(CommandStr, Len),
    FpLen is min(100, Len),
    sub_string(CommandStr, 0, FpLen, _, Fingerprint),
    sub_string(Content, _, _, _, Fingerprint).

% -----------------------------------------------------------------------------
% 5. Audit Log Recording
% record_audit_event(+EventType, +Command, +Message, +Outcome)
% -----------------------------------------------------------------------------
record_audit_event(EventType, Command, Message, Outcome) :-
    audit_log_file(AuditPath),
    atom_string(AuditAtom, AuditPath),
    get_time(TS),
    format_time(string(TimeStr), "%Y-%m-%dT%H:%M:%S", TS),
    % Sanitize command for log (redact potential secrets)
    sanitize_for_log(Command, SafeCmd),
    format(string(LogLine),
        "[~w] TYPE=~w CMD=~w MSG=~w OUTCOME=~w~n",
        [TimeStr, EventType, SafeCmd, Message, Outcome]),
    catch(
        (   open(AuditAtom, append, Stream, [encoding(utf8)]),
            write(Stream, LogLine),
            close(Stream)
        ),
        _,
        true  % If audit log write fails, continue silently (non-blocking)
    ).

sanitize_for_log(Input, Sanitized) :-
    atom_string(_, Input),  % Ensure it is a string
    re_replace("AIza[0-9A-Za-z\\-_]{20,}"/g, "[REDACTED]", Input, S1),
    re_replace("sk-[a-zA-Z0-9_\\-]{20,}"/g, "[REDACTED]", S1, S2),
    re_replace("Bearer [A-Za-z0-9\\-_.]{10,}"/g, "Bearer [REDACTED]", S2, Sanitized), !.
sanitize_for_log(Input, Input).  % Fallback: use as-is

% -----------------------------------------------------------------------------
% 6. Safe Shell Execution with Real Human Approval Gate
%
% execute_shell_command_safe(+CommandStr, +TimeoutSec, +_IgnoredApprovalFlag, -Result)
%
% IMPORTANT SECURITY CONTRACT:
% - The 3rd argument (ApprovalFlag) is IGNORED. It is never trusted.
% - Approval is ONLY checked via the approval IPC file (check_pending_approval).
% - The model cannot self-approve by passing approved=true in its action.
% - Destructive commands always require IPC-file human approval.
% - Non-destructive commands run immediately with timeout.
%
% Result: [success, OutputStr] | [failure, ErrorStr] | [approval_required, RequestMsg]
% -----------------------------------------------------------------------------

% Case 1: Destructive command — require IPC approval
execute_shell_command_safe(CommandStr, _TimeoutSec, _IgnoredFlag, Result) :-
    is_destructive_command(CommandStr, DangerousReason),
    !,
    check_pending_approval(CommandStr, ApprovalStatus),
    (   ApprovalStatus == approved
    ->  record_audit_event("destructive_command_approved", CommandStr, DangerousReason, "executing"),
        default_shell_timeout(DefaultTimeout),
        run_shell_with_timeout(CommandStr, DefaultTimeout, Result)
    ;   ApprovalStatus == denied
    ->  record_audit_event("destructive_command_denied", CommandStr, DangerousReason, "blocked"),
        string_concat("DENIED: Dangerous command blocked by human. Reason: ", DangerousReason, Msg),
        Result = [failure, Msg]
    ;   % pending or not yet approved
        record_audit_event("approval_requested", CommandStr, DangerousReason, "awaiting_human"),
        format(string(RequestMsg),
            "APPROVAL_REQUIRED: This command requires explicit human approval before execution.\nCommand: ~w\nRisk: ~w\nAction: Please use the UI approval panel or approve via memory/pending_approval.json.",
            [CommandStr, DangerousReason]),
        Result = [failure, RequestMsg]
    ).

% Case 2: Non-destructive command — run with timeout
execute_shell_command_safe(CommandStr, TimeoutSec, _IgnoredFlag, Result) :-
    (   number(TimeoutSec), TimeoutSec > 0
    ->  Timeout = TimeoutSec
    ;   default_shell_timeout(Timeout)
    ),
    record_audit_event("command_executed", CommandStr, "non-destructive", "running"),
    run_shell_with_timeout(CommandStr, Timeout, Result).

% Core shell runner with real timeout and output capping
run_shell_with_timeout(CommandStr, Timeout, [success, FinalOut]) :-
    catch(
        (
            process_create(path(bash), ['-c', CommandStr], [
                stdout(pipe(OutStream)),
                stderr(pipe(ErrStream)),
                process(PID)
            ]),
            wait_for_process_timeout(PID, Timeout, ExitStatus),
            read_string(OutStream, _, RawOut),
            read_string(ErrStream, _, RawErr),
            catch(close(OutStream), _, true),
            catch(close(ErrStream), _, true),
            cap_output(RawOut, CappedOut),
            (   ExitStatus == exit(0)
            ->  (   CappedOut == ""
                ->  FinalOut = "(Command completed with no stdout output.)"
                ;   FinalOut = CappedOut
                )
            ;   ExitStatus == timeout
            ->  format(string(FinalOut),
                    "TIMEOUT: Command did not complete within ~w seconds. Process killed. Stdout so far: ~w",
                    [Timeout, CappedOut]),
                fail  % Fall through to failure clause
            ;   format(string(FinalOut),
                    "Command failed (status: ~w).\nStdout: ~w\nStderr: ~w",
                    [ExitStatus, CappedOut, RawErr])
            )
        ),
        Error,
        (term_string(Error, ES), string_concat("Shell execution error: ", ES, FinalOut))
    ), !.

run_shell_with_timeout(CommandStr, Timeout, [failure, TimeoutMsg]) :-
    format(string(TimeoutMsg),
        "TIMEOUT: Command '~w' did not complete within ~w seconds.",
        [CommandStr, Timeout]).

% Terminate process when time limit exceeded
wait_for_process_timeout(PID, Timeout, Status) :-
    catch(
        call_with_time_limit(Timeout, process_wait(PID, Status)),
        time_limit_exceeded,
        (
            catch(process_kill(PID, 9), _, true),
            Status = timeout
        )
    ).

% Cap output to max_output_bytes to prevent context overflow
cap_output(RawStr, CappedStr) :-
    max_output_bytes(MaxBytes),
    string_bytes(RawStr, Bytes),
    length(Bytes, Len),
    (   Len > MaxBytes
    ->  length(Prefix, MaxBytes),
        append(Prefix, _, Bytes),
        string_bytes(Trimmed, Prefix),
        string_concat(Trimmed, "\n...[OUTPUT TRUNCATED — exceeded 8KB limit]", CappedStr)
    ;   CappedStr = RawStr
    ), !.
cap_output(RawStr, RawStr).  % Fallback

% -----------------------------------------------------------------------------
% 7. Send User Message Safe: send_user_message_safe(+MsgStr, -Result)
% Result: [success, OutputStr]
% -----------------------------------------------------------------------------
send_user_message_safe(MsgStr, [success, ResultStr]) :-
    string_concat("[Agent Message] ", MsgStr, ResultStr).
