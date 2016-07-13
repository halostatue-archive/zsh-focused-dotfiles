# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::HTTPie < Halozsh::Package
  include Halozsh::Package::Type::VirtualEnv

  def pip_name
    "https://github.com/jkbr/httpie/tarball/master"
  end

  has_plugin

  def plugin_functions
    {
      :http => zsh_autoload(http_function),
    }
  end

  def http_function
    %Q<(cd #{target.join('bin')} && ./http "${@}")>
  end
end
