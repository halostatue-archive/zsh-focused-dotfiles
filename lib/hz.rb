# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'erb'
require 'forwardable'

begin
  require 'psych'
rescue LoadError
  nil
end

require 'yaml'

class Hz
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

require 'hz/installer'
