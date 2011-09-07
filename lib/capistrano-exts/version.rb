module Capistrano
  module Extensions
    module Version #:nodoc:
      MAJOR = 1
      MINOR = 6
      TINY = 0

      ARRAY  = [MAJOR, MINOR, TINY]
      STRING = ARRAY.join(".")
    end
  end
end
