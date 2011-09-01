require 'spec_helper'

describe Nginx do

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

  describe "requirement" do
    describe ":php_fpm" do
      subject { Nginx.new :php_fpm }

      before(:each) do
        subject.application_url = 'example.com www.example.com'
        subject.application = 'example'
        subject.php_fpm_host = 'localhost'
        subject.php_fpm_port = 60313
        subject.public_path = '/path/to/application'
        subject.indexes = 'index.php'
      end

      it "should require an 'application_url'" do
        subject.application_url = nil
        lambda {
          subject.render
        }.should raise_error(ArgumentError, "application_url is required, please define it.")
      end

      it "should require an 'public_path'" do
        subject.public_path = nil
        lambda {
          subject.render
        }.should raise_error(ArgumentError, "public_path is required, please define it.")
      end

      it "should require both 'php_fpm_host'" do
        subject.php_fpm_host = nil
        lambda {
          subject.render
        }.should raise_error(ArgumentError, "php_fpm_host is required, please define it.")
      end

      it "should require both 'php_fpm_port'" do
        subject.php_fpm_port = nil
        lambda {
          subject.render
        }.should raise_error(ArgumentError, "php_fpm_port is required, please define it.")
      end
    end

    describe ":rails_passenger" do
      subject { Nginx.new :rails_passenger }

      it "should require 'public_path'"

      it "should have passenger enabled"
    end

    describe ":rails_reverse_proxy" do
      subject { Nginx.new :rails_reverse_proxy }

      it "should require 'reverse_proxy_server_address'"

      it "should require 'reverse_proxy_server_port'"

      it "should require 'reverse_proxy_socket'"

      it "should have reverse_proxy enabled"
    end
  end

  describe "rendering" do
    describe ":php_fpm" do
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
        subject.render.should =~ %r{root\s+/path/to/application;}
      end

      it "should render 'authentification_file'" do
        subject.authentification_file = '/path/to/authentification_file'
        subject.render.should =~%r{auth_basic_user_file\s+/path/to/authentification_file;}
      end

      it "should render 'logs_path'" do
        subject.logs_path = '/path/to/logs'
        subject.render.should =~ %r{access_log\s+/path/to/logs/access.log;}
        subject.render.should =~ %r{error_log\s+/path/to/logs/error.log;}
      end

      it "should have 'logs_path' optional" do
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
        subject.render.should =~ %r{server_name\s+technogate.fr www.technogate.fr;}
      end

      it "should render 'indexes'" do
        subject.indexes = 'index.php index.html'
        subject.render.should =~ %r{index\s+index.php index.html;}
      end

      it "should have 'indexes' optional" do
        subject.indexes = nil
        subject.render.should_not =~ %r{\s+index .+;}
      end

      it "should render 'mod_rewrite_simulation'" do
        subject.mod_rewrite_simulation = true
        subject.render.should =~ %r{rewrite.+index.php.+last;}
      end

      it "should have 'mod_rewrite_simulation' on by default" do
        subject.render.should =~ %r{rewrite.+index.php.+last;}
      end

      it "should render 'php_fpm_host'" do
        subject.php_fpm_host = 'localhost'
        subject.render.should =~ %r{\s+fastcgi_pass\s+localhost:.+$}
      end

      it "should render 'php_fpm_port'" do
        subject.php_fpm_host = 'localhost'
        subject.php_fpm_port = 5454
        subject.render.should =~ %r{\s+fastcgi_pass\s+localhost:5454.+$}
      end
    end

    describe ":rails_passenger" do
      subject { Nginx.new :rails_passenger }

      it "should render 'application'"

      it "should have passenger enabled"
    end

    describe ":rails_reverse_proxy" do
      subject { Nginx.new :rails_reverse_proxy }

      it "should render 'reverse_proxy_server_address'"

      it "should render 'reverse_proxy_server_port'"

      it "should render 'reverse_proxy_socket'"
    end
  end
end