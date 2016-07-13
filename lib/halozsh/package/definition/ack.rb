# -*- ruby encoding: utf-8 -*-

require 'open-uri'

class Halozsh::Package::Definition::Ack < Halozsh::Package
  default_package
  has_plugin

  def install(task)
    target.mkpath

    temp = target.join('ack-new')
    file = target.join('ack')

    temp.delete if temp.exist?
    open("http://betterthangrep.com/ack-standalone") { |r|
      File.open(temp.to_path, 'w') { |w| w.write r.read }
    }

    type = %x(file "#{temp.to_path}")

    if type =~ /a perl script text executable/
      file.delete if file.exist?
      temp.rename(temp.dirname.join(file.basename))
      file.chmod(0755)
    else
      warn "ack could not be installed (type: #{type})"
    end
  end
  alias_method :update, :install

  def plugin_functions
    {
      :acke => zsh_autoload(acke),
      :ackg => zsh_autoload(ackg)
    }
  end

  def acke
    %Q("${EDITOR}" $(ack -l "${@}"))
  end

  def ackg
    %Q(EDITOR=gvim acke "${@}")
  end

  def plugin_init_file
    %Q(add-paths-before-if "#{target}")
  end
end
