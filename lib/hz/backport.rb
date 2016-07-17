# frozen_string_literal: true

# :nocov:

unless Pathname.public_method_defined?(:write)
  ##
  module Hz::PathnameWrite #:nodoc:
    def write(*args)
      IO.write(to_s, *args)
    end

    ::Pathname.send(:include, Hz::PathnameWrite)
  end
end
# :nocov:
