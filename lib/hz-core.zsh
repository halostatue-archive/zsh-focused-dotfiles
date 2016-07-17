#! /usr/bin/env zsh

zmodload -m -F zsh/files b:zf_\*

--hz-once!()
{
  [[ ${funcstack[2]} == ${0} ]] || eval "${funcstack[2]}() { }"
  true
}

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
  # builtin print "\nUsage: hz ${caller} [OPTIONS]"
}

--hz-show-commands()
{
  --hz-once!
  local cmd short
  local -a cmds

  for cmd ($(builtin whence -m 'hz-*')); do
    [[ ${cmd:t} == hz-*-help ]] && continue
    cmds+=(${${cmd:t}/hz-})
  done

  builtin print "\nCommands:"
  for cmd (${(ui)cmds}); do
    if (( ${+HZ_BANNER[${cmd}]} )); then
      builtin printf "\t%s\n\t\t%s\n" ${cmd} ${HZ_BANNER[${cmd}]}
    else
      builtin printf "\t%s\n" ${cmd}
    fi
  done
}

--hz-halt()
{
  local rc=${?}

  builtin printf "%s\n" "${@}" >&2

  exit ${rc}
}

--hz-has-function()
{
  (( ${+functions[hz-${1}]} ))
}

--hz-has-command()
{
  (( ${+commands[hz-${1}]} ))
}

--hz-install-gem()
{
  if (( $(command gem list ${1} | command grep -c ${1}) < 1 )); then
    command gem install ${1} --no-ri --no-rdoc > /dev/null ||
      --hz-halt "Could not install gem ${1}."
  fi
}

--hz-ruby-hz()
{
  command ruby -Ilib -rhz -e "${*}"
}

--hz-setup()
{
  --hz-once!
  --hz-internal-gem-repo-setup
}

# Set up the private gem environment, once. This function will undefine itself
# once run.
--hz-internal-gem-repo-setup()
{
  --hz-once!

  # Handle an already-installed chruby specially by doing a reset (the same as
  # chruby_reset).
  if [[ -n "${RUBY_ROOT}" ]]; then
    PATH=":${PATH}:"
    PATH="${PATH//:${RUBY_ROOT}\/bin:/:}"
    [ -n "${GEM_HOME}" ] && PATH="${PATH//:${GEM_HOME}\/bin:/:}"
    [ -n "${GEM_ROOT}" ] && PATH="${PATH//:${GEM_ROOT}\/bin:/:}"

    GEM_PATH=":${GEM_PATH}:"
    GEM_PATH="${GEM_PATH//:${GEM_HOME}:/:}"
    GEM_PATH="${GEM_PATH//:${GEM_ROOT}:/:}"
    GEM_PATH="${GEM_PATH#:}"
    GEM_PATH="${GEM_PATH%:}"
    [ -z "${GEM_PATH}" ] && builtin unset GEM_PATH
    builtin unset GEM_ROOT GEM_HOME

    PATH="${PATH#:}"
    PATH="${PATH%:}"
    builtin unset RUBY_ROOT RUBY_ENGINE RUBY_VERSION RUBYOPT
    builtin hash -r
  fi

  eval "$(
  ruby - <<EOF
begin; require 'rubygems'; rescue LoadError; end
puts "export RUBY_ENGINE=#{defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'};"
puts "export RUBY_VERSION=#{RUBY_VERSION};"
puts "export GEM_ROOT=#{Gem.default_dir.inspect};" if defined? Gem
EOF
)"

  export GEM_HOME="${HZ_INTERNAL}/${RUBY_ENGINE}/${RUBY_VERSION}"
  export GEM_PATH="${GEM_HOME}${GEM_ROOT:+:${GEM_ROOT}}${GEM_PATH:+:${GEM_PATH}}"
  export PATH="${GEM_HOME}/bin${GEM_ROOT:+:${GEM_ROOT}/bin}:${PATH}"
  builtin zf_mkdir -p ${GEM_HOME}
}

--hz-install-highline()
{
  --hz-install-gem highline
}

--hz-parse-global-opts()
{
  --hz-once!
  local -a force
  force=()
  zparseopts -D -K -E -a force f force -force
  hz_modified_args=("${@}")
  (( ${#force} )) && HZ_OPTION_FORCE=true
}
