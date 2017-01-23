#! /usr/bin/env zsh

HZ_BANNER[version]="Show the current version of Hz."
hz-version() { --hz-version }

HZ_BANNER[commands]="Show all commands known to Hz."
hz-commands()
{
  --hz-once!
  hz-help
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

HZ_BANNER[user-backup]="Create an archive of user data"
HZ_HELP[user-backup]=$'
Backs up the current user data configuration as "user-backup.tar.gz".
'
hz-user-backup()
{
  if [[ -d user ]]; then
    tar cfz user-backup.tar.gz user
  else
    builtin print "No user data to back up."
  fi
}
