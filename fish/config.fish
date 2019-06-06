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
