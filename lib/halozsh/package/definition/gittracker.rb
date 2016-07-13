# -*- ruby encoding: utf-8 -*-


class Halozsh::Package::Definition::GitTracker < Halozsh::Package
  include Halozsh::Package::Type::Git

  url "git://github.com/highgroove/git_tracker.git"
end
