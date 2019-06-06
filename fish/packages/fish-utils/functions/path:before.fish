function path:before -d 'Prepend items to $PATH or $MANPATH uniquely'
    argparse -n(status function) -N1 'm/man' 'a/append' 't/test' -- $argv
    or return

    path:unique {$_flag_man} {$_flag_test} $argv
end
