function path:unique -d 'Ensures that the provided value is unique in $PATH or $MANPATH'
    argparse -n(status function) -N1 'm/man' 'a/append' 't/test' -- $argv
    or return

    set -l var PATH
    test -z {$_flag_man}
    or set var MANPATH

    set -l prepend true
    test -z {$_flag_append}
    or set prepend false

    set -l test false
    test -z {$_flag_test}
    or set test true

    for item in $argv
        if $test
            test -d $item
            or continue
        end

        if $prepend
            set $var $item (string match -v $item $$var)
        else
            set $var (string match -v $item $$var) $item
        end
    end
end
