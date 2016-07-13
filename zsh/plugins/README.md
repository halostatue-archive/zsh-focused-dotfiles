# Austin's zsh plug-in system

This is a fairly simple but robust plug-in system for zsh. A plug-in under
this system is a directory that contains an optional detection file (`detect`)
and at least one item that changes the environment:

* an `init` directory with one or more scripts inside;
* an `init` script;
* a `functions` directory with one or more zsh function scripts inside;
* a `functions` script; or
* a `completion` directory with one or more zsh function scripts used for
  completion inside;
* a `bin` directory with one or more binaries inside.

A zsh plug-in for `git` might have a directory structure like this:

    plugins/
      git/
        bin/
          git-tag-versions
          git-darcs-record
          hub
          githack
          gitship
        completion/
          _git-rm
        detect
        functions/
          zgitinit
        init

## Plug-in Activation

During the initialization of the Zsh environment, `~/.zsh/plugins/loader` will
be run. This script loops through the immediate subsdirectories of the plug-in
path (set by default to `~/.zsh/plugins`):

1.  If the directory name (which is treated as the plug-in name) is present in
    the style `:hzsh:plugins disabled` or the style `:hzsh:plugins:NAME
    enabled` is not true, the plug-in is skipped. Note that the plug-in may be
    reconsidered later, as described below.
2.  If the directory contains a file called `detect`, the contents of this
    file are used to determine whether the plug-in can be loaded. See PLUG-IN
    DETECTION for more information.
3.  If the directory does NOT contain a file called `detect`, but the style
    `:hzsh:plugins enabled` contains the name of the directory, or the style
    `:hzsh:plugins:NAME enabled` is true, the plug-in is considered detected.

If the plug-in has been successfully detected for activation, it is then
initialized:

1.  If the plug-in contains a directory called `init`, each normal file (not
    ending in `~` or `DISABLED`) is sourced.
2.  If the plug-in contains a file called `init`, it is sourced.
3.  If the plug-in contains a directory called `functions`, the directory is
    added to the beginning of the `$fpath` array.
4.  If the plug-in contains a file called `functions`, it is sourced.
5.  If the plug-in contains a directory called `bin`, it is added to the
    beginning of `$PATH`.

If a plug-in modifies `$PATH` or calls the function
`__hzsh_retry_plugin_search`, the plug-in discovery and initialization will be
repeated for plug-ins that have not yet been discovered.

## Plug-in Detection

When a plug-in has a `detect` file, it is parsed for directives that specify
conditions the must all be met during the detection phase(s). This file is
*not* a zsh script. The general format for the `detect` script is:

    DIRECTIVE PARAMETERS

The directives are:

* command
* alternates
* do
* do-return
* directory
* file
* executable

A plug-in will only be activated if **all** of the directives in the detection
script pass and should be kept fairly simple for speed purposes.

### command, alternates

    command COMMAND
    alternates COMMAND+

The `command` directive tests to see if the provided *COMMAND* is a program,
script, or shell function that exists. By default, the word `command` is
optional; any a *COMMAND* that appears on a line by itself will be treated as
having an implicit `command` directive.

This returns true if the output of the zsh builtin `command -v` returns any
value.

    command git

This will be true if `git` is in your `$PATH`.

The `alternates` directive works exactly like the `command` directive if only
one *COMMAND* is provided. If more than one *COMMAND* is provided, the
`command` test is run for each *COMMAND* provided, but only **one** of the
provided *COMMAND* parameters must exist for the result to be true.

    alternates jruby macruby ruby

This will be true if `jruby`, `macruby`, or `ruby` are in your `$PATH`.

### do, do-return

    do COMMAND [PARAMETERS]
    do-return VALUE COMMAND [PARAMETERS]

The `do` directive is followed by a *COMMAND* that will be executed with the
(optionally) provided PARAMETERS. Any output (both `stdout` and `stderr`) is
discarded and the shell return value (`$?`) will be used to determine whether
this directive passes in the usual shell manner (e.g., `$?` must be 0 to be
true).

    do is-mac

This will be true if the shell function `is-mac` returns true (in this case, if
`$OSTYPE` matches `*darwin*`).

The `do-return` directive executes the named *COMMAND* with the (optionally)
provided *PARAMETERS*, discarding any output. The shell return value must match
the provided *VALUE*, not zero.

    do-return 1 is-mac

This will be true if the shell function `is-mac` does *not* return true (in
this case, if `$OSTYPE` does *not* match `*darwin*`).

### directory, file, executable

    directory PATH+
    file PATH+
    executable PATH+

These directives will test to see if one or more provided *PATH* value exist.
`directory` uses the result of `test -d`; `file` uses the result of `test -f`;
and `executable` uses the result of `test -x`. Before testing the provided
*PATH* values, the *PATH* list is eval-echoed (`mypath=$(eval "echo PATH")`)
so that environment variables and glob expansions are resolved. As with
`alternates`, only one of the resolved paths must match the condition to be
true.

> **Note** that the `directory`, `file`, and `executable` directives won't
> work with paths that have spaces in them, even if they are quoted or
> escaped.

    directory ~/.rvm

This will be true if the directory `.rvm` exists in the user's home directory.

    file /etc/debian_version

This will be true if the file `/etc/debian_version` exists.

    executable ${GOROOT:-${HOME}/go}/src/all.bash

This will be true if the file `${GOROOT}/src/all.bash` exists and is
executable; should the environment variable `${GOROOT}` not exist, the default
value `${HOME}/go` will be used, looking for `${HOME}/go/src/all.bash`.
