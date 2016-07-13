# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::RubyInstall < Halozsh::Package
  include Halozsh::Package::Type::Git

  url "https://github.com/postmodern/ruby-install.git"
  path ':name/src'
  has_plugin

  def remove_paths(task)
    target.parent.expand_path.rmtree
  end
  private :remove_paths

  alias_method :post_uninstall, :remove_paths

  def install_with_makefile(task)
    Dir.chdir(target) do
      sh %Q(make install PREFIX=#{target.parent.expand_path})
    end
  end
  private :install_with_makefile

  alias_method :post_install, :install_with_makefile
  alias_method :post_update, :install_with_makefile

  def plugin_init_file
    <<-EOS
add-paths-before-if "#{target.parent.join('bin')}"
unique-manpath -b "#{target.parent.join('share/man')}"
    EOS
  end
end
