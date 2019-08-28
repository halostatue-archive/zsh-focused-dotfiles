if not functions -q fisher
    set -q XDG_CONFIG_HOME
    or set XDG_CONFIG_HOME ~/.config
    curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
    fish -c fisher
end

function __source_or_create -a name type
    set -l name {$__fish_config_dir}/$name.fish
    if test -f $name
        source $name
    else
        mkdir -p (dirname $name)
        echo Creating $type file: $name
        touch $name
    end
end

__source_or_create platforms/(string lower (uname -s)) platform
__source_or_create hosts/(string lower (string replace -r '\.(local|home)' '' (hostname))) host
__source_or_create users/(string lower (whoami)) user

functions -e __source_or_create

functions -q has:keg
and has:keg chruby-fish
and begin
    source (brew --prefix chruby-fish)/share/chruby/chruby.fish 
    # source (brew --prefix chruby-fish)/share/chruby/auto.fish
    set -Ux RUBIES $RUBIES
end

if command -sq erl
    function erlv -d 'Show the current erlang version'
        set -l v (erl -eval 'io:fwrite(erlang:system_info(otp_release)), halt().' -noshell)
        set -l e (dirname (dirname (command -s erl)))
        set -l ff $e/releases/$v/OTP_{VERSION,RELEASE}
        for f in $ff
            test -f $f
            and cat $f
        end
    end
end

if command -sq fzf
    function fp --description 'Search your $PATH'
        set -l loc (echo $PATH | tr ' ' '\n' | eval "fzf $FZF_DEFAULT_OPTS --header='[find:path]'")

        if test (count $loc) = 1
            set -l cmd (rg --files -L $loc | rev | cut -d'/' -f1 | rev | tr ' ' '\n' | eval "fzf $FZF_DEFAULT_OPTS --header='[find:exe] => $loc'")
            if test (count $cmd) = 1
                echo $cmd
            else
                fp
            end
        end
    end

    function kp --description "Kill processes"
        set -l __kp__pid ''

        if contains -- '--tcp' $argv
            set __kp__pid (lsof -Pwni tcp | sed 1d | eval "fzf $FZF_DEFAULT_OPTS -m --header='[kill:tcp]'" | awk '{print $2}')
        else
            set __kp__pid (ps -ef | sed 1d | eval "fzf $FZF_DEFAULT_OPTS -m --header='[kill:process]'" | awk '{print $2}')
        end

        if test "x$__kp__pid" != "x"
            if test "x$argv[1]" != "x"
                echo $__kp__pid | xargs kill $argv[1]
            else
                echo $__kp__pid | xargs kill -9
            end
            kp
        end
    end

    function ks --description "Kill http server processes"
        set -l __ks__pid (lsof -Pwni tcp | sed 1d | eval "fzf $FZF_DEFAULT_OPTS -m --header='[kill:tcp]'" | awk '{print $2}')
        set -l __ks__kc $argv[1]

        if test "x$__ks__pid" != "x"
            if test "x$argv[1]" != "x"
                echo $__ks__pid | xargs kill $argv[1]
            else
                echo $__ks__pid | xargs kill -9
            end
            ks
        end
    end

    if command -sq rg
        set -gx FZF_DEFAULT_COMMAND 'rg --files --no-ignore-vcs --hidden'
    end

    function gcb --description "delete git branches"
        set delete_mode '-d'

        if contains -- '--force' $argv
            set force_label ':force'
            set delete_mode '-D'
        end

        set -l branches_to_delete (git branch | sed -E 's/^[* ] //g' | fzf -m --header="[git:branch:delete$force_label]")

        if test -n "$branches_to_delete"
            git branch $delete_mode $branches_to_delete
        end
    end

    if command -sq brew
        function bip --description "Install brew plugins"
            set -l inst (brew search | eval "fzf $FZF_DEFAULT_OPTS -m --header='[brew:install]'")

            if not test (count $inst) = 0
                for prog in $inst
                    brew install "$prog"
                end
            end
        end

        function bcp --description "Remove brew plugins"
            set -l inst (brew leaves | eval "fzf $FZF_DEFAULT_OPTS -m --header='[brew:uninstall]'")

            if not test (count $inst) = 0
                for prog in $inst
                    brew uninstall "$prog"
                end
            end
        end
    end
end

functions -q path:unique
and path:unique --test $HOME/.local/bin $HOME/.bin $HOME/bin

functions -q path:make_unique
and path:make_unique

set CDPATH . ~/.links/ ~/dev ~/dev/kinetic ~/oss ~/oss/github ~

function l
    ll $argv
end

set -gx HOMEBREW_FORCE_VENDOR_RUBY 1
