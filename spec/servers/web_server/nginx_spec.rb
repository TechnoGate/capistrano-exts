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

    before(:each) do
      subject.application_url = 'example.com www.example.com'
      subject.application = 'example'
      subject.php_fpm_host = 'localhost'
      subject.php_fpm_port = 60313
      subject.public_path = '/path/to/application'
      subject.indexes = 'index.php'
    end

    it "should render 'public_path'" do |variable|
      subject.public_path = '/path/to/application'
      subject.render.should =~ %r{/path/to/application}
    end

    it "should render 'authentification_file'" do
      subject.authentification_file = '/path/to/authentification_file'
      subject.render.should =~%r{/path/to/authentification_file}
    end

    it "should render 'logs_path'" do
      subject.logs_path = '/path/to/logs'
      subject.render.should =~ %r{access_log /path/to/logs}
      subject.render.should =~ %r{error_log /path/to/logs}
    end

    it "should have logs_path optional" do
      subject.render.should_not =~ %r{access_log.+/access.log;}
      subject.render.should_not =~ %r{error_log.+/error.log;}
    end

    it "should render 'nginx_listen_port'" do
      subject.nginx_listen_port = 8080
      subject.render.should =~ /listen 8080;/
    end

    it "should default the 'nginx_listen_port' to 80" do
      subject.render.should =~ /listen 80;/
    end

    it "should render 'application_url'" do
      subject.application_url = 'technogate.fr www.technogate.fr'
      subject.render.should =~ %r{technogate.fr www.technogate.fr}
    end

    it "should require an 'application_url'" do
      subject.application_url = nil
      lambda {
        subject.render
      }.should raise_error(ArgumentError, "application_url is required, please define it.")
    end

    it "should render 'indexes'" do
      subject.indexes = 'index.php index.html'
      subject.render.should =~ %r{index index.php index.html;}
    end

    it "should have 'indexes' optional" do
      subject.indexes = nil
      subject.render.should_not =~ %r{ index .+;}
    end

    it "should render 'mod_rewrite_simulation'" do
      subject.mod_rewrite_simulation = true
      subject.render.should =~ %r{rewrite.+index.php.+last;}
    end

    it "should render 'php_fpm_host'"

    it "should render 'php_fpm_port'"

  end

  describe "rendering :rails_passenger" do
    it "should render 'application'"

    it "should have passenger enabled"
  end

  describe "rendering :rails_reverse_proxy" do
    it "should render 'reverse_proxy_server_address'"

    it "should render 'reverse_proxy_server_port'"

    it "should render 'reverse_proxy_socket'"
  end
end