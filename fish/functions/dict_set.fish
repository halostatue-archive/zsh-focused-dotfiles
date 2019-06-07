function dict_set -a name key value -d 'Sets dict[name][key]=value'
  set -l dictkey (__dict_key_name $name $key)
  set -g $dictkey $value
end
