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

require 'dalli'

class Memcached
  # Construct a new Memcached cache object.
  #
  def initialize(config={})
    if config.include?('cache') and config['cache'].include?('memcached') and not config['cache']['memcached']['servers'].blank?
      servers = config['cache']['memcached']['servers']
    else
      servers = ['localhost:11211'] 
    end

    if config.include?('cache') and config['cache'].include?('memcached') and not config['cache']['memcached']['options'].blank?
      options = config['cache']['memcached']['options']
    else
      options = { 'value_max_bytes' => 4000000 }
    end
    options = options.map {|k, v| [k.to_sym, v]}.to_h
    @cache = Dalli::Client.new(servers, options)
  end

  # Get key
  #
  def get(key)
    @cache.get key
  end

  # Set key
  #
  def set(key, data, ttl)
    @cache.set key, data, ttl
  end

  # Delete key
  #
  def del(key)
    @cache.delete key
  end
  
  # Flush cache
  def flush
    @cache.flush
  end
end
