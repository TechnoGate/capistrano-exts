# encoding: utf-8

require 'capistrano-technogate/servers/web_server/common'

module Capistrano
  module TechnoGate
    module Server
      class Nginx < WebServer

        AVAILABLE_MODES = [:rails_passenger, :rails_reverse_proxy, :php_fpm]
        NGINX_TEMPLATE_PATH = ROOT_PATH + '/capistrano-technogate/templates/web_servers/nginx.conf.erb'

        # Setup read/write attribute
        attr_accessor :public_path, :authentification_file, :logs_path,
                      :nginx_listen_port, :application_url, :indexes,
                      :enable_mod_rewrite_simulation, :application,
                      :php_fpm, :passenger, :reverse_proxy_server_address,
                      :reverse_proxy_server_port, :reverse_proxy_socket,
                      :php_fpm_host, :php_fpm_port

        def initialize(mode, template_path = NGINX_TEMPLATE_PATH)
          raise ArgumentError, "The requested mode is not supported" unless AVAILABLE_MODES.include?(mode)
          raise ArgumentError, "The template file is not found or not readable" unless File.exists?(template_path)
          @mode = mode.to_sym
          @template = template_path
        end
      end
    end
  end
end