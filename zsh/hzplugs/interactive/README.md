# hzsh Interactive Plug-In

## `zstyle` Options

These options generally only affect startup of the shell.

`:hzsh:plugins:interactive human-readable-sizes`
: Humanizes the size output of various commands to use human-readable size
suffixes (e.g., KB, MB, GB). Uses the base-2 SI versions (actually KiB, MiB,
etc.) rather than base-10 SI versions. Enabled by default.

`:hzsh:plugins:interactive:color enable`
: Enables colour output from various programs like `ls` and `grep`. Enabled by
default.

`:hzsh:plugins:interactive:sudo with-xauthority`
: Creates an alias for `sudo` that exports the `XAUTHORITY` environment
variable. Enabled by default.

`:hzsh:plugins:interactive:open extensions`
: The list of extensions that will be opened through the function call-open
(which wraps 'open' on OS X and the appropriate *-open on Linux). Not set by
default.
