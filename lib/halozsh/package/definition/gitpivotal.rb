# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::GitPivotal < Halozsh::Package
  include Halozsh::Package::Type::Git

  url "git://github.com/trydionel/git-pivotal.git"
end
