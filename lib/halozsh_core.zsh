#! /usr/bin/env zsh

--halozsh-halt() {
  rc=${?}

  builtin printf "%s\n" "${@}" >&2

  exit ${rc}
}

--halozsh-has-function() {
  (( ${+functions[halozsh-${1}]} )) || return 1
}

--halozsh-has-command() {
  (( ${+commands[halozsh-${1}]} )) || return 1
}

--halozsh-gem-install() {
  gem install ${1} --no-ri --no-rdoc > /dev/null ||
    --halozsh-halt "Could not install gem ${1}."
}

--halozsh-gem-conditional-install() {
  if [ $(gem list ${1} | grep -c ${1}) -lt 1 ]; then
    --halozsh-gem-install ${1}
  fi
}

--halozsh-rake() {
  --halozsh-install-rake
  --halozsh-install-highline
  rake -f ${HALOZSH_LIB}/halozsh.rake "${@}"
}


# Set up the gem environment
--halozsh-gem-setup() {
  # Handle an already-installed chruby specially by doing a reset (the same as
  # chruby_reset).
  --halozsh-chruby-reset

  eval "$(
  ruby - <<EOF
begin; require 'rubygems'; rescue LoadError; end
puts "export RUBY_ENGINE=#{defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'};"
puts "export RUBY_VERSION=#{RUBY_VERSION};"
puts "export GEM_ROOT=#{Gem.default_dir.inspect};" if defined? Gem
EOF
)"

  export GEM_HOME="${HALOZSH_ROOT}/.gem/${RUBY_ENGINE}/${RUBY_VERSION}"
  export GEM_PATH="${GEM_HOME}${GEM_ROOT:+:${GEM_ROOT}}${GEM_PATH:+:${GEM_PATH}}"
  export PATH="${GEM_HOME}/bin${GEM_ROOT:+:${GEM_ROOT}/bin}:${PATH}"
  mkdir -p ${GEM_HOME}
}

--halozsh-install-rake() {
  [ -n "${rake_version}" ] && return

  if --halozsh-has-command rake; then
    rake_version=$(rake -V | sed -e 's/^rake, version \(.*\)\..*\..*$/\1/')
  else
    rake_version=0
  fi

  if (( ${rake_version} < 10 )); then
    --halozsh-gem-install rake && hash -r &&
      rake_version=$(rake -V | sed -e 's/^rake, version \(.*\)\..*\..*$/\1/')
  fi
}

--halozsh-install-highline() {
  --halozsh-gem-conditional-install highline
}

function --halozsh-chruby-reset {
  [ -z "${RUBY_ROOT}" ] && return

  PATH=":${PATH}:"
  PATH="${PATH//:${RUBY_ROOT}\/bin:/:}"
  [ -n "${GEM_HOME}" ] && PATH="${PATH//:${GEM_HOME}\/bin:/:}"
  [ -n "${GEM_ROOT}" ] && PATH="${PATH//:${GEM_ROOT}\/bin:/:}"

  GEM_PATH=":${GEM_PATH}:"
  GEM_PATH="${GEM_PATH//:${GEM_HOME}:/:}"
  GEM_PATH="${GEM_PATH//:${GEM_ROOT}:/:}"
  GEM_PATH="${GEM_PATH#:}"; GEM_PATH="${GEM_PATH%:}"
  [ -z "${GEM_PATH}" ] && unset GEM_PATH
  unset GEM_ROOT GEM_HOME

  PATH="${PATH#:}"
  PATH="${PATH%:}"
  unset RUBY_ROOT RUBY_ENGINE RUBY_VERSION RUBYOPT
  hash -r
}
