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

require 'handset_detection/vendor/blank'
require 'handset_detection/cache/filesystem'
require 'handset_detection/cache/memcached'
require 'handset_detection/cache/rails'
require 'handset_detection/cache/none'

# Cache class for HandsetDetection
#
# Notes :
# *  - Cache objects may be > 1Mb when serialized so ensure memcache or memcached can handle it.
#
class Cache
  def initialize(config={})
    @prefix = nil
    @ttl = nil
    @cache = nil
    set_config config
  end

  # Set config file
  #
  # +param+ array $config An assoc array of config data
  # +return+ true on success, false otherwise
  #
  def set_config(config)
    @config = config 
    @prefix = (config.include?('cache') and config['cache'].include?('prefix')) ? config['cache']['prefix'] : 'hd40'
    @duration = (config.include?('cache') and config['cache'].include?('ttl')) ? config['cache']['ttl'] : 7200
    if config.include?('cache') and config['cache'].include?('memcached')
      @cache = Memcached.new(@config)
    elsif config.include?('cache') and config['cache'].include?('rails')
      @cache = RailsCache.new(@config)
    elsif config.include?('cache') and config['cache'].include?('none')
      @cache = None.new(@config)
    elsif defined? Rails
      @cache = RailsCache.new(@config)
    else
      @cache = FileSystem.new(@config)
    end
    true
  end

  # Fetch a cache key
  #
  # +param+ string $key
  # +return+ value on success, null otherwise
  #
  def read(key)
    @cache.get @prefix + key
  end

  # Store a data at $key
  # 
  # +param+ string $key
  # +param+ mixed $data
  # +return+ true on success, false otherwise
  #
  def write(key, data)
    @cache.set @prefix + key, data, @duration
  end

  # Remove a cache key (and its data)
  # 
  # +param+ string $key
  # +return+ true on success, false otherwise
  #
  def delete(key)
    @cache.del @prefix + key
  end

  # Flush the whole cache
  #
  # +param+ void
  # +return+ true on success, false otherwise
  #
  def purge
    @cache.flush
  end
end
