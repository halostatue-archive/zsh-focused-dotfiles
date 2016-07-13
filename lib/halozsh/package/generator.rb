# -*- ruby encoding: utf-8 -*-

require 'erb'

class Halozsh::Package::Generator
  include Rake::DSL

  class << self
    include Rake::DSL

    def inherited(subclass)
      known_generators << subclass
    end

    def known_generators
      @known_generators ||= []
    end

    def define_generator_tasks(installer)
      namespace :package do
        task_names = []
        generate = namespace :generate do
          known_generators.each do |subclass|
            generator = subclass.new(installer)
            task_names << generator.task_name

            task generator.task_name, [ :name, :url ] do |t, args|
              generator.create(t, args)
            end
          end
        end


        desc "Show package generator."
        task :generators do
          puts task_names.map { |gen|
              "%-20s     package:generate:%s" % [ gen, gen ]
          }.join("\n")
        end

        desc "Generate a package for 'type'."
        task :generate, [ :type, :name, :url ] do |t, args|
          generate[args.type].invoke(*args.values_at(:name, :url))
        end
      end
    end
  end

  class << self
    def name(package = nil)
      @name = package if package
      @name ||= self.to_s.split(/::/)[-2].downcase
      @name &&= @name.downcase
      Halozsh::Package.validate_name!(@name)
      @name
    end
  end

  def initialize(installer)
    @installer = installer
  end

  attr_reader :installer

  def name
    self.class.name
  end

  def class_path
    self.class.to_s.split(/::/)[0..-2].join('::')
  end

  def task_name
    name.to_sym
  end

  def path(*args)
    installer.source_file(*%W(lib halozsh package definition)).join(*args)
  end

  def create(t, args)
    raise "Expected a package name." if args.name.nil?
    source_file = path("#{args.name.downcase}.rb")

    raise "Package #{args.name} already exists." if source_file.exist?

    klass_name = args.name.capitalize
    url = args.url || ENV['url'] || '<url>'

    result = template
    while result =~ %r{\<%\=}
      tmpl = ERB.new(result, 0, '%<>')
      result = tmpl.result(binding)
    end

    File.open(source_file, "w") { |f| f.write(result) }
  end

  def template
    <<-EOS
# -*- ruby encoding: utf-8 -*-

class Halozsh::Package::<%= klass_name %> < Halozsh::Package
  include <%= class_path %>
<%= template_body %>
end
    EOS
  end
end
