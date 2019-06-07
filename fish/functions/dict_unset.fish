function dict_unset -a name key -d 'Clears the value of dict[name][key]'
  set -l dictkey (__dict_key_name $name $key)
  set -g -e $dictkey
end
