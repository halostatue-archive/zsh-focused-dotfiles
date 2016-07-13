# -*- ruby encoding: utf-8 -*-

class Halozsh::Package::Powerline < Halozsh::Package
  include Halozsh::Package::Type::Git
  url "https://github.com/milkbikis/powerline-shell"
  has_plugin

  def plugin_functions
    {
      :prompt_powerline_setup  => zsh_autoload(prompt_powerline_setup),
    }
  end

  def prompt_powerline_setup
    <<-EOS
setopt prompt_subst

PROMPT="\$(#{target.join('powerline-bash.py')} ${?} --shell zsh)"
RPROMPT=
    EOS
  end
end
