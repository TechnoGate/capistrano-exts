# encoding: utf-8

require 'capistrano-exts/servers/utils/erb'
require 'capistrano-exts/servers/utils/variables'

module Capistrano
  module Extensions
    module Server
      class WebServer

        include Erb
        include Variables

        protected
          def authentification?
            @authentification_file.present?
          end

          def reverse_proxy?
            @mode == :reverse_proxy
          end

          def mod_rewrite?
            (
              @mod_rewrite.present? and
              @mod_rewrite == true
            ) or
            (
              @mod_rewrite.blank?
            )
          end

          def php_fpm?
            @mode == :php_fpm
          end

          def passenger?
            @mode == :passenger
          end

          def php_build_with_force_cgi_redirect?
            # required if PHP was built with --enable-force-cgi-redirect
            @php_build_with_force_cgi_redirect.present? && @php_build_with_force_cgi_redirect == true
          end

          def sanity_check
            [:application_url, :application].each do |var|
              unless instance_variable_get("@#{var.to_s}")
                raise ArgumentError, "#{var.to_s} is required, please define it."
              end
            end

            if php_fpm?
              [:php_fpm_host, :php_fpm_port].each do |var|
                unless instance_variable_get("@#{var.to_s}")
                  raise ArgumentError, "#{var.to_s} is required, please define it."
                end
              end
            end

            if reverse_proxy?
              if @reverse_proxy_server_address.blank? && @reverse_proxy_server_port.blank? && @reverse_proxy_socket.blank?
                raise ArgumentError, "None of the address, port or socket has been defined."
              end

              if @reverse_proxy_server_address.present? && @reverse_proxy_server_port.blank?
                raise ArgumentError, "reverse_proxy_server_address is defined but reverse_proxy_server_port is not please define it."
              end

              if @reverse_proxy_server_port.present? && @reverse_proxy_server_address.blank?
                raise ArgumentError, "reverse_proxy_server_port is defined but reverse_proxy_server_address is not please define it."
              end

              if @reverse_proxy_server_address.present? && @reverse_proxy_server_port.present? && @reverse_proxy_socket.present?
                raise ArgumentError, "you should not define reverse_proxy_server_address, reverse_proxy_server_port and reverse_proxy_socket."
              end
            end

            if passenger? or php_fpm?
              if @public_path.blank?
                raise ArgumentError, "public_path is required, please define it."
              end
            end

          end

      end
    end
  end
end

# Require all web servers
Dir["#{File.dirname __FILE__}/web_server/*.rb"].each { |f| require f }