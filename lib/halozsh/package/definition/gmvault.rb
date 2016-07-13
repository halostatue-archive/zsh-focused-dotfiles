# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::GMVault < Halozsh::Package
  include Halozsh::Package::Type::VirtualEnv

  has_plugin

  def plugin_functions
    {
      :gmvault => zsh_autoload(gmvault_function)
    }
  end

  def gmvault_function
    %Q<(cd #{target.join('bin')} && ./gmvault "${@}")>
  end
end
