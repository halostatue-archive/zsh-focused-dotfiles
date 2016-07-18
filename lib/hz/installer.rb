# frozen_string_literal: true

require_relative 'config'

class Hz::Installer < ::Hz
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
    result = @config_map.map do |source, target|
      prerequisites(source)
      try_replace_file(source, target)
    end.compact

    if result.empty?
      cli.say "No files need to be updated."
    elsif result.size < @config_map.size
      if result.size == 1
        cli.say "Updated one file."
      else
        cli.say "Updated #{result.size} files."
      end
    else
      cli.say "Updated all files."
    end
  end

  private

  def replace_file(source, target)
    remove_file target

    if prerequisites(source).size > 1 or needs_merge?(source, target)
      merge_file source, target
    else
      link_file source, target
    end
  end

  def remove_file(target)
    if target.exist? or target.symlink?
      if backup_file target
        puts "Removing target #{target.basename}…"
        target.unlink if target.exist?
      end
    end
  end

  def merge_file(source, target)
    @current_file = source.basename

    cli.say <<-SAY
Creating target #{target.basename} from #{@current_file} and local files…
    SAY

    target.write evaluate(source)
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
    puts "Linking source #{source.basename} as target #{target.basename}…"
    target.make_symlink(source)
  end

  def expand_filename_pattern(filename_pattern, current_file = nil)
    fp = filename_pattern.to_s.
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
  USER_DATA_RE      = %r{<%=?.*user_data_lookup.*?%>}m
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

  def needs_merge?(source, target)
    return true unless target.exist?
    return true unless @needs_merge[source.to_s]
    mtime = target.mtime
    prerequisites(source).any? { |f| f.mtime > mtime }
  end

  def prerequisites(filename)
    key = filename.to_s
    unless @prerequisites.key?(key)
      pq = @prerequisites[key] = [ filename ]
      if filename.file?
        data = filename.binread

        if !@needs_merge.key?(key) and (@needs_merge[key] = !!(data =~ TEMPLATE_MATCH_RE))
          files = []
          files << user_data_file if data =~ USER_DATA_RE

          included_files =
            data.scan(INCLUDE_FILE_RE).flatten.compact.uniq.map { |ifn|
              expand_filename_pattern(ifn, filename)
          }.flatten.compact.uniq

          included_files.each { |ifn| files += prerequisites(ifn) }
          pq += files.compact
        end
      end
    end

    @prerequisites[key]
  end

  def backup_file(target)
    if target.symlink?
      true
    elsif target.directory?
      puts "Backing up target directory #{target.basename}…"
      target.rename("#{target}.backup")
    elsif target.file?
      puts "Backing up target #{target.basename}…"
      target.rename("#{target}.backup")
    else
      raise "Unknown type for #{target.basename}!"
    end
    true
  end

  def evaluate(filename)
    if filename.exist?
      puts "\t#{relative_path(filename)}…"
      ERB.new(filename.read, 0, "><>%").result(binding)
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
    source = Pathname(source).expand_path
    target = Pathname(target).expand_path

    target.dirname.mkpath unless target.dirname == target_path

    replace =
      if target.exist?
        if replace_all?
          true
        elsif target.symlink? and target.readlink == source
          # Do not try to do anything if the target is an extant link to the
          # source file.
          false
        elsif !needs_merge?(source, target)
          # Do not try to do anything if the target does not need replacing.
          false
        else
          case ask_overwrite(target)
          when 'y', 'Y'
            true
          when 'n', 'N'
            cli.say "Skipping target #{expand(target).basename}"
            false
          when 'q', 'Q'
            cli.say 'Stopping.'
            exit
          when 'a', 'A'
            cli.say 'Replacing all files.'
            self.replace_all(true)
          end
        end
      else
        true
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
