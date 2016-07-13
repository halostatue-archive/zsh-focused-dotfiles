# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::HgGit < Halozsh::Package
  default_package

  include Halozsh::Package::Type::Git

  url "git://github.com/schacon/hg-git.git"

  def after_action(task)
    update_config_file 'hgrc'
  end
  private :after_action

  alias_method :post_install, :after_action
  alias_method :post_uninstall, :after_action
  alias_method :post_update, :after_action
end
