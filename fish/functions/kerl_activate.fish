function kerl_activate
  source (kerl path $argv[1])/activate.fish
  set -l vars (set -n | grep _KERL)
  for var in (set -n | grep _KERL)
    set -gx $var $$var
  end
end
