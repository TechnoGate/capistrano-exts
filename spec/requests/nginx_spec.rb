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

  end

  describe ":reverse_proxy" do

  end

end