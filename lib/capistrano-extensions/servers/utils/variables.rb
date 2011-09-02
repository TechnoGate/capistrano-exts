# encoding: utf-8

require 'erb'

module Capistrano
  module TechnoGate
    module Variables

      # Instead of defining a whole lot of attr_accessor, let's be smart about
      # templates, right ?
      def method_missing(method, *args, &block)
        if method =~ /(.+)=$/
          # Method 1: works but the attr_accessor would be set on all instances
          # Which is not good
          #
          # self.class.__send__(:attr_accessor, $1.to_sym)
          # self.__send__(method, *args, &block)

          # Method 2: Just set the instance variable, works better
          self.send(:instance_variable_set, "@#{$1.to_sym}", *args)
        end
      end
    end
  end
end