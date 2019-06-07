function dict_get -a name key -d 'Returns dict[name][key]'
  set -l dictkey (__dict_key_name $name $key)
  printf '%s' $$dictkey
end
