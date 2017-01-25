# -*- ruby encoding: utf-8 -*-

require 'pathname'
require 'open-uri'
require 'tempfile'

SOURCE = Pathname.new(__FILE__).dirname.dirname
$:.unshift SOURCE.join('lib')

require 'halozsh'

namespace :gem do
  desc "Install the default gems for the environment."
  task :default => [ "default/gems" ] do |t|
    gems = t.prerequisites.map { |req| IO.readlines(req) }.flatten
    gems.each { |e|
      e.chomp!

      next if e.empty?
      next if e =~ /^\s*#/

      n, v = e.split(/\s+/, 2)

      if v and %x(gem list -v "#{v}" -i #{n}).chomp == 'false'
        sh %Q(gem install -v "#{v}" #{n})
      elsif v.nil?
        sh %Q(gem install #{n})
      end
    }
  end
end

# vim: syntax=ruby
