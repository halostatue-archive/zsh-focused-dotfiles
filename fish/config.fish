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

source (brew --prefix chruby-fish)/share/chruby/chruby.fish
source (brew --prefix chruby-fish)/share/chruby/auto.fish

if command -sq erl
    function erlv -d 'Show the current erlang version'
        set -l v (erl -eval 'io:fwrite(erlang:system_info(otp_release)), halt().' -noshell)
        set -l e (dirname (dirname (command -s erl)))
        set -l ff $e/releases/$v/OTP_{VERSION,RELEASE}
        for f in ff
            test -f $f
            and cat $f
        end
    end
end

test -d $HOME/.bin
and path:unique $HOME/.bin

functions -q path:make_unique
and path:make_unique

set CDPATH . ~/.links/ ~/dev ~/dev/kinetic ~/oss ~/oss/github ~

function l
    ll $argv
end
