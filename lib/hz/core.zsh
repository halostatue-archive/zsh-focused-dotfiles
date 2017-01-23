#! /usr/bin/env zsh

--hz-report-unknown-command()
{
  (( ${#} )) || return
  --hz-has-hz-function-or-command ${1} && return

  hz-version >&2
  builtin printf >&2 "\nUnknown command '${HZ_BN0} ${1}'.\n"
  hz-commands >&2

  exit 1
}

--hz-has-hz-function()
{
  --hz-has-function hz-${1}
}

--hz-has-hz-command()
{
  --hz-has-command hz-${1}
}

--hz-has-hz-function-or-command()
{
  --hz-has-hz-function ${1} || --hz-has-hz-command ${1}
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
  ${HZ_OPTION_DEBUG} && --hz-install-gem byebug
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
  local -a force debug
  force=()
  debug=()
  zparseopts -D -K -E -a force f force -force D=debug debug=debug -debug=debug
  hz_modified_args=("${@}")
  (( ${#force} )) && HZ_OPTION_FORCE=true
  (( ${#debug} )) && HZ_OPTION_DEBUG=true
}
