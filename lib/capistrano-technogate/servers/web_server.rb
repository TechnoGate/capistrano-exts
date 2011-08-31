# encoding: utf-8

require 'capistrano-technogate/servers/utils/erb'
require 'capistrano-technogate/servers/utils/variables'

module Capistrano
  module TechnoGate
    module Server
      class WebServer

        include Erb
        include Variables

        protected
          def authentification?
            @authentification_file.present?
          end

          def reverse_proxy?
            @mode == :rails_reverse_proxy
          end

          def enable_mod_rewrite_simulation?
            @enable_mod_rewrite_simulation.present? and @enable_mod_rewrite_simulation == true
          end

          def php_fpm?
            @mode == :php_fpm
          end

          def passenger?
            @mode == :rails_passenger
          end
      end
    end
  end
end