# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::Lunchy < Halozsh::Package
  include Halozsh::Package::Type::Git

  url "git://github.com/mperham/lunchy.git"
  has_plugin

  def plugin_init_file
    %Q(add-paths-before-if "#{target.join('bin')}")
  end
end
