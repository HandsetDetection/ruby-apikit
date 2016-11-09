#--
# Copyright (c) Richard Uren 2016 <richard@teleport.com.au>
# All Rights Reserved
#
# LICENSE: Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met: Redistributions of source code must retain the
# above copyright notice, this list of conditions and the following
# disclaimer. Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
# NO EVENT SHALL CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.
#++

require 'fileutils'
require 'handset_detection/base'
require 'handset_detection/device'
require 'yaml'
require 'zip'

# HD4 Class
#
class HD4 < Base
  attr_reader :cache

  # This is the main constructor for the class HD4
  #
  # +param+ mixed config can be a hash of config options or a fully qualified path to an alternate config file.
  # +return+ void
  #
  def initialize(config=nil)
    @realm = 'APIv4'
    @reply = nil
    @raw_reply = nil
    @detect_request = {} 
    @error = ''
    @logger = nil
    @debug = false
    @config = { 
      'username' => '',
      'secret' => '',
      'site_id' => '',
      'use_proxy' => 0,
      'proxy_server' => '',
      'proxy_port' => '',
      'proxy_user' => '',
      'proxy_pass' => '',
      'use_local' => false,
      'api_server' => 'api.handsetdetection.com',
      'timeout' => 10,
      'debug' => false,
      'filesdir' => '',
      'retries' => 3,
      'cache_requests' => false,
      'geoip' => false,
      'log_unknown' => true
    }
    @tree = {} 
    if config.blank?
      if defined? Rails
        config = File.join Rails.root, 'config', 'hdconfig.yml'
      else
        config = 'hdconfig.yml'
      end
    end
    super()
    set_config config
    if @config['username'].blank?
      raise 'Error : API username not set. Download a premade config from your Site Settings.'
    elsif @config['secret'].blank?
      raise 'Error : API secret not set. Download a premade config from your Site Settings.'
    end
  end

  def set_local_detection(enable)
     @config['use_local'] = enable
  end

  def set_proxy_user(user)
     @config['proxy_user'] = user
  end

  def set_proxy_pass(pass)
     @config['proxy_pass'] = pass
  end

  def set_use_proxy(proxy)
     @config['use_proxy'] = proxy
  end

  def set_proxy_server(name) 
     @config['proxy_server'] = name
  end

  def set_proxy_port(number) 
    @config['proxy_port'] = number
  end

  def set_secret(secret) 
     @config['secret'] = secret
  end

  def set_username(user) 
     @config['username'] = user
  end

  def set_timeout(timeout) 
     @config['timeout'] = timeout
  end

  def set_detect_var(key, value) 
     @detect_request[key.downcase] = value
  end

  def set_site_id(siteid) 
     @config['site_id'] = siteid.to_i
  end

  def set_use_local(value) 
     @config['use_local'] = value
  end

  def set_api_server(value) 
     @config['api_server'] = value
  end

  def set_logger(function) 
     @config['logger'] = function
  end

  def set_files_dir(directory)
    @config['filesdir'] = directory
    unless @store.set_directory(directory)
      raise "Error : Failed to create cache directory in #{directory}. Set your filesdir config setting or check directory permissions."
    end
  end

  def get_local_detection
     @config['use_local']
  end

  def get_proxy_user
     @config['proxy_user']
  end

  def get_proxy_pass
     @config['proxy_pass']
  end

  def get_use_proxy
     @config['use_proxy']
  end

  def get_proxy_server
     @config['proxy_server']
  end

  def get_proxy_port
     @config['proxy_port']
  end

  def get_error
     @error
  end

  def get_error_msg
     @error
  end

  def get_secret
     @config['secret']
  end

  def get_username
     @config['username']
  end

  def get_timeout
     @config['timeout']
  end

  def get_reply
     @reply
  end

  def get_raw_reply
     @raw_reply
  end

  def get_site_id
     @config['site_id']
  end

  def get_use_local
     @config['use_local']
  end

  def get_api_server
     @config['api_server']
  end

  def get_detect_request
     @detect_request
  end

  def get_files_dir
     @config['filesdir']
  end
  
  # Set config file
  #
  # +param+ hash config An assoc array of config data
  # +return+ true on success, false otherwise
  #
  def set_config(cfg)
    if cfg.is_a? Hash
      @config = cfg
    elsif cfg.is_a? String
      @config = YAML::load_file cfg
    end
    
    if @config['filesdir'].blank?
      @config['filesdir'] = File.dirname __FILE__ 
    end

    @store = Store::get_instance
    @store.set_config @config, true
    @cache = Cache.new(@config)
    @device = Device.new(@config)
    true
  end

  # Setup the api kit with HTTP headers from the web server environment.
  # 
  # This is likely what you want to send if you're invoking this class for each new website visitor.
  # You can override or add to these with set_detect_var(key, value)
  # 
  # +param+ env A hash holding web server environment variables. In Rails: request.env or request.headers
  # +return+ void
  #  
  def set_server_headers(env)
    env.each do |k, v|
      next unless k.match(/^HTTP_/)
      name = k.sub(/^HTTP_/, '').split(/_/).map { |x| x.capitalize }.join('-')
      @detect_request[name] = v
    end
  end

  # List all known vendors
  #
  # +param+ void
  # +return+ bool true on success, false otherwise. Use getReply to inspect results on success.
  #
  def device_vendors
    return remote("device/vendors", nil) unless @config['use_local']
    @reply = @device.get_reply if @device.local_vendors
    set_error @device.get_status, @device.get_message
  end
  
  # List all models for a given vendor
  #
  # +param+ string vendor The device vendor eg Apple
  # +return+ bool true on success, false otherwise. Use getReply to inspect results on success.
  #  
  def device_models(vendor)
    unless @config['use_local']
      return remote "device/models/#{vendor}", nil
    end

    if @device.local_models vendor
      @reply = @device.get_reply
    end

    set_error @device.get_status, @device.get_message
  end
  
  # Find properties for a specific device
  #
  # +param+ string vendor The device vendor eg. Nokia
  # +param+ string model The deviec model eg. N95
  # +return+ bool true on success, false otherwise. Use getReply to inspect results on success.
  #
  def device_view(vendor, model)
    unless @config['use_local']
      return remote "device/view/#{vendor}/#{model}", nil 
    end
    if @device.local_view vendor, model
      @reply = @device.get_reply
    end
    set_error @device.get_status, @device.get_message
  end
  
  # Find which devices have property 'X'.
  #
  # +param+ string key Property to inquire about eg 'network', 'connectors' etc...
  # +param+ string value Value to inquire about eg 'CDMA', 'USB' etc ...
  # +return+ bool true on success, false otherwise. Use getReply to inspect results on success. 
  #  
  def device_what_has(key, value)
    unless @config['use_local']
      return remote("device/whathas/#{key}/#{value}", nil)
    end
    
    if @device.local_what_has key, value
      @reply = @device.get_reply
    end
      
    set_error @device.get_status, @device.get_message
  end
    
  # Device Detect
  #
  # +param+ array data : Data for device detection : HTTP Headers usually
  # +return+ bool true on success, false otherwise. Use getReply to inspect results on success.
  #    
  def device_detect(data={})
    id = data['id'].blank? ? @config['site_id'] : data['id']
    data.delete 'id'
    request_body = data.blank? ? @detect_request: data
    fast_key = ''
    
    # If caching enabled then check cache
    unless @config['cache_requests'].blank?
      request_body.each { |k, v| headers[k.downcase] = v }
      headers = headers.sort.to_h
      fast_key = JSON.generate(headers).gsub(/ /, '')
      if reply = @cache.read(fast_key)
        @reply = reply
        @raw_reply = ''
        return set_error 0, "OK"
      end
    end
    
    if @config['use_local']
      # log("Starting Local Detection")
      result = @device.local_detect(request_body)
      set_error @device.get_status, @device.get_message
      set_reply @device.get_reply
      # log"Finishing Local Detection : result is #{result}"
      # Log unknown headers if enabled
      if @config['log_unknown'] == true and not result
        send_remote_syslog request_body
      end
    else
      # log "Starting API Detection"
      result = remote "device/detect/#{id}", request_body
      # log "Finishing API Detection : result is #{result}"
    end

    # If we got a result then cache it
    if result and not @config['cache_requests'].blank?
      @cache.write fast_key, reply
    end
    result
  end

  # Fetch an archive from handset detection which contains all the device specs and matching trees as individual json files.
  #
  # +param+ void
  # +return+ hd_specs data on success, false otherwise
  #
  def device_fetch_archive
    path = File.join(@config['filesdir'], "ultimate.zip")
    unless @config['local_archive_source'].blank?
      FileUtils.cp File.join(@config['local_archive_source'], "ultimate.zip"), path
      return install_archive path 
    end

    return false unless remote("device/fetcharchive", '', 'zip')
    data = get_raw_reply
    if data.blank? 
      return set_error 299, 'Error : FetchArchive failed. Bad Download. File is zero length'
    elsif data.length < 9000000
      trythis = JSON.parse data
      if trythis and trythis.include?('status') and trythis.include('message')
        return set_error trythis['status'].to_i, trythis['message']
      end
      set_error 299, "Error : FetchArchive failed. Bad Download. File too short at #{data.length} bytes."
    end

    begin
      File.open(path, 'w') { |f| f.write(get_raw_reply) }
    rescue
      return set_error 299, "Error : FetchArchive failed. Could not write #{path}"
    end
    return install_archive path 
  end

  # Community Fetch Archive - Fetch the community archive version
  #
  # +param+ void
  # +return+ hd_specs data on success, false otherwise
  #
  def community_fetch_archive
    path = File.join(@config['filesdir'], "communityultimate.zip")
    unless @config['local_archive_source'].blank?
      FileUtils.cp File.join(@config['local_archive_source'], "communityultimate.zip"), path
      return install_archive path 
    end

    return false unless remote "community/fetcharchive", '', 'zip', false
    data = get_raw_reply
    if data.blank?
      return set_error 299, 'Error : FetchArchive failed. Bad Download. File is zero length'
    elsif data.length < 900000
      trythis = JSON.parse data
      if not trythis.blank? and trythis.include?('status') and trythis.include?('message')
        return set_error trythis['status'].to_int, trythis['message']
      end
      return set_error 299, "Error : FetchArchive failed. Bad Download. File too short at #{data.length} bytes."
    end

    begin
      File.open(path, 'w') { |f| f.write data  }
    rescue
      return set_error 299, "Error : FetchArchive failed. Could not write #{path}"
    end
   return install_archive path 
  end

  # Install an ultimate archive file
  #
  # +param+ string $file Fully qualified path to file
  # +return+ boolean true on success, false otherwise
  #
  def install_archive(file)
    # Unzip the archive and cache the individual files
    Zip::File.open(file) do |zip_file|
      #  return $this->setError(299, "Error : Failed to open ". $file)
      zip_file.each do |entry|
        filename = File.join Dir.tmpdir, entry.name
        entry.extract(filename) {true}
        @store.move_in filename, entry.name
      end
    end
    true
  end

  # This method can indicate if using the js Helper would yeild more accurate results.
  #
  # +param+ hash headers
  # +return+ true if helpful, false otherwise.
  #
  def is_helper_useful(headers)
    @device.is_helper_useful headers
  end
end
