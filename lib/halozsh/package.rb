# -*- ruby encoding: utf-8 -*-

require 'pathname'

class Halozsh::Package
  include Rake::DSL

  # These methods define the Package interface, for use in a Rakefile or
  # Rake task builder.
  class << self
    include Rake::DSL

    def inherited(subclass)
      known_packages << subclass
    end

    # Returns the known packages
    def known_packages
      @known_packages ||= []
    end

    def installed_packages(installer)
      list = installer.packages_file('installed')
      if list.exist?
        [ list, list.binread.split($/) ]
      else
        [ list, [] ]
      end
    end

    # Supported package methods.
    def package_methods
      @pm ||= %W(install update uninstall).map(&:to_sym).freeze
    end

    # Validates the package name; mostly checks to make sure that the name
    # isn't a reserved name ("all" or "defaults").
    def validate_name!(name)
      case name
      when 'all', 'defaults'
        raise "Invalid name: must not be 'all' or 'defaults'."
      end
    end

    # Defines packaging tasks. This stuff should be defined once and
    # typically done prior to defining any individual package tasks.
    def default_package_tasks(installer, source_path = nil)
      return unless self.eql? Halozsh::Package
      return if @defined

      @defined = true
      source_path ||= installer.source_file('lib')

      packages_file = installer.packages_file.to_path
      directory packages_file

      namespace :package do
        package_methods.each do |m|
          method_ns = namespace(m) {}
          desc "#{m.to_s.capitalize} the named package."
          task m, [ :name ] => packages_file do |t, args|
            method_ns[args.name].invoke
          end

          next unless m == :update
          update_ns = namespace(m) {}

          namespace m do
            desc "#{m.to_s.capitalize} all installed packages."
            task :all do
              _, have = Halozsh::Package.installed_packages(installer)
              update_ns.tasks.map do |pkg|
                name = pkg.name.split(/:/).last
                pkg.invoke if have.include? name
              end
            end
          end
        end

        install_ns = namespace(:install) {}

        desc "Show the known packages and their state."
        task :known do
          _ , have = Halozsh::Package.installed_packages(installer)

          pkgs = install_ns.tasks.map { |pkg|
            name = pkg.name.split(/:/).last

            if name == 'all' or name == 'defaults'
              nil
            elsif have.include? name
              "  * #{name}"
            else
              "    #{name}"
            end
          }.compact!

          puts "Known packages: (* indicates the package is installed)"
          puts pkgs.join("\n")
        end

        task :list => 'package:known'
      end
      task :package => 'package:known'
      task :packages => :package

      Halozsh::Package::Generator.define_generator_tasks(installer)
      define_package_task(installer, *known_packages)

      namespace :package do
        package_methods.each do |m|
          next if m == :update

          method_ns = namespace(m) {}

          if method_ns[:all]
            namespace m do
              text = if m == :update
                       "#{m.to_s.capitalize} all installed packages."
                     else
                       "#{m.to_s.capitalize} all packages."
                     end
              desc text
              task :all
            end
          end

          if method_ns[:defaults]
            namespace m do
              desc "Install default packages."
              task :defaults
            end
          end
        end
      end
    end

    def define_package_task(installer, *packages)
      return unless self.eql? Halozsh::Package

      packages.flatten.each do |package|
        case package
        when Class
          package.define_tasks(installer)
        when String
          known_packages = Halozsh::Package.known_packages.dup

          begin
            require package
          rescue LoadError
            warn "Error loading #{package}"
            next
          end

          new_packages = Halozsh::Package.known_packages - known_packages
          new_packages.each { |pkg| pkg.define_tasks(installer) }
        end
      end
    end

    # Defines package tasks.
    def define_tasks(installer)
      package = new(installer)
      raise ArgumentError, "Package is not named" unless package.name
      raise ArgumentError, "Package can't be installed" unless package.respond_to? :install
      raise ArgumentError, "Package can't be updated" unless package.respond_to? :update

      packages_file = installer.packages_file.to_path
      directory packages_file

      package_task = package.task_name
      namespace :package do
        package_methods.each do |m|
          namespace m do
            depends = [ dependencies, packages_file ].flatten
            task package_task => depends do |t|
              actual_method = "__#{m}__".to_sym
              package.__send__(actual_method, t)
              package.update_plugin(m)
              package.update_package_list(m)
            end

            next if m == :update
            task :all => "package:#{m}:#{package_task}"
          end
        end
      end

      if default_package?
        namespace :package do
          namespace :install do
            task :defaults => "package:install:#{package.name}"
          end
        end
      end
    end
  end

  # These methods define the Package DSL.
  class << self
    def name(package = nil)
      @name = package if package
      @name ||= self.to_s.split(/::/).last.downcase
      Halozsh::Package.validate_name!(@name)
      @name
    end

    def path(path = nil)
      @path = Pathname.new(path.to_s.gsub(/:name/, name)) if path
      @path || name
    end

    def default_package
      @default_package = true
    end

    def default_package?
      @default_package
    end

    def dependency(dep)
      dependencies << dep
    end

    def dependencies(deps = nil)
      @dependencies ||= []
      @dependencies << deps if deps
      @dependencies
    end

    def has_plugin
      @has_plugin = true
    end

    def has_plugin?
      @has_plugin
    end

    def private_package
      @private_package = true
    end

    def private_package?
      @private_package
    end
  end

  def initialize(installer)
    @installer = installer
    @descriptions = { }

    path = Pathname.new(self.path)

    @target = if path.absolute?
                path
              else
                installer.packages_file(path)
              end
  end

  # The installer instance used.
  attr_reader :installer
  # The target path for installation.
  attr_reader :target

  def name
    self.class.name
  end

  def path
    self.class.path
  end

  def task_name
    name.to_sym
  end

  def has_plugin?
    self.class.has_plugin?
  end

  def update_package_list(action)
    list, data = Halozsh::Package.installed_packages(installer)

    case action.to_s
    when "install"
      data << name
    when "uninstall"
      data.delete_if { |item| name == item }
    end
    data.uniq!

    File.open(list, 'wb') { |f| f.puts data.sort.join("\n") }
  end

  def zsh_source_file(header, body)
    <<-EOS
