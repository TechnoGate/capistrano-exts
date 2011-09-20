require 'spec_helper'

describe Nginx do

  describe ":php_fpm" do
    subject { Nginx.new :php_fpm}

    before(:each) do
      @application_url  = %w(technogate.fr www.technogate.fr)
      @application      = 'technogate'
      @php_fpm_host     = 'localhost'
      @php_fpm_port     = 30313
      @public_path      = '/home/vhosts/technogate/public'
      @indexes          = %w(index.php index.html)

      subject.application_url = @application_url
      subject.application     = @application
      subject.php_fpm_host    = @php_fpm_host
      subject.php_fpm_port    = @php_fpm_port
      subject.public_path     = @public_path
      subject.indexes         = @indexes
    end

    it "should render the correct file" do
      expected_result = File.read File.join(RENDERED_TEMPLATES_PATH, 'nginx_php_fpm.conf')
      subject.render.should == expected_result
    end
  end

  describe ":passenger" do
    subject { Nginx.new :passenger}

    before(:each) do
      @application_url  = %w(technogate.fr www.technogate.fr)
      @application      = 'technogate'
      @public_path      = '/home/vhosts/technogate/public'

      subject.application_url = @application_url
      subject.application     = @application
      subject.public_path     = @public_path
    end

    it "should render the correct file" do
      expected_result = File.read File.join(RENDERED_TEMPLATES_PATH, 'nginx_passenger.conf')
      subject.render.should == expected_result
    end
  end

  describe ":reverse_proxy socket" do
    subject { Nginx.new :reverse_proxy}

    before(:each) do
      @application_url      = %w(technogate.fr www.technogate.fr)
      @application          = 'technogate'
      @reverse_proxy_socket = '/home/vhosts/technogate/tmp/unicorn.sock'

      subject.application_url       = @application_url
      subject.application           = @application
      subject.reverse_proxy_socket  = @reverse_proxy_socket
    end

    it "should render the correct file" do
      expected_result = File.read File.join(RENDERED_TEMPLATES_PATH, 'nginx_reverse_proxy_socket.conf')
      subject.render.should == expected_result
    end
  end

  describe ":reverse_proxy address" do
    subject { Nginx.new :reverse_proxy}

    before(:each) do
      @application_url              = %w(technogate.fr www.technogate.fr)
      @application                  = 'technogate'
      @reverse_proxy_server_address = 'localhost'
      @reverse_proxy_server_port    = '8080'

      subject.application_url               = @application_url
      subject.application                   = @application
      subject.reverse_proxy_server_address  = @reverse_proxy_server_address
      subject.reverse_proxy_server_port     = @reverse_proxy_server_port
    end

    it "should render the correct file" do
      expected_result = File.read File.join(RENDERED_TEMPLATES_PATH, 'nginx_reverse_proxy_address.conf')
      subject.render.should == expected_result
    end
  end

end