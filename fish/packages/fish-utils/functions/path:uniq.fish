function path:make_unique -d 'Makes sure that each entry in $PATH or $MANPATH is uniq, with order preserved.'
    argparse -n(status function) -X0 'm/man' -- $argv
    or return

    set -l var PATH
    test -z {$_flag_man}
    or set var MANPATH

    set -l value

    for item in $$var
        string match -q $item $value
        and continue

        set value $value $item
    end

    set $var $value
end
