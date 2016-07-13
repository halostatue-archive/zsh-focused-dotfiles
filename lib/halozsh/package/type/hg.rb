# -*- ruby encoding: utf-8 -*-


module Halozsh::Package::Type::Hg
  def self.included(mod)
    mod.extend(DSL)
  end

  module DSL
    def url(value = nil)
      @url = value if value
      @url or raise "No URL provided for a Hg package type."
    end
  end

  def url
    self.class.url
  end
  private :url

  def is_hg?
    target.join('.hg').directory?
  end

  def clone_or_pull
    if is_hg?
      Dir.chdir(target) { sh %Q(hg pull && hg update) }
    else
      pre_install(task) if respond_to?(:pre_install, true)
      sh %Q(hg clone #{url} #{target})
      post_install(task) if respond_to?(:post_install, true)
    end
  end

  def validate_is_hg(task)
    if installed? and not is_hg?
      raise "#{name} exists in #{target} but is not a hg repo."
    end
  end
  alias_method :pre_install_validate, :validate_is_hg
  alias_method :pre_update_validate, :validate_is_hg

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
