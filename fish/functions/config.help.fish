function config.help -a package
  test $_ = config
    and set -l command "config <package>"
    or set -l command "$_ config"

  test -z "$package"
    and set -l package "shell package"

  echo "Get and set $package configuration.

Usage
  $command (-l|--list) [<options>]
  $command (-g|--get) <key> [<options>]
  $command (-q|--query) <key> [<options>]
  $command (-s|--set) <key> [<value>] [<options>]
  $command (-u|--unset) <key> [<options>]

Actions
  --list      List all config keys and values
  --get       Get the value of a config key
  --query     Check if a key is set
  --set       Set a config key's value
  --unset     Remove a config key and value

Options
  -e|--edit     Edit a value with an editor
  -d|--default  Specify a value to use if a key is not set
"
end
