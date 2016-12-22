#! /usr/bin/env zsh

typeset -gA HZ_BANNER HZ_HELP HZ_USAGE

HZ_HELP=()
HZ_BANNER=()
HZ_USAGE=()

HZ_BANNER[version]="Show the current version of Hz."
hz-version() { --hz-version }

HZ_BANNER[commands]="Show all commands known to Hz."
hz-commands()
{
  --hz-once!
  hz-help
}

HZ_BANNER[help]='Show help for Hz or for an Hz command.'
hz-help()
{
  --hz-version
  --hz-unknown-command ${1}
  --hz-usage ${1:-COMMAND}

  if (( !${#} )); then
    --hz-show-commands
  elif (( ${+HZ_HELP[${1}]} )); then
    builtin print ${HZ_HELP[${1}]}
  elif (( ${+HZ_BANNER[${1}]} )); then
    builtin print "\n${HZ_BANNER[${1}]}"
  elif --hz-has-command ${1}; then
    exec hz-${1} @help
  else
    builtin print "\nNo help for 'hz ${1}'."
  fi
}

HZ_BANNER[install]="Install Hz configuration."
hz-install()
{
  --hz-ruby-hz "Hz::Installer.run('${HZ_ROOT}', '${HZ_TARGET}', ${HZ_OPTION_FORCE:-false})"
}

if ${HZ_RUN_RELATIVE}; then
  HZ_BANNER[bootstrap]="Bootstrap Hz."
  HZ_HELP[bootstrap]=$'
Performs the initial configuration of Hz. Performs user data setup and installs
the Hz configuration like with `hz install`. This should only need to be run
once.
'

  hz-bootstrap()
  {
    --hz-once!
    builtin print "Bootstrapping Hz..."
    --hz-install-highline
    hz-user-setup
    hz-install
  }
fi

HZ_BANNER[user-setup]="Configure user data."
hz-user-setup()
{
  --hz-ruby-hz "Hz::UserData.run('${HZ_ROOT}', '${HZ_TARGET}')"
}
