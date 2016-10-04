#! /bin/zsh

function()
{
  {
    (( ${+commands[--hzsh-is-caching]} )) ||
      source ${HOME}/.zsh/zsh.d/00-cache-initialization

    if --hzsh-is-caching; then
      { # Run this in the background
        local -a files
        files=(${HOME}/.z{login,profile,compdump,sh{env,rc{,-local}}})
        files+=($(--hzsh-cache-path)/zcomp-${HOST})
        for f ($files); do
          [[ -f ${f} ]] && zrecompile -qp ${f} && rm -f ${f}.zwc.old
        done
      } &!

      { # Run this in the background
        local dir zwc
        local -i i
        local -a files

        for (( i = 1; i <= ${#fpath}; ++i )); do
          dir=${fpath[i]}
          zwc=${dir:t}.zwc
          [[ ${dir} == (.|..) || ${dir} == (.|..)/* ]] && continue
          files=($dir/*(N-.))
          if [[ -w ${dir:h} && -n ${files} ]]; then
            files=(${${(M)files%/*/*}#/})
            if (cd ${dir:h} && zrecompile -p -U -z ${zwc} ${files} ); then
              fpath[i]=${fpath[i]}.zwc
            fi
          fi
        done
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
