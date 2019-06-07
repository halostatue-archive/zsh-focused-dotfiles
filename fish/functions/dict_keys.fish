function dict_keys -a name -d 'Shows all keys for dict[name]'
  set -l dictkey (__dict_key_name $name)
  set -l keys
  for key in (complete -C\$$dictkey)
    set -a keys (string unescape (string replace $dictkey '' $key))
  end
  printf '%s' $keys
end
