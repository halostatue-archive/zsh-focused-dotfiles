# -*- ruby encoding: utf-8 -*-

class Halozsh
  module Common
    include Rake::DSL

    attr_reader :source_path
    attr_reader :target_path

    # Returns the PATH directories.
    def env_path
      @env_path ||= ENV['PATH'].split(/:/).map { |root|
        Pathname(root).expand_path
      }
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
    def config_file(*args)
      @config_file ||= source_file('config')
      @config_file.join(*args)
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

    def user_data_lookup(key_path)
      dig_user_data(*key_path.split(/\./))
    end

    private

    def configure(source_path, target_path)
      @source_path = Pathname(source_path).expand_path
      @target_path = Pathname(target_path).expand_path
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
end
