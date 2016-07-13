# -*- ruby encoding: utf-8 -*-

require 'pathname'

module Halozsh::Package::Type; end

file = Pathname.new(__FILE__)
path = file.dirname.join(file.basename(file.extname))
path.children(false).map { |child|
  next unless child.extname == '.rb'
  require path.join(child.basename(child.extname)).to_path
}
