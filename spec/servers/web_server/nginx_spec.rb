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
        subject.application_url = %w{example.com www.example.com}
        subject.application = 'example'
        subject.php_fpm_host = 'localhost'
        subject.php_fpm_port = 60313
        subject.public_path = '/path/to/application'
        subject.indexes = %w{index.php}
      end

      it "should have php_fpm enabled" do
        subject.send(:php_fpm?).should be_true
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

    describe ":passenger" do
      subject { Nginx.new :passenger }

      before(:each) do
        subject.application_url = %w{example.com www.example.com}
        subject.application = 'example'
        subject.public_path = '/path/to/application'
      end

      it "should require 'public_path'" do
        subject.public_path = nil
        lambda {
          subject.render
        }.should raise_error(ArgumentError, "public_path is required, please define it.")
      end

      it "should have passenger enabled" do
        subject.send(:passenger?).should be_true
      end
    end

    describe ":reverse_proxy" do
      subject { Nginx.new :reverse_proxy }

      before(:each) do
        subject.application_url = %w{example.com www.example.com}
        subject.application = 'example'
        subject.reverse_proxy_server_address = 'localhost'
        subject.reverse_proxy_server_port = 8080
      end

      it "should have reverse_proxy enabled" do
        subject.send(:reverse_proxy?).should be_true
      end

      it "should require 'reverse_proxy_server_address' and 'reverse_proxy_server_port' or 'reverse_proxy_socket'" do
        subject.reverse_proxy_server_address = nil
        subject.reverse_proxy_server_port = nil
        lambda {
          subject.render
        }.should raise_error(ArgumentError, "None of the address, port or socket has been defined.")
      end

      it "should force defining reverse_proxy_server_port if reverse_proxy_server_address is defined" do
        subject.reverse_proxy_server_address = 'localhost'
        subject.reverse_proxy_server_port = nil

        lambda {
          subject.render
        }.should raise_error(ArgumentError, "reverse_proxy_server_address is defined but reverse_proxy_server_port is not please define it.")
      end

      it "should force defining reverse_proxy_server_address if reverse_proxy_server_port is defined" do
        subject.reverse_proxy_server_address = nil
        subject.reverse_proxy_server_port = 8080
        lambda {
          subject.render
        }.should raise_error(ArgumentError, "reverse_proxy_server_port is defined but reverse_proxy_server_address is not please define it.")
      end

      it "shouldn't allow defining both reverse_proxy_server_address and reverse_proxy_socket or reverse_proxy_server_port and reverse_proxy_socket" do
        subject.reverse_proxy_socket = '/tmp/socket'
        lambda {
          subject.render
        }.should raise_error(ArgumentError, "you should not define reverse_proxy_server_address, reverse_proxy_server_port and reverse_proxy_socket.")
      end
    end
  end

  describe "rendering" do
    describe ":php_fpm" do
      subject { Nginx.new :php_fpm }

      before(:each) do
        subject.application_url = %w{example.com www.example.com}
        subject.application = 'example'
        subject.php_fpm_host = 'localhost'
        subject.php_fpm_port = 60313
        subject.public_path = '/path/to/application'
        subject.indexes = %w{index.php}
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

      it "should render 'listen_port'" do
        subject.listen_port = 8080
        subject.render.should =~ /listen 8080;/
      end

      it "should default the 'listen_port' to 80" do
        subject.render.should =~ /listen 80;/
      end

      it "should render 'application_url'" do
        subject.application_url = %w{technogate.fr www.technogate.fr}
        subject.render.should =~ %r{server_name\s+technogate.fr www.technogate.fr;}
      end

      it "should render 'indexes'" do
        subject.indexes = %w{index.php index.html}
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

      it "should render 'denied_access'" do
        subject.denied_access = ["/system/logs", "/tl_file/.htaccess"]
        subject.render.should =~ /location ~ \/system\/logs {.*deny\s+all;.*}/m
        subject.render.should =~ /location ~ \/tl_file\/\\.htaccess {.*deny\s+all;.*}/m
      end
    end

    describe ":passenger" do
      subject { Nginx.new :passenger }

      before(:each) do
        subject.application_url = %w{example.com www.example.com}
        subject.application = 'example'
        subject.public_path = '/path/to/application'
      end

      it "should render 'application_url'" do
        subject.application_url = %w{technogate.fr www.technogate.fr}
        subject.render.should =~ %r{technogate.fr www.technogate.fr}
      end
    end

    describe ":reverse_proxy" do
      subject { Nginx.new :reverse_proxy }

      before(:each) do
        subject.application_url = %w{example.com www.example.com}
        subject.application = 'example'
        subject.reverse_proxy_server_address = 'localhost'
        subject.reverse_proxy_server_port = 8080
      end

      it "should render 'reverse_proxy_server_address'" do
        subject.reverse_proxy_server_address = 'web_proxy'
        subject.render.should =~ /upstream example_reverse_proxy .+server web_proxy:8080 fail_timeout=0;.+/m
      end

      it "should render 'reverse_proxy_server_port'" do
        subject.reverse_proxy_server_port = 6565
        subject.render.should =~ /upstream example_reverse_proxy .+server localhost:6565 fail_timeout=0;.+/m
      end

      it "should render 'reverse_proxy_socket'" do
        subject.reverse_proxy_server_address = nil
        subject.reverse_proxy_server_port = nil
        subject.reverse_proxy_socket = "/tmp/socket"
        subject.render.should =~ /upstream example_reverse_proxy .+server unix:\/tmp\/socket;.+/m
      end
    end
  end
end