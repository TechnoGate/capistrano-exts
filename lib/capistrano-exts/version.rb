module Capistrano
  module Extensions
    module Version #:nodoc:
      MAJOR = 1
      MINOR = 4
      TINY = 0

      ARRAY  = [MAJOR, MINOR, TINY]
      STRING = ARRAY.join(".")
    end
  end
end
