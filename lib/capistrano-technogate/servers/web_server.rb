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

          def mod_rewrite_simulation?
            @mod_rewrite_simulation.present? and @mod_rewrite_simulation == true
          end

          def php_fpm?
            @mode == :php_fpm
          end

          def passenger?
            @mode == :rails_passenger
          end

          def sanity_check
            [:application_url, :application].each do |var|
              unless instance_variable_get("@#{var.to_s}")
                raise ArgumentError, "#{var.to_s} is required, please define it."
              end
            end

            if php_fpm?
              [:php_fpm_host, :php_fpm_port, :public_path].each do |var|
                unless instance_variable_get("@#{var.to_s}")
                  raise ArgumentError, "#{var.to_s} is required, please define it."
                end
              end
            end

          end

      end
    end
  end
end