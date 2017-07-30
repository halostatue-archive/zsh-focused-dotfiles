#! /bin/zsh

function()
{
  {
    (( ${+commands[--hzsh-is-caching]} )) ||
      source ${HOME}/.zsh/zsh.d/00-cache-initialization

    if --hzsh-is-caching; then
      { # Run this in the background
        local cache
        assign-output-to cache --hzsh-cache-path

        local -a files
        files=(${HOME}/.z{login,profile,compdump,sh{env,rc{,-local}}})
        files+=(${cache}/zcomp-${HOST})
        for f ($files); do
          [[ -f ${f} ]] && zrecompile -qp ${f} && rm -f ${f}.zwc.old
        done
      } &!

      { # Run this in the background
        --zrecompile
      } &!
    fi
  }

  if [[ ${OSTYPE} == darwin* ]]; then
    for env_var in PATH MANPATH; do
      launchctl setenv "${env_var}" "${(P)env_var}" 2>/dev/null
    done
  fi

  (( ${+options[interactive]} )) &&
    [[ ${options[interactive]} == 'on' ]] &&
    (( ${+commands[fortune]} )) && fortune
}
