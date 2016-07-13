# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::WillGit < Halozsh::Package
  include Halozsh::Package::Type::Git

  default_package
  url "git://gitorious.org/willgit/mainline.git"
  has_plugin

  def plugin_init_file
    <<-EOS
add-paths-before-if "#{target.join('bin')}"
    EOS
  end
end
