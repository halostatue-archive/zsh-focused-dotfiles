# -*- ruby encoding: utf-8 -*-

class Halozsh::Package::Definition::Attach < Halozsh::Package
  include Halozsh::Package::Type::Git

  url "git://github.com/sorin-ionescu/attach.git"
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

  def uninstall(task)
    target.parent.expand_path.rmtree
  end

  def install_with_symlinks(task)
    parent  = target.parent
    bin     = parent.join('bin/attach')
    man     = parent.join('share/man/man1/attach.1')

    installer.fileops.ln_s target.join('attach'), bin unless bin.exist?
    installer.fileops.ln_s target.join('attach.1'), man unless man.exist?
  end
  private :install_with_symlinks

  alias_method :post_install, :install_with_symlinks
  alias_method :post_update, :install_with_symlinks

  def plugin_init_file
    <<-EOS
add-paths-before-if "#{target.parent.join('bin')}"
unique-manpath -b "#{target.parent.join('share/man')}"
    EOS
  end
end
