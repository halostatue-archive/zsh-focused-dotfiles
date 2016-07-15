# frozen_string_literal: true

require_relative 'config'

class Hz::Installer < ::Hz
  def self.run(source, target, replace = false)
    new(source, target, replace).run
  end

  # Sets the replace-all mode for file replacement.
  def replace_all(value)
    @replace_all = !!value
  end

  # Returns +true+ if all files are to be replaced.
  def replace_all?
    @replace_all
  end

  def initialize(source, target, replace = false)
    super(source, target)
    replace_all(replace)

    map_file    = source_file('config_map.yml')
    @config_map = YAML.load(map_file.binread) if map_file.exist?
    @config_map = {} unless @config_map.kind_of? ::Hash

    @config_map.keys.dup.each do |file|
      @config_map[source_file(file)] = target_file(@config_map.delete(file))
    end

    Pathname.glob(source_file('z*')).each do |zfile|
      @config_map[zfile] ||= target_file(".#{zfile.relative_path_from(source_path)}")
    end

    config_path.children.each do |config_file|
      @config_map[config_file] ||=
        begin
          target = config_file.basename.to_path
          target = ".#{target}" unless target.start_with?('.')
          target_file(target)
        end
    end

    @ostype        = %x(uname).chomp.downcase

    @prerequisites = {}
    @needs_merge   = {}
  end

  def run
    @config_map.each do |source, target|
      prerequisites(source)
      try_replace_file(source, target)
    end
  end

  private

  def replace_file(source, target)
    remove_file target

    if @prerequisites[source].size > 1 or @needs_merge[source]
      merge_file source, target
    else
      link_file source, target
    end
  end

  def remove_file(target)
    if File.exist? target or File.symlink? target
      if backup_file target
        puts "Removing target #{File.basename(target)}…"
        FileUtils.rm target, :force => true
      end
    end
  end

  def merge_file(source, target)
    @current_file = File.basename(source)

    cli.say <<-SAY
Creating target #{File.basename(target)} from #{@current_file} and local files…
    SAY

    contents = evaluate(source)

    File.open(target, 'w') { |f| f.write contents }
  end

  def include_file(filename_pattern)
    expand_filename_pattern(filename_pattern).map { |f|
      evaluate(f)
    }.join
  end
  alias_method :include_files, :include_file

  def include_platform_files
    include_file platform_files
  end

  def include_user_files
    include_file user_files
  end

  def user_files
    "user_files"
  end

  def platform_files
    "platform_files"
  end

  def link_file(source, target)
    puts "Linking source #{File.basename(source)} as target #{File.basename(target)}…"
    FileUtils.ln_s source, target
  end

  def expand_filename_pattern(filename_pattern, current_file = nil)
    fp = filename_pattern.
      gsub(PLATFORM_FILES_RE, "platform/{PLATFORM}/{FILE}").
      gsub(USER_FILES_RE, "user/**/{FILE}").
      gsub(PLATFORM_RE, @ostype).
      gsub(CURRENT_FILE_RE, File.basename(current_file || @current_file))
    Dir[fp].map { |f|
      f = Pathname.new(f).expand_path
      if f.exist?
        f
      else
        nil
      end
    }.compact.uniq
  end

  PLATFORM_RE       = %r{\{PLATFORM\}}
  CURRENT_FILE_RE   = %r{\{FILE\}}
  USER_DATA_RE      = %r{<%=?.*user_data(?:\[|_lookup).*?%>}m
  PLATFORM_FILES_RE = %r{\bplatform_files\b}
  USER_FILES_RE     = %r{\buser_files\b}
  TEMPLATE_MATCH_RE = %r{<%=?.*?%>}m
  INCLUDE_FILE_RE   = %r{
    <%=?.*?
      (?:
       include_files?
       (?:
        \s+"(.+?)"
        |
        \s+'(.+?)'
        |
        \("(.+?)"\)
        |
        \('(.+?)'\)
        |
        ((?:platform|user)_files)
       )
       |
       include_((?:platform|user)_files)
      )
    .*?%>}mx

  def prerequisites(filename)
    filename = filename.to_s
    unless @prerequisites.key? filename
      @prerequisites[filename] = [ filename ]
      if File.file? filename
        data = IO.binread(filename)

        unless @needs_merge.key? filename
          needs_merge = !!(data =~ TEMPLATE_MATCH_RE)
          @needs_merge[filename] = needs_merge

          if needs_merge
            files = []
            files << user_data_file if data =~ USER_DATA_RE

            included_files =
              data.scan(INCLUDE_FILE_RE).flatten.compact.uniq.map { |ifn|
                expand_filename_pattern(ifn, filename)
            }.flatten.compact.uniq

            included_files.each { |ifn| prerequisites(ifn) }

            files += included_files
            @prerequisites[filename] += files.compact
          end
        end
      end
    end

    @prerequisites[filename]
  end

  def backup_file(target)
    if File.symlink? target
      true
    elsif File.directory? target
      puts "Backing up target directory #{File.basename(target)}…"
      FileUtils.mv target, "#{target}.backup"
    elsif File.file? target
      puts "Backing up target #{File.basename(target)}…"
      FileUtils.cp target, "#{target}.backup"
    else
      raise "Unknown type for #{File.basename(target)}!"
    end
    true
  end

  def evaluate(filename)
    if File.exists? filename
      puts "\t#{relative_path(filename)}…"
      data = File.open(filename) { |f| f.read }
      erb = ERB.new(data, 0, "><>%")
      erb.result(binding)
    else
      puts "\t#{relative_path(filename)} (missing)…"
      ""
    end
  rescue Exception => exception
    $stderr.puts "Could not process '#{filename}': #{exception.message}"
    $stderr.puts exception.backtrace
    ""
  end

  def on(value = nil)
    yield value if value
  end

  def path_exist?(path, pattern = nil)
    path = Pathname(path).expand_path

    return unless path.exist?

    pattern = yield if block_given?
    "#{pattern.to_s.gsub(%r{\{PATH\}}, path.to_s)}\n"
  end
  alias_method :when_path_exist?, :path_exist?

  def in_path?(path, pattern = nil)
    env_path.each do |root|
      next unless root.join(path).exist?
      pattern = yield if block_given?
      return "#{pattern.to_s.gsub(%r{\{PATH\}}, path.to_s)}\n"
    end
    nil
  end
  alias_method :when_in_path?, :in_path?

  def try_replace_file(source, target = source)
    replace = false

    source = Pathname(source).expand_path
    target = Pathname(target).expand_path

    target.dirname.mkpath unless target.dirname == target_path

    if File.exist? target
      if replace_all?
        replace = true
      else
        begin
          case ask_overwrite(target)
          when 'y', 'Y'
            replace = true
          when 'n', 'N'
            cli.say "Skipping target #{expand(target).basename}"
          when 'q', 'Q'
            cli.say 'Stopping.'
            exit
          when 'a', 'A'
            cli.say 'Replacing all files.'
            replace = self.replace_all(true)
          end
        end
      end
    else
      replace = true
    end

    replace_file(source, target) if replace
  end

  def ask_overwrite(target)
    answer = cli.ask("Overwrite target #{relative_path(target)}? [ynaqh] ") { |q|
      q.default = 'n'
      q.validate = %r{[ynaqh]}i
    }
    raise if answer =~ /h/i
    answer
  rescue
    cli.say <<-SAY
y - Yes
n - No (default)
q - Quit
a - Yes to All
h - Help
    SAY
    retry
  end
end
