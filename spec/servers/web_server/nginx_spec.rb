require 'spec_helper'

# require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Server::Nginx do
  include Server

  describe "instance" do
    it "should require a mode" do
      lambda {
        Nginx.new
      }.should raise_error(ArgumentError)
    end

    it "should require a valid mode" do
      lambda {
        Nginx.new(:invalid_mode)
      }.should raise_error(ArgumentError)
    end
  end

  describe "rendering :php_fpm" do
    subject { Nginx.new :php_fpm }

    it "should render 'public_path'" do |variable|
      subject.public_path = '/path/to/application'
      subject.render.should =~ %r{/path/to/application}
    end

    it "should render 'authentification_file'"
    it "should render 'logs_path'"

    it "should render 'nginx_listen_port'" do
      subject.nginx_listen_port = 8080
      subject.render.should =~ /listen 8080;/
    end

    it "should render 'application_url'"
    it "should render 'indexes'"
    it "should render 'enable_mod_rewrite_simulation'"
    it "should render 'application'"
    it "should render 'php_fpm'"
    it "should render 'passenger'"
    it "should render 'reverse_proxy_server_address'"
    it "should render 'reverse_proxy_server_port'"
    it "should render 'reverse_proxy_socket'"
    it "should render 'php_fpm_host'"
    it "should render 'php_fpm_port'"


  end
end