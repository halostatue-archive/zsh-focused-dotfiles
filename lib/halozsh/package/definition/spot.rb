# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::Spot < Halozsh::Package
  include Halozsh::Package::Type::Git

  url "git://github.com/guille/spot.git"
  path ':name/src'
  has_plugin

  def make_paths(task)
    %W(bin share/man/man1).each do |stem|
      target.parent.join(stem).expand_path.mkpath
    end
  end
  private :make_paths

  alias_method :pre_install, :make_paths
  alias_method :pre_update, :make_paths

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
