#! /bin/zsh

function()
{
  {
    (( ${+commands[--hzsh-is-caching]} )) ||
      source ${HOME}/.zsh/zsh.d/00-cache-initialization

    if --hzsh-is-caching ; then
      # Run this in the background
      for f in ${HOME}/.zshrc $(--hzsh-cache-path)/zcomp-${HOST}; do
        [ -f ${f} ] && zrecompile -qp ${f} && rm -f ${f}.zwc.old
      done
    fi

    if [[ ${OSTYPE} == darwin* ]]; then
      for env_var in PATH MANPATH; do
        launchctl setenv "$env_var" "${(P)env_var}" 2>/dev/null
      done
    fi
  } &!

  (( ${+options[interactive]} )) &&
    [[ ${options[interactive]} == 'on' ]] &&
    (( ${+commands[fortune]} )) && fortune
}
