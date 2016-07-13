# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::Pybugz < Halozsh::Package
  include Halozsh::Package::Type::Git

  url "git://github.com/williamh/pybugz.git"

  def plugin_functions
    {
      :bugz => zsh_autoload(pybugz_function)
    }
  end

  def pybugz_function
    %Q<#{target.join('lbugz')} "${@}">
  end
end
