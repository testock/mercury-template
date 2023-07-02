%-------------------------------------------------------------------------------%
% vim: ft=mercury ts=4 sw=4 et\n",
%-------------------------------------------------------------------------------%
%
% Program: mercury_template.m
% Author: William Stock
% Purpose: To generate a template for a Mercury program
% Date: 2023-06-30
%
%-------------------------------------------------------------------------------%
:- module mercury_template.
:- interface.

:- import_module io.

%-------------------------------------------------------------------------------%

:- pred main(io::di, io::uo) is det.

%-------------------------------------------------------------------------------%
:- implementation.
:- import_module bool.
:- import_module char.
:- import_module getopt_io.
:- import_module list.
:- import_module maybe.
:- import_module string.
:- import_module time.

%-------------------------------------------------------------------------------%

:- type option
    --->    makefile_flag
    ;       help_flag.

:- pred short_option(char::in, option::out) is semidet.
short_option('m', makefile_flag).
short_option('h', help_flag).

:- pred long_option(string::in, option::out) is semidet.
long_option("makefile", makefile_flag).
long_option("help", help_flag).

:- pred default_option(option::out, option_data::out) is multi.
default_option(makefile_flag, bool(no)).
default_option(help_flag, bool(no)).

%-------------------------------------------------------------------------------%

main(!IO) :-
    io.command_line_arguments(RawArgs, !IO),
    Config = option_ops_multi(short_option, long_option, default_option),
    getopt_io.process_options_io(Config, RawArgs, Args, RestOpts, !IO),
    (
        RestOpts = ok(Options),
        (
            if getopt_io.lookup_bool_option(Options, help_flag, yes) then
                usage(!IO)
            else if Args = [ModuleName] then
                TM = time.gmtime(Time_t),
                DateString = time.asctime(TM),
                get_git_author_name(AuthorName, !IO),
                time.time(Time_t, !IO),
                create_template(ModuleName, AuthorName, DateString, !IO),
                (
                    if getopt_io.lookup_bool_option(Options, makefile_flag, yes)
                    then create_makefile(ModuleName, !IO)
                    else true
                )
            else usage(!IO)
        )
    ;
        RestOpts = error(Reason),
        io.progname_base("mercury_template", Program, !IO),
        io.format(io.stderr_stream, "%s: %s\n",
            [s(Program), s(option_error_to_string(Reason))], !IO),
        usage(!IO)
    ).

%-------------------------------------------------------------------------------%

:- pred create_template(string::in, string::in, string::in, io::di, io::uo) is det.

create_template(ModuleName, AuthorName, DateString, !IO) :-
    io.open_output(ModuleName ++ ".m", Result, !IO),
    (
        Result = ok(File),
        io.write_strings(File, [
                                 "%-------------------------------------------------------------------------------%\n",
                                 "% vim: ft=mercury ts=4 sw=4 et\n",
                                 "%-------------------------------------------------------------------------------%\n",
                                 "%\n",
                                 "% File: ", ModuleName, ".m\n",
                                 "% Author: ", AuthorName, "\n",
                                 "% Date: ", DateString,
                                 "%\n",
                                 "% Purpose: Description of the program\n",
                                 "%\n",
                                 "%-------------------------------------------------------------------------------%\n\n",
                                 ":- module ", ModuleName, ".\n",
                                 ":- interface.\n",
                                 ":- import_module io.\n",
                                 ":- pred main(io::di, io::uo) is det.\n\n",
                                 "%-------------------------------------------------------------------------------%\n\n",
                                 ":- implementation.\n",
                                 "main(!IO) :-\n",
                                 "    % Your code here.\n\n",
                                 "     usage(!IO).\n\n",
                                 ":- pred usage(io::di, io::uo) is erroneous.\n",
                                 "usage(!IO) :-\n",
                                 "    UsageString = \"Usage: ", ModuleName, " <args>\", \n",
                                 "    die(UsageString, !IO).\n\n",
                                 ":- pred die(string::in, io::di, io::uo) is erroneous.\n",
                                 "die(Error, !IO) :-\n",
                                 "    io.write_string(io.stderr_stream, Error, !IO),\n",
                                 "    die(!IO).\n\n",
                                 ":- pred die(io::di, io::uo) is erroneous.\n",
                                 ":- pragma foreign_proc(""C"",\n",
                                 "    die(_IO0::di, _IO::uo),\n",
                                 "    [will_not_call_mercury, promise_pure],\n",
                                 "    "" exit(1); ""). \n\n",
                                 "%-------------------------------------------------------------------------------%\n",
                                 ":- end_module ", ModuleName, ".\n",
                                 "%-------------------------------------------------------------------------------%\n"
                               ], !IO),
        io.close_output(File, !IO)
    ;
        Result = error(Error),
        io.write_string("Couldn't open file for writing: ", !IO),
        io.write_string(io.error_message(Error), !IO),
        io.nl(!IO)
    ).

:- pred create_makefile(string::in, io::di, io::uo) is det.

create_makefile(ModuleName, !IO) :-
    io.open_output("Makefile", Result, !IO),
    (
        Result = ok(File),
        io.write_strings(File, [
                                 "MC=mmc\n",
                                 "MLFLAGS=\n",
                                 "ALL: ", ModuleName, "\n\n",
                                 ModuleName, ": ", ModuleName, ".m\n",
                                 "\t$(MC) --make $(MLFLAGS) ", ModuleName, "\n\n",
                                 "clean:\n",
                                 "\t$(MC) --make clean\n\n",
                                 ".PHONY: ALL clean\n"
                               ], !IO),
        io.close_output(File, !IO)
    ;
        Result = error(Error),
        io.write_string("Couldn't open file for writing: ", !IO),
        io.write_string(io.error_message(Error), !IO),
        io.nl(!IO)
    ).

:- pred get_git_author_name(string::out, io::di, io::uo) is det.
get_git_author_name(Author, !IO) :-
    get_environment_var("GIT_AUTHOR_NAME", MaybeAuthor, !IO),
    (
        MaybeAuthor = yes(Author)
    ;
        MaybeAuthor = no,
        Author = ""
    ).

:- pred usage(io::di, io::uo) is erroneous.

usage(!IO) :-
    UsageString =
        "Usage: mercury_template [-mh] <module_name>\n" ++
        " -h, --help         display this message\n" ++
        " -m, --makefile     create a makefile\n\n",
    die(UsageString, !IO).

:- pred die(string::in, io::di, io::uo) is erroneous.
die(Error, !IO) :-
    io.write_string(io.stderr_stream, Error, !IO),
    die(!IO).

:- pred die(io::di, io::uo) is erroneous.
:- pragma foreign_proc("C",
    die(_IO0::di, _IO::uo),
    [will_not_call_mercury, promise_pure],
"
    exit(1);
").

%-------------------------------------------------------------------------------%
:- end_module mercury_template.
%-------------------------------------------------------------------------------%
