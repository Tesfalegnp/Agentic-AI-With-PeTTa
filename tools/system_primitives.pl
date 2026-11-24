% =============================================================================
% PeTTa Agentic AI Framework - Safe System Primitives
% Module: tools/system_primitives.pl
%
% Implements deterministic, safe system tools for:
% 1. read_file_safe/2
% 2. write_file_safe/3
% 3. execute_shell_command_safe/4
% 4. send_user_message_safe/2
% =============================================================================

:- module(system_primitives, [
    read_file_safe/2,
    write_file_safe/3,
    execute_shell_command_safe/4,
    send_user_message_safe/2,
    is_destructive_command/2
]).

:- use_module(library(readutil)).
:- use_module(library(process)).
:- use_module(library(filesex)).

% Maximum allowed file read size: 1 MB
max_read_bytes(1048576).

% -----------------------------------------------------------------------------
% 1. Safe File Reading: read_file_safe(+FilePath, -Result)
% Result is [success, ContentStr] or [failure, ErrorStr]
% -----------------------------------------------------------------------------
read_file_safe(FilePath, [failure, "Error: File does not exist."]) :-
    atom_string(PathAtom, FilePath),
    \+ exists_file(PathAtom), !.
read_file_safe(FilePath, [failure, "Error: File size exceeds safe maximum limit (1 MB)."]) :-
    atom_string(PathAtom, FilePath),
    catch(size_file(PathAtom, Size), _, fail),
    max_read_bytes(Limit),
    Size > Limit, !.
read_file_safe(FilePath, [success, ContentStr]) :-
    atom_string(PathAtom, FilePath),
    catch(
        read_file_to_string(PathAtom, ContentStr, [encoding(utf8)]),
        _,
        fail
    ), !.
read_file_safe(FilePath, [failure, ErrMsg]) :-
    atom_string(PathAtom, FilePath),
    catch(
        read_file_to_string(PathAtom, _, [encoding(utf8)]),
        Error,
        true
    ),
    term_string(Error, ErrStr),
    string_concat("Error reading file: ", ErrStr, ErrMsg).

% -----------------------------------------------------------------------------
% 2. Safe File Writing: write_file_safe(+FilePath, +ContentStr, -Result)
% Result is [success, StatusStr] or [failure, ErrorStr]
% -----------------------------------------------------------------------------
write_file_safe(FilePath, _ContentStr, [failure, "Error: Write path to critical system directory is forbidden."]) :-
    atom_string(PathAtom, FilePath),
    (   sub_atom(PathAtom, 0, _, _, '/etc')
    ;   sub_atom(PathAtom, 0, _, _, '/usr')
    ;   sub_atom(PathAtom, 0, _, _, '/bin')
    ;   sub_atom(PathAtom, 0, _, _, '/boot')
    ;   sub_atom(PathAtom, 0, _, _, '/sys')
    ;   sub_atom(PathAtom, 0, _, _, '/proc')
    ), !.
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
        _,
        fail
    ), !.
write_file_safe(FilePath, _ContentStr, [failure, ErrMsg]) :-
    string_concat("Error writing file: ", FilePath, ErrMsg).

% -----------------------------------------------------------------------------
% 3. Destructive Command Detection
% -----------------------------------------------------------------------------
is_destructive_command(CommandStr, Reason) :-
    atom_string(Cmd, CommandStr),
    (   sub_atom(Cmd, _, _, _, 'rm -rf') -> Reason = "Recursive force removal (rm -rf)"
    ;   sub_atom(Cmd, _, _, _, 'rm -fr') -> Reason = "Recursive force removal (rm -fr)"
    ;   sub_atom(Cmd, _, _, _, 'mkfs')   -> Reason = "Filesystem format (mkfs)"
    ;   sub_atom(Cmd, _, _, _, 'dd if=') -> Reason = "Direct disk block overwrite (dd)"
    ;   sub_atom(Cmd, _, _, _, 'shutdown') -> Reason = "System shutdown"
    ;   sub_atom(Cmd, _, _, _, 'reboot')   -> Reason = "System reboot"
    ;   sub_atom(Cmd, _, _, _, ':(){ :|:& };:') -> Reason = "Fork bomb detected"
    ;   sub_atom(Cmd, _, _, _, '> /dev/sd') -> Reason = "Direct raw device write"
    ).

% -----------------------------------------------------------------------------
% 4. Safe Shell Execution with Timeout and Approval Guardrails
% execute_shell_command_safe(+CommandStr, +TimeoutSec, +ApprovedStr, -Result)
% Result is [success, OutputStr] or [failure, ErrorStr]
% -----------------------------------------------------------------------------
execute_shell_command_safe(CommandStr, _TimeoutSec, ApprovedStr, [failure, ErrStr]) :-
    is_destructive_command(CommandStr, DangerousReason),
    \+ (ApprovedStr == "true" ; ApprovedStr == true), !,
    string_concat("Error: Destructive shell command blocked. Reason: ", DangerousReason, P1),
    string_concat(P1, ". Explicit approval required (Approved=true).", ErrStr).

execute_shell_command_safe(CommandStr, TimeoutSec, _ApprovedStr, [success, OutputStr]) :-
    (   number(TimeoutSec), TimeoutSec > 0
    ->  Timeout = TimeoutSec
    ;   Timeout = 10
    ),
    catch(
        (
            process_create(path(bash), ['-c', CommandStr], [
                stdout(pipe(OutStream)),
                stderr(pipe(ErrStream)),
                process(PID)
            ]),
            wait_for_process_timeout(PID, Timeout, ExitStatus),
            read_string(OutStream, _, OutData),
            read_string(ErrStream, _, ErrData),
            close(OutStream),
            close(ErrStream),
            (   ExitStatus == exit(0)
            ->  (   OutData == ""
                ->  OutputStr = "(Command executed successfully with no stdout output)"
                ;   OutputStr = OutData
                )
            ;   ExitStatus == timeout
            ->  string_concat("Error: Command execution timed out after ", Timeout, P1),
                string_concat(P1, " seconds.", OutputStr)
            ;   string_concat("Command failed with status: ", ExitStatus, P1),
                string_concat(P1, "\nStderr: ", P2),
                string_concat(P2, ErrData, P3),
                string_concat(P3, "\nStdout: ", P4),
                string_concat(P4, OutData, OutputStr)
            )
        ),
        Error,
        (
            term_string(Error, ErrStr),
            string_concat("Error executing shell command: ", ErrStr, OutputStr)
        )
    ), !.
execute_shell_command_safe(_Cmd, _T, _A, [failure, "Unknown execution error"]).

wait_for_process_timeout(PID, Timeout, Status) :-
    catch(
        call_with_time_limit(Timeout, process_wait(PID, Status)),
        time_limit_exceeded,
        (
            catch(process_kill(PID, 9), _, true),
            Status = timeout
        )
    ).

% -----------------------------------------------------------------------------
% 5. Send User Message Safe: send_user_message_safe(+MsgStr, -Result)
% Result is [success, OutputStr]
% -----------------------------------------------------------------------------
send_user_message_safe(MsgStr, [success, ResultStr]) :-
    string_concat("Message sent to user: ", MsgStr, ResultStr).
