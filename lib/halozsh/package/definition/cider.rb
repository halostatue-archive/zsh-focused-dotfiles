
class Halozsh::Package::Definition::Cider < Halozsh::Package
  include Halozsh::Package::Type::VirtualEnv

# def pip_name
#   "https://github.com/jkbr/httpie/tarball/master"
# end

  has_plugin

  def plugin_functions
    {
      :cider => zsh_autoload(cider_function),
    }
  end

  def cider_function
    %Q<(cd #{target.join('bin')} && ./cider "${@}")>
  end
end
