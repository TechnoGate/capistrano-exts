module Capistrano
  module Extensions
    module Version #:nodoc:
      MAJOR = 1
      MINOR = 0
      TINY = 0

      STRING = [MAJOR, MINOR, TINY].join(".")
    end
  end
end
