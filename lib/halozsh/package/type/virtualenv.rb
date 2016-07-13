# -*- ruby encoding: utf-8 -*-


module Halozsh::Package::Type::VirtualEnv
  def pip_name
    name
  end
  private :pip_name

  def pip_install_upgrade(name)
    Dir.chdir(target.join('bin')) do
      sh %Q(./pip install --upgrade #{name})
    end
  end
  private :pip_install_upgrade

  def install_virtualenv
    unless installed? and target.join('bin/pip').exist?
      _ = %x(which -s virtualenv)
      if $?.to_i.nonzero?
        require 'highline/import'

        say "Python virtualenv is not installed or not in your path."
        choose do |menu|
          menu.prompt = "Select one: "
          menu.choice("Install with 'pip install virtualenv'") {
            say "Installing virtualenv with pip."
            sh %q(pip install virtualenv)
          }
          menu.choice("Install with 'easy_install virtualenv'") {
            say "Installing virtualenv with easy_install."
            sh %q(easy_install virtualenv)
          }
          menu.choice("Install with 'sudo pip install virtualenv'") {
            say "Installing virtualenv with pip (using sudo)."
            sh %Q(sudo pip install virtualenv)
          }
          menu.choice("Install with 'sudo easy_install virtualenv'") {
            say "Installing virtualenv with easy_install (using sudo)."
            sh %Q(sudo easy_install virtualenv)
          }
          menu.choice("Cancel") {
            say "Cancelling install of gmvault."
            return
          }
        end
      end

      sh %Q(virtualenv --no-site-packages #{target})
    end
  end
  private :install_virtualenv

  def pre_install(task)
    install_virtualenv
  end
  alias_method :pre_update, :pre_install

  def install(task)
    pip_install_upgrade(pip_name)
  end
  alias_method :update, :install

  class Generator < Halozsh::Package::Generator
    def template_body
    end
  end
end
