if command -sq pt
  set -gx FZF_CTRL_T_DEFAULT_COMMAND 'pt -g "" --hidden --ignore .git'
  else if command -sq rg
  set -gx FZF_CTRL_T_DEFAULT_COMMAND 'rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2>/dev/null'
  else if command -sq ag
  set -gx FZF_CTRL_T_DEFAULT_COMMAND 'ag -g "" --hidden --ignore .git'
  end

set -l preview
command -sq highlight
and set preview 'highlight -O xterm256 -l {} 2> /dev/null || '
command -sq bat
and set preview $preview'bat --color=always {} || '
set preview '('$preview'cat {} || tree -C {}) | head -200'

set -gx FZF_CTRL_T_OPTS "--preview='$preview' --select-1 --exit-0"

set -l fd
if command -sq brew
  set fd (find $(brew --prefix)/Cellar/fd -name fd -type f)[-1]
end

if test -z $fd; and command -sq cargo
  set -l candidate (dirname (command -sq cargo))/fd
  test -x $candidate
  and set fd $candidate
end

test -z $fd
or set -gx FZF_ALT_C_COMMAND "$fd -L -t d ."

export FZF_ALT_C_OPTS="--preview='tree -C {} | head -200' --header-lines=1 --select-1 --exit-0"
export FZF_CTRL_R_OPTS="--preview='echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

if test -d $HOME/.fzf/man
  path:unique --man --before --test
path:unique --before --test ${HOME}/.fzf/
  unique-manpath -b ${HOME}/.fzf/man

  source ${HOME}/.fzf.zsh

  # bindkey "\C-Op" __vim_fzf
  # bindkey "\C-Ov" __gvim_fzf
}
