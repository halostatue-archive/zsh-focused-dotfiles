# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'erb'
require 'forwardable'

def optional_dependency(path)
  require path
rescue LoadError
  nil
end

optional_dependency 'psych'
require 'yaml'

optional_dependency 'byebug' if ENV['HZ_OPTION_DEBUG'] == 'true'

class Hz
  def self.run(*args)
    new(*args).run
  end

  def initialize(source_path, target_path)
    @config = Hz::Config.new(source_path, target_path)
  end

  def method_missing(sym, *args, &block)
    return @config.send(sym, *args, &block) if @config.respond_to?(sym)
    super
  end

  def respond_to_missing?(sym, include_private)
    @config.respond_to?(sym, include_private)
  end
end

require 'hz/backport'
require 'hz/installer'
require 'hz/user_data'
