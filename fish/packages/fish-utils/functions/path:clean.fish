function path:clean -d 'Clean the specified paths from $PATH or $MANPATH'
    argparse -n(status function) -N1 'm/man' -- $argv
    or return

    set -l var PATH
    test -z {$_flag_man}
    or set var MANPATH

    for item in $argv
        set $var (string match -v {$item} $$var)
    end
end