##{header}

#{body}
    EOS
  end

  def zsh_autoload(body)
    zsh_source_file("autoload -U", body)
  end

  def zsh_source(body)
    zsh_source_file("! zsh", body)
  end

  def zsh_compdef(rules, body)
    zsh_source_file("compdef #{rules}", body)
  end

  def create_plugin_files(plugin_file_path, plugin_files)
    return unless plugin_files
    plugin_file_path.mkpath
    plugin_files.each do |name, body|
      File.open(plugin_file_path.join(name.to_s), 'wb') { |f| f.puts(body) }
    end
  end

  def plugin_init
    return nil unless respond_to? :plugin_init_file
    {
      :init => zsh_source(plugin_init_file)
    }
  end

  def update_plugin(action)
    plugin_path = installer.packages_file('.plugins', name)

    case action.to_s
    when "install", "update"
      return unless has_plugin?
      plugin_path.mkpath

      if respond_to? :plugin_completion
        create_plugin_files(plugin_path.join('completion'), plugin_completion)
      end

      if respond_to? :plugin_functions
        create_plugin_files(plugin_path.join('functions'), plugin_functions)
      end

      create_plugin_files(plugin_path.join('init'), plugin_init)

      action = if action == :install
                 "Installed"
               else
                 "Updated"
               end
      puts "#{action} hzsh plugin for #{name}."
    when "uninstall"
      if plugin_path.exist?
        plugin_path.rmtree
        puts "Removed hzsh plugin for #{name}."
      end
    end
  end

  def installed?
    target.directory?
  end

  def fail_if_installed
    raise "Package #{name} already installed in #{target}." if installed?
  end

  def fail_unless_installed
    raise "Package #{name} is not installed in #{target}." unless installed?
  end

  def update_config_file(name)
    task = Rake::Task["file:#{name}"]
    file = Rake::Task[task.prerequisites.first].prerequisites.first

    raise "Task file:#{name} does not exist." unless task

    touch file
    task.invoke
  end

  def __install__(task)
    pre_install_validate(task) if respond_to?(:pre_install_validate, true)
    pre_install(task) if respond_to?(:pre_install, true)
    install(task)
    post_install(task) if respond_to?(:post_install, true)
    post_install_validate(task) if respond_to?(:post_install_validate, true)
    puts "Installed package #{name}."
  end

  def __update__(task)
    pre_update_validate(task) if respond_to?(:pre_update_validate, true)
    pre_update(task) if respond_to?(:pre_update, true)
    update(task)
    post_update(task) if respond_to?(:post_update, true)
    post_update_validate(task) if respond_to?(:post_update_validate, true)
    puts "Updated package #{name}."
  end

  def __uninstall__(task)
    fail_unless_installed
    pre_uninstall_validate(task) if respond_to?(:pre_uninstall_validate, true)
    pre_uninstall(task) if respond_to?(:pre_uninstall, true)
    uninstall(task) if respond_to?(:uninstall, true)
    target.rmtree if target.directory?
    post_uninstall(task) if respond_to?(:post_uninstall, true)
    puts "Removed package #{name}."
  end
end

require 'halozsh/package/generator'
require 'halozsh/package/type'
require 'halozsh/package/definition'
