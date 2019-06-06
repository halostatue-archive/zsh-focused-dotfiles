function dict_clear -a name -d 'Clears all values from dict[name]'
  set -l dictkey (__dict_key_name $name)
  for key in (complete -C\$$dictkey)
    echo $key
    set -ge $key
  end
end
