# Install fisher if not already installed.
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

set -qU PROJECT_PATHS
or set -U PROJECT_PATHS \
    ~/dev/kinetic \
    ~/dev/kinetic/aldo \
    ~/dev/kinetic/kcp \
    ~/oss \
    ~/oss/mime-types-org \
    ~/oss/halostatue

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
        set -l ff $e{,/lib/erlang}/releases/$v/OTP_{VERSION,RELEASE}
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

function marked
    for d in $argv
        if test -d $d
            marked $d/*.md
        else
            open -a Marked $d
        end
    end
end

function json-clean
    pbpaste | jq . | pbcopy
end

function lowes_clean_dump
    pushd ~/dev/kinetic/lowes
    and env DATABASE_POSTGRESQL_NAME=lowes_loyalty_clean mix do ecto.drop, ecto.create, ecto.migrate
    and popd
end

function restoredb
    # pg_restore --verbose --clean -Fc -x --if-exists -d $database $filename
    # pg_restore --verbose --clean --create -Fc -x --if-exists $filename

    pg_restore --verbose --clean -Fc -x --if-exists -j4 --no-acl --no-owner $argv[1]
end

function restoremysql
    mysql -u root <$argv[1]
end

function magic_enter
    if test -z (string join0 (commandline))
        if git_is_repo
            set -q MAGIC_ENTER_GIT_COMMAND
            or set MAGIC_ENTER_GIT_COMMAND 'git status -u .'
            eval $MAGIC_ENTER_GIT_COMMAND
        else
            set -q MAGIC_ENTER_OTHER_COMMAND
            or set MAGIC_ENTER_OTHER_COMMAND 'ls -lh .'
            eval $MAGIC_ENTER_OTHER_COMMAND
        end

        echo ""

        commandline -f repaint
    else
        commandline -f execute
    end
end

bind \cq magic_enter
bind -k enter magic_enter
bind \r magic_enter
bind \n magic_enter

# set -gx HOMEBREW_FORCE_VENDOR_RUBY 1

functions -q fallback
or function fallback --description 'allow a fallback value for variable'
    if test (count $argv) = 1
        echo $argv
    else
        echo $argv[1..-2]
    end
end

functions -q get_ext
or function get_ext --description "Get the file extension from the argument"
    set -l splits (string split "." "$argv")
    echo $splits[-1]
end


## App shortcuts with completion for filetype

if functions -q is:mac
    and is:mac
    function acorn
        open -a Acorn $argv
    end
    complete -c acorn -d "Image" -a "*.{png,jpg,jpeg,psd}"
    complete -c acorn -d "Acorn" -a "*.acorn"

    function alpha
        open -a ImageAlpha $argv
    end
    complete -c alpha -d "Image" -a "*.{png,gif}"

    function optim
        open -a ImageOptim $argv
    end
    complete -c optim -d "Image" -a "*.{png,jpg,jpeg,gif}"

    function by
        open -a Byword $argv
    end
    complete -c by -d "Markdown File" -a "*.{md,mkd,mmd,markdown,mkdn}"
    complete -c by -d "Text File" -a "*.{text,txt}"

    function chrome
        open -a '/Applications/Google Chrome.app' $argv
    end
    complete -c chrome -d "HTML File" -a "*.{html,htm}"

    function mmdc
        open -a '/Applications/MultiMarkdown Composer.app' $argv
    end
    complete -c mmdc -d "Markdown File" -a "*.{md,mkd,mmd,markdown,mkdn}"
    complete -c mmdc -d "Text File" -a "*.{text,txt}"

    function tp
        open -a TaskPaper $argv
    end
    complete -c tp -d "TaskPaper File" -a "*.taskpaper"

    function xc
        open -a Xcode $argv
    end
    complete -c xc -d "Xcode project" -a "*.xcodeproj"

    function imgsize --description "Quickly get image dimensions from the command line"
        if test -f $argv
            set -l height (sips -g pixelHeight "$argv"|tail -n 1|awk '{print $2}')
            set -l width (sips -g pixelWidth "$argv"|tail -n 1|awk '{print $2}')
            echo "$width x $height"
        else
            echo "File not found"
        end
    end

    function o
        open -a $argv
    end
    complete -c o -a (basename -s .app /Applications{,/Setapp}/*.app|awk '{printf "\"%s\" ", $0 }')

    function dash -d "Open argument in Dash"
        open "dash://"(urlenc $argv)
    end

    function dman -d "Open man page in Dash"
        open "dash://man:"(urlenc $argv)
    end

    # flying through bundle identifiers more efficiently than `osascript`, faster than `defaults read`, it's `bid` to the rescue!
    # fuzzy string matching, returns title and bundle id for first match
    # `bid preview`
    function bid -d "Get bundle id for app name"
        # (and remove ".app" and escapes from the end if it exists due to autocomplete)
        set -l shortname (echo "$argv"| sed -E 's/\.app$//'|sed 's/\\\//g')
        set -l location
        # if the file is a match in apps folder, don't spotlight
        if test -d "/Applications/$shortname.localized/$shortname.app"
            set location "/Applications/$shortname.localized/$shortname.app"
        else if test -d "/Applications/$shortname.app"
            set location "/Applications/$shortname.app"
        else # use spotlight
            set location (mdfind -onlyin /Applications -onlyin /Applications/Setapp -onlyin /Applications/Utilities -onlyin ~/Applications -onlyin /Developer/Applications "kMDItemKind==Application && kMDItemDisplayName=='*$shortname*'cdw"|head -n1)
        end
        # No result? Die.
        if test -z $location
            echo "$argv not found, I quit"
            return
        end
        # Find the bundleid using spotlight metadata
        set -l bundleid (mdls -name kMDItemCFBundleIdentifier -r "$location")
        # return the result or an error message
        if test -z $bundleid
            echo "Error getting bundle ID for \"$argv\""
        else
            echo "$location: $bundleid"
        end
    end
end

if command -sq code-insiders
    function code
        code-insiders $argv
    end
end

if command -sq pngcrush
    function crush -d "pngcrush"
        pngcrush -e _sm.png -rem alla -brute -reduce $argv
    end
    complete -c crush -d "PNG" -a "*.png"
end

function degit -d "Remove all traces of git from a folder"
    find . -name '.git' -exec rm -rf {} \;
end

if command -sq pandoc
    function docx2md --description "Convert docx to markdown: docx2md [source] [target]"
        pandoc -o "$2" --extract-media=(dirname "$argv[2]") "$argv[1]"
    end
end

function 64enc -d "encode a given image file as base64 and output css background property to clipboard"
    openssl base64 -in "$argv" | awk -v ext=(get_ext $argv) '{ str1=str1 $0 }END{ print "background:url(data:image/"ext";base64,"str1");" }' | pbcopy
    echo "$argv encoded to clipboard"
end

function 64font -d "encode a given font file as base64 and output css background property to clipboard"
    openssl base64 -in "$argv" | awk -v ext=(get_ext $argv) '{ str1=str1 $0 }END{ print "src:url(\"data:font/"ext";base64,"str1"\")  format(\""ext"\");" }' | pbcopy
    echo "$argv encoded as font and copied to clipboard"
end

function lt -d "List directory from oldest to newest"
    ls -Atr1 $argv && echo "------Newest--"
end

function ltr -d "List directory from newest to oldest"
    ls -At1 $argv && echo "------Oldest--"
end

# function __should_na --on-variable PWD
#   set -l cmd (history --max=1|awk '{print $1;}')
#   set -l cds cd z j popd g
#   if contains $cmd $cds
#     test -s (basename $PWD)".taskpaper" && ~/scripts/fish/na
#   end
# end

# function ...;cd ../..;end
# function ....;cd ../../..;end

# function ax -d "Make file executable"
#   chmod a+x $argv
# end

# function cat;bat --style plain --theme OneHalfDark $argv;end
# function c;clear;end

# function flush -d "Flush DNS cache"
#   sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder
# end

# function _up -d "inspired by `bd`: https://github.com/vigneshwaranr/bd"
#   set -l rx (ruby -e "print '$argv'.gsub(/\s+/,'').split('').join('.*?')")
#   # fish doesn't allow ${var} protection
#   # so the square brackets are interpreted as array counters...
#   set -l rx (printf "/(.*\/%s[^\/]*\/).*/i" $rx)
#   echo $PWD | ruby -e "print STDIN.read.sub($rx,'\1')"
# end

# function up -d "cd to a parent folder with fuzzy matching"
#   if test (count $argv) -eq 0
#     echo "up: traverses up the current working directory to first match and cds to it"
#     echo "Missing argument"
#   else
#     cd (_up "$argv")
#   end
# end

# function urlenc -d "url encode the passed string"
#   if test (count $argv) > 0
#     echo -n "$argv" | perl -pe's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg'
#   else
#     command cat | perl -pe's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg'
#   end
# end

# set_color 8aC374 && figlet -f block -w 80 "The Lab"

# command -sq starship; and starship init fish | source

command -sq pipx
and command -sq register-python-argcomplete
and register-python-argcomplete --shell fish pipx | source

set -U pisces_only_insert_at_eol 1

emit fish_postexec
