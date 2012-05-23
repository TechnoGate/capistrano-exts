require 'digest/sha1'
require 'highline'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  # Taken from the capistrano code.
  def _cset(name, *args, &block)
    unless exists?(name)
      set(name, *args, &block)
    end
  end

  # Taken from Stackoverflow
  # http://stackoverflow.com/questions/1661586/how-can-you-check-to-see-if-a-file-exists-on-the-remote-server-in-capistrano
  def remote_file_exists?(full_path)
    'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
  end

  def link_file(source_file, destination_file)
    if remote_file_exists?(source_file)
      begin
        run "#{try_sudo} ln -nsf #{source_file} #{destination_file}"
      rescue Capistrano::CommandError
        abort "Unable to create a link for '#{source_file}' at '#{destination_file}'"
      end
    end
  end

  # Return an array of arrays of files to link
  #
  # @param [String] Absolute path to folder from which to link
  # @param [String] Absolute path to folder to which to link
  # @return [Array]
  def exhaustive_list_of_files_to_link(from, to)
    script = <<-END
exhaustive_list_of_files_to_link() {
  files="";

  for f in `ls -A1 ${1}`; do
    file="${2}/${f}";
    f="${1}/${f}";
    if [[ -e "${file}" ]]; then
      files="${files} `exhaustive_list_of_files_to_link ${f} ${file}`";
    else
      files="${files} ${f}:${file}";
    fi;
  done;
  echo "${files}";
};
    END

    script << "exhaustive_list_of_files_to_link '#{from}' '#{to}';"

    begin
      files = capture(script).strip.split(' ')
      files.map {|f| f.split(':')}
    rescue Capistrano::CommandError
      abort "Unable to get files list"
    end
  end

  def link_files(path, files = {})
    files.each do |f|
      file_name = f.dup.gsub(/\//, '_')
      unless remote_file_exists?("#{path}/#{file_name}")
        begin
          run <<-CMD
            #{try_sudo} cp -a #{latest_release}/#{f} #{path}/#{file_name}
          CMD
        rescue Capistrano::CommandError
          if remote_file_exists?("#{latest_release}/#{f}.default")
            run <<-CMD
              #{try_sudo} cp #{latest_release}/#{f}.default #{path}/#{file_name}
            CMD
          else
            run <<-CMD
              #{try_sudo} touch #{path}/#{file_name}
            CMD
            logger.info "WARNING: You should edit '#{path}/#{file_name}' or re-create it as a folder if that's your intention."
          end
        end
      end

      link_file File.join(path, file_name), File.join(fetch(:latest_release), f)
    end
  end

  def gen_pass( len = 8 )
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      newpass = ""
      1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
      return newpass
  end

  def ask(what, options = {})
    default = options[:default]
    validate = options[:validate] || /(y(es)?)|(no?)|(a(bort)?|\n)/i
    echo = (options[:echo].nil?) ? true : options[:echo]

    ui = HighLine.new
    ui.ask("#{what}?  ") do |q|
      q.overwrite = false
      q.default = default
      q.validate = validate
      q.responses[:not_valid] = what
      unless echo
        q.echo = "*"
      end
    end
  end

  def mysql_db_hosts
    # TODO: Do some real work here, we shouldn't be allowing all hosts but only all db/web/app hosts.
    ['%']
  end

  def generate_random_file_name(data = nil)
    if data
      "#{fetch :application}_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S-%L')}_#{Digest::SHA1.hexdigest data}"
    else
      "#{fetch :application}_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S-%L')}"
    end
  end

  def random_tmp_file(data = nil)
    "/tmp/#{generate_random_file_name data}"
  end

  # Helper for some mysql tasks
  def credentials_formatted(credentials, adapter_mapping = {})
    if adapter_mapping.include?(credentials[:adapter])
      adapter = adapter_mapping[credentials[:adapter]]
    else
      adapter = credentials[:adapter]
    end

    return <<-EOS
adapter: #{adapter}
hostname: #{credentials[:host]}
username: #{credentials[:user]}
password: #{credentials[:pass]}
    EOS
  end

  # Helper for rails database.yml generator
  def rails_database_yml(credentials, adapter_mapping = {})
    if adapter_mapping.include?(credentials[:adapter])
      adapter = adapter_mapping[credentials[:adapter]]
    else
      adapter = credentials[:adapter]
    end

    return <<-EOS
#{fetch :rails_env}:
  adapter: #{adapter}
  encoding: utf8
  reconnect: false
  pool: 10
  host: #{credentials[:host]}
  username: #{credentials[:user]}
  password: #{credentials[:pass]}
  database: #{fetch :mysql_db_name}
    EOS
  end

  # Read a remote file
  def read(file)
    capture("cat #{file}")
  end

  # ask_for_confirmation(what)
  # This function asks the user for confirmation (confirm running the task)
  # If the user answers no, then the task won't be executed.
  def ask_for_confirmation(what, options = {})
    unless exists?(:force) and fetch(:force) == true
      # Ask for a confirmation
      response = ask(what, options)
      if response =~ /(no?)|(a(bort)?|\n)/i
        abort "Canceled by the user."
      end
    end
  end

  # Tries bundle exec
  # TODO: Do some real work here
  def try_bundle_exec
    "bundle exec"
  end
end
