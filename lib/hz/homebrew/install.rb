#! /System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby

require 'open-uri'

brewpath = ARGV[0]

open('https://raw.githubusercontent.com/Homebrew/install/master/install') do |r|
  Tempfile.open('homebrew') do |w|
    w.write r.read.gsub(%r{/usr/local}) { "#{brewpath}" }
    w.chmod 0755
    w.close
    system w.path
  end
end
