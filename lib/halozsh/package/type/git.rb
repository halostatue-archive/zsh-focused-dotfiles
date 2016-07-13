# -*- ruby encoding: utf-8 -*-


module Halozsh::Package::Type::Git
  def self.included(mod)
    mod.extend(DSL)
  end

  module DSL
    def url(value = nil)
      @url = value if value
      @url or raise "No URL provided for a Git package type."
    end
  end

  def url
    self.class.url
  end
  private :url

  def is_git?
    target.join('.git').directory?
  end

  def clone_or_pull
    if is_git?
      Dir.chdir(target) { sh %Q(git pull) }
    else
      sh %Q(git clone #{url} #{target})
    end
  end

  def validate_is_git(task)
    if installed? and not is_git?
      raise "#{name} exists in #{target} but is not a git repo."
    end
  end
  alias_method :pre_install_validate, :validate_is_git
  alias_method :pre_update_validate, :validate_is_git

  def install(task)
    clone_or_pull
  end
  alias_method :update, :install

  class Generator < Halozsh::Package::Generator
    def template_body
      <<-EOS
  url "<%= url %>"
      EOS
    end
  end
end
