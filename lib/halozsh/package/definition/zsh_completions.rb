# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::ZshCompletions < Halozsh::Package
  include Halozsh::Package::Type::Git

  default_package
  url "git://github.com/zsh-users/zsh-completions.git"
  has_plugin

  def plugin_init_file
    <<-EOS
# Put zshcompletions first
fpath=("#{target.join('src')}" ${fpath})
    EOS
  end
end
