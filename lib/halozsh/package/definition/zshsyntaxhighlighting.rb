# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Zshsyntaxhighlighting < Halozsh::Package
  include Halozsh::Package::Type::Git
  url "git://github.com/zsh-users/zsh-syntax-highlighting.git"

  has_plugin

  def plugin_init_file
    <<-EOS
source "#{target.join('zsh-syntax-highlighting.zsh')}"
    EOS
  end
end
