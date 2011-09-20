module Capistrano
  module Extensions
    module Version #:nodoc:
      MAJOR = 1
      MINOR = 11
      TINY = 1

      ARRAY  = [MAJOR, MINOR, TINY]
      STRING = ARRAY.join(".")
    end
  end
end