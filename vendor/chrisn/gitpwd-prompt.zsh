# gitpwd - print %~, limited to $NDIR segments, with inline git branch
NDIRS=2
gitpwd() {
  local -a segs splitprefix; local prefix gitbranch
  segs=("${(Oas:/:)${(D)PWD}}")

  if gitprefix=$(git rev-parse --show-prefix 2>/dev/null); then
    splitprefix=("${(s:/:)gitprefix}")
    branch=$(git name-rev --name-only HEAD 2>/dev/null)
    if (( $#splitprefix > NDIRS )); then
      print -n "${segs[$#splitprefix]}@$branch "
    else
      segs[$#splitprefix]+=@$branch
    fi
  fi

  print "${(j:/:)${(@Oa)segs[1,NDIRS]}}"
}

function cnprompt6 {
  case "$TERM" in
    xterm*|rxvt*)
      precmd() {  print -Pn "\e]0;%m: %~\a" }
      preexec() { printf "\e]0;$HOST: %s\a" $1 };;
  esac
  setopt PROMPT_SUBST
  PS1='%B%m%(?.. %??)%(1j. %j&.)%b $(gitpwd)%B%(!.%F{red}.%F{yellow})%#${SSH_CLIENT:+%#} %b'
  RPROMPT=''
}

cnprompt6
