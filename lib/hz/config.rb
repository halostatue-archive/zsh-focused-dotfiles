# frozen_string_literal: true

require 'highline'

class Hz::Config
  attr_reader :source_path
  attr_reader :target_path
  attr_reader :cli

  def initialize(source_path, target_path)
    @source_path   = expand(source_path)
    @target_path   = expand(target_path)
    @cli           = HighLine.new
  end

  # Expand the path as a Pathname
  def expand(path)
    Pathname(path).expand_path
  end

  # Returns the PATH directories.
  def env_path
    @env_path ||= ENV['PATH'].split(/:/).map { |root| expand(root) }
  end

  # Returns a complete path to a source file prepended with source_path
  def source_file(*args)
    @source_path.join(*args)
  end

  # Returns a complete path to a target file prepended with target_file
  def target_file(*args)
    @target_path.join(*args)
  end

  # Return a file relative to $HOME
  def home(*args)
    @home ||= Pathname(ENV['HOME']).expand_path
    @home.join(*args)
  end

  # Returns a complete path to the packages directory.
  def packages_file(*args)
    @packages_file ||= source_file('packages')
    @packages_file.join(*args)
  end

  # Returns a complete path to a config file.
  def config_path(*args)
    @config_path ||= source_file('config')
    @config_path.join(*args)
  end

  # Returns a complete path to a user file.
  def user_file(*args)
    @user_file ||= source_file('user')
    @user_file.join(*args)
  end

  # Returns the complete path to the user data file.
  def user_data_file
    @user_data_file ||= user_file('data.yml')
  end

  def user_data
    @user_data ||= read_user_data
  end

  def relative_path(path)
    base = Pathname('~')
    path = Pathname(path)
    path = path.relative_path_from(base.expand_path)
    base.join(path)
  end

  def user_data_lookup(key_path)
    dig_user_data(*key_path.split(/\./))
  end

  def read_user_data
    YAML.load_file(user_data_file)
  rescue
    {}
  end

  def user_data_set(key_path, value)
    *deep, last = key_path.split(/\./)

    if deep.empty?
      user_data[last] = value
    else
      dig_user_data(*deep)[last] = value
    end
  end

  def dig_user_data(key, *rest, data: user_data)
    value = data[key]
    if value.nil? || rest.empty?
      value
    else
      dig_user_data(*rest, data: value)
    end
  end
end
