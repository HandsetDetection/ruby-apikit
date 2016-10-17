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
require 'handset_detection/cache'
require 'json'

# A file backed storage class
#
class Store
  attr_reader :directory, :cache
  @@instance = nil

  # Singleton Constructor
  #
  # +param+ string $path Location of storage ROOT dir.
  # +param+ boolean $createDirectory - Create storage directory if it does not exist
  #
  def initialize
    @dirname = "hd40store"
    @path = ""
    @directory = ""
    @cache = nil
    @config = {} 
  end

  # Get the Singleton
  #
  # +param+ void
  # +return+ Object @@instance
  #
  def self.get_instance
    @@instance = self.new if @@instance == nil
    @@instance
  end

  # Sets the storage config options, optionally creating the storage directory.
  #
  # +param+ array $config An assoc array of config info.
  # +param+ boolean $createDirectory
  # +return+ void
  #
  def set_config(config, create_directory=false)
    config.each { |key, value| @config[key] = value }
    @path = @config.include?('filesdir') ? @config['filesdir'] : File.dirname(__FILE__) 
    @directory = File.join @path, @dirname
    @cache = Cache.new(@config)

    if create_directory 
      unless File.directory? @directory
        unless FileUtils.mkdir_p @directory
          raise("Error : Failed to create storage directory at #{@directory}. Check permissions.")
        end
      end
    end
  end

  # Write data to cache & disk
  #
  # +param+ string $key
  # +param+ array $data
  # +return+ boolean true on success, false otherwise
  #
  def write(key, data)
    return false if data.blank?
    return false unless store(key, data)
    @cache.write(key, data)
  end

  # Store data to disk
  #
  # +param+ string $key The search key (becomes the filename .. so keep it alphanumeric)
  # +param+ array $data Data to persist (will be persisted in json format)
  # +return+ boolean true on success, false otherwise
  #
  def store(key, data)
    jsonstr = JSON.generate data
    begin
      File.open(File.join(@directory, "#{key}.json"), 'w') { |f| f.write jsonstr }
      return true
    rescue
    end
    false
  end

  # Read $data, try cache first
  #
  # +param+ sting $key Key to search for
  # +return+ boolean true on success, false
  #
  def read(key)
    reply = @cache.read(key)
    return reply unless reply.blank?
    reply = fetch(key)
    return false if reply.blank?
    return false unless @cache.write(key, reply)
    return reply
  end

  # Fetch data from disk
  #
  # +param+ string $key.
  # +return+ mixed
  #
  def fetch(key)
    begin
      jsonstr = File.read(File.join(@directory, "#{key}.json"))
      return JSON.parse(jsonstr)
    rescue
    end
    false
  end

  # Returns all devices inside one giant array
  #
  # Used by localDevice* functions to iterate over all devies
  #
  # +param+ void
  # +return+ array All devices in one giant assoc array
  #
  def fetch_devices
    data = {'devices' => []} 
    Dir.glob(File.join(@directory, 'Device*.json')).each do |file|
      jsonstr = File.read file
      return false if not jsonstr or jsonstr.blank?
      data['devices'] << JSON.parse(jsonstr)
    end 
    data
  end

  # Moves a json file into storage.
  #
  # +param+ string $srcAbsName The fully qualified path and file name eg /tmp/sjjhas778hsjhh
  # +param+ string $destName The key name inside the cache eg Device_19.json
  # +return+ boolean true on success, false otherwise
  #
  def move_in(src_abs_name, dest_name)
    FileUtils.mv src_abs_name, File.join(@directory, dest_name)
  end

  # Cleans out the store - Use with caution
  #
  # +param+ void
  # +return+ true on success, false otherwise
  #
  def purge
    files = Dir.glob File.join(@directory, '*.json')
    files.each do |file|
      if File.file? file
        return false unless File.unlink file
      end
    end 
    @cache.purge
  end
end
