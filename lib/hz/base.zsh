#! /usr/bin/env zsh

# Load zsh/files with a zf_ prefix (e.g., zf_chgrp, etc.)
zmodload -m -F zsh/files b:zf_\*

typeset -gA HZ_BANNER HZ_HELP HZ_USAGE
typeset -g HZ_COMMANDS_PREFIX

HZ_HELP=()
HZ_BANNER=()
HZ_USAGE=()
HZ_COMMANDS_PREFIX=hz-

HZ_HELP[COMMAND]="
Manage your Hz dotfiles installation.
"

--hz-version()
{
  --hz-once!
  builtin print "Hz v${HZ_VERSION}"
}


--hz-usage()
{
  --hz-once!
  local caller=${${1:-${funcstack[2]}}/hz-}

  builtin print "\nUsage: hz ${${HZ_USAGE[${caller}]}:-"${caller} [OPTIONS]"}"
}

# Place this at the top of any function to prevent it from being run more than
# once.
--hz-once!()
{
  [[ ${funcstack[2]} == ${0} ]] || eval "${funcstack[2]}() { }"
  true
}

--hz-halt()
{
  local rc=${?}

  builtin printf "%s\n" "${@}" >&2

  exit ${rc}
}

--hz-has-function()
{
  (( ${+functions[${1}]} ))
}

--hz-has-command()
{
  (( ${+commands[${1}]} ))
}

--hz-show-commands()
{
  --hz-once!
  local cmd banner
  local -i result
  local -a cmds

  for cmd ($(builtin whence -m ${HZ_COMMANDS_PREFIX}'*')); do
    [[ ${cmd:t} == ${HZ_COMMANDS_PREFIX}*-help ]] && continue
    [[ ${cmd:t} == ${HZ_COMMANDS_PREFIX}*-banner ]] && continue
    cmds+=(${${cmd:t}/${HZ_COMMANDS_PREFIX}})
  done

  (( ${#cmds} )) || return
  builtin print "Known Commands:"
  for cmd (${(ui)cmds}); do
    if (( ${+HZ_BANNER[${cmd}]} )); then
      builtin printf "\t%s\n\t\t%s\n" ${cmd} ${HZ_BANNER[${cmd}]}
    else
      if --hz-has-${HZ_COMMANDS_PREFIX}command ${cmd}-banner; then
        banner=$(${HZ_COMMANDS_PREFIX}${cmd}-banner)
      else
        banner=$(${HZ_COMMANDS_PREFIX}${cmd} -banner)
        case $? in
          0)    # Success, banner is set.
            : ;;
          123)  # This command is invisible.
            continue ;;
          *)    # Failure
            banner=
            ;;
        esac
      fi

      (( !${#banner} )) && --hz-has-${HZ_COMMANDS_PREFIX}command ${cmd} &&
        banner="(external)"

      if (( ${#banner} )); then
        builtin printf "\t%s\n\t\t%s\n" ${cmd} ${banner}
      else
        builtin printf "\t%s\n" ${cmd}
      fi
    fi
  done
}

HZ_BANNER[help]='Show help for Hz or for a Hz command.'
hz-help()
{
  --hz-version
  [[ ${HZ_COMMANDS_PREFIX} == hz- ]] && --hz-report-unknown-command ${1}
  --hz-usage ${1:-COMMAND}

  if (( !${#} )); then
    (( ${+HZ_HELP[COMMAND]} )) && builtin print ${HZ_HELP[COMMAND]}
    --hz-show-commands
  elif (( ${+HZ_HELP[${1}]} )); then
    builtin print ${HZ_HELP[${1}]}
  elif (( ${+HZ_HELP[${HZ_COMMANDS_PREFIX}${1}]} )); then
    builtin print ${HZ_HELP[${HZ_COMMANDS_PREFIX}${1}]}
  elif (( ${+HZ_BANNER[${1}]} )); then
    builtin print "\n${HZ_BANNER[${1}]}"
  elif (( ${+HZ_BANNER[${HZ_COMMANDS_PREFIX}${1}]} )); then
    builtin print "\n${HZ_BANNER[${HZ_COMMANDS_PREFIX}${1}]}"
  elif --hz-has-${HZ_COMMANDS_PREFIX}command ${1}-help; then
    exec ${HZ_COMMANDS_PREFIX}${1}-help
  elif --hz-has-${HZ_COMMANDS_PREFIX}command ${1}; then
    exec ${HZ_COMMANDS_PREFIX}${1} -help
  else
    builtin print "\nNo help for 'hz ${1}'."
  fi
}

--hz-subcommand-prefix()
{
  (( ${#1} )) || return

  HZ_COMMANDS_PREFIX=${1}-
  eval $'
--hz-has-${HZ_COMMANDS_PREFIX}function()
{
  --hz-has-function ${HZ_COMMANDS_PREFIX}${1}
}

--hz-has-${HZ_COMMANDS_PREFIX}command()
{
  --hz-has-command ${HZ_COMMANDS_PREFIX}${1}
}

--hz-has-${HZ_COMMANDS_PREFIX}function-or-command()
{
  --hz-has-${HZ_COMMANDS_PREFIX}function ${1} || --hz-has-${HZ_COMMANDS_PREFIX}command ${1}
}
'
}
