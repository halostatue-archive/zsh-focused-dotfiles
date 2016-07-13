# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::Highline < Halozsh::Package
  default_package

  include Halozsh::Package::Type::Git

  url "git://github.com/JEG2/highline.git"
  private_package
end
