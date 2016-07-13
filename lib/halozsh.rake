# -*- ruby encoding: utf-8 -*-

require 'pathname'
require 'open-uri'
require 'tempfile'

SOURCE = Pathname.new(__FILE__).dirname.dirname
$:.unshift SOURCE.join('lib')

require 'halozsh'

Halozsh.install_tasks(source: SOURCE, target: ENV['HOME'])

task 'debug:env' do
  require 'pp'
  pp ENV
end

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

namespace :homebrew do
  desc "Install or update the default homebrew formulas."
  task :default => [ 'homebrew:install', "default/brew" ] do |t|
    kegs  = %x(brew list).split($/)
    taps  = %x(brew tap).split($/)
    casks = %x(brew cask list).split($/)
    files = t.prerequisites.grep(%r{/})
    lines = files.map { |req| IO.readlines(req) }.flatten

    sh %Q(brew update)

    lines.each { |line|
      line = line.chomp.gsub(/#.*$/, '').strip

      next if line.empty?

      command, part, _ = line.split(/\s+/, 3)

      case command
      when "tap"
        if taps.include? part
          puts "Skipping tap #{part}…"
          next
        end
      when "install"
        if kegs.include? part
          puts "Skipping keg #{part}…"
          next
        end
      when "cask"
        if casks.include? part
          puts "Skipping cask #{part}…"
          next
        end
        line = [ command, 'install', part, _ ].join(' ')
      end

      sh %Q(brew #{line})
    }
  end

  desc "Install homebrew, if required. Defaults to ~/.brew."
  task :install, :target do |t, args|
    brew = %x(command -v brew).chomp
    installed = false

    if brew.empty?
      brew = if File.executable?(File.expand_path("~/.brew/bin/brew"))
               File.expand_path("~/.brew")
             elsif File.executable?("/usr/local/bin/brew")
               "/usr/local"
             else
               ""
             end
    end

    if brew.empty?
      brew = if args.target.nil? or args.target.empty?
               File.expand_path("~/.brew")
             else
               File.expand_path(args.target)
             end

      open('https://raw.githubusercontent.com/Homebrew/install/master/install') do |r|
        Tempfile.open('homebrew') do |w|
          data = r.read.gsub(%r{HOMEBREW_PREFIX\s*=\s*'.*?'}) {
            "HOMEBREW_PREFIX = '#{brew}'"
          }
          w.write data
          w.close

          puts "Installing homebrew to '#{brew}'."
          ruby w.path
          installed = true
        end
      end
    else
      puts "Homebrew is already installed in #{brew}."
    end

    if ENV['PATH'].scan(/brew/).empty?
      ENV['PATH'] = "#{brew}/bin:#{ENV['PATH']}"
      sh %Q(brew doctor) if installed
    end
  end
end

namespace :vendor do
  desc "Add a new vendored repository."
  task :add, [ :url, :name ] do |t, args|
    url  = args.url or raise "Need a repo URL"
    name = Pathname.new(args.name || args.url).basename('.git')
    path = Pathname.new('vendor').join(name)

    raise "Vendor path #{path} already exists." if SOURCE.join(path).exist?

    # Make vendor:add[url] act more like 'hub' and assume github.com if an
    # incomplete URL has been provided and the format is name/repo.
    url = "git://github.com/#{url}" if url =~ %r{[-\w]+/[-\w]+}

    Dir.chdir(SOURCE.expand_path) do
      sh %Q(git submodule add #{url} #{path})
      sh %Q(git submodule update --init --recursive #{path})
      sh %Q(git commit .gitmodules #{path} -m "Adding submodule #{url} as #{path}")
    end
  end

  desc "Update or initialize the vendored files."
  task :update do
    Dir.chdir(SOURCE.expand_path) do
      submodules = %x(git submodule status)

      if submodules.scan(/^(.)/).flatten.any? { |e| e == "-" }
        sh %Q(git submodule update --init --recursive)
      end

      sh %Q(git submodule foreach 'git fetch -mp && git checkout $(git branch -a | grep remotes/origin/HEAD | sed "s/ *remotes.origin.HEAD -> origin.//") && git pull')
    end
  end

  desc "Reset the vendored files to the desired state."
  task :reset do
    Dir.chdir(SOURCE.expand_path) do
      sh %Q(git submodule update --init --recursive)
    end
  end
end

task :backup do
  sh %Q(tar cfz user-backup.tar.gz user)
end

# vim: syntax=ruby
