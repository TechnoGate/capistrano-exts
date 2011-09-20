module Capistrano
  module Extensions
    module Version #:nodoc:
      MAJOR = 1
      MINOR = 11
      TINY = 2

      ARRAY  = [MAJOR, MINOR, TINY]
      STRING = ARRAY.join(".")
    end
  end
end