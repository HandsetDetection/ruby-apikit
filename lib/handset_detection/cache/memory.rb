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

begin
  require 'thread_safe'
rescue LoadError
end

class Memory
  # Construct a new Memory cache object.
  #
  # +param+  string dir
  #
  def initialize(config={})
    @thread_safe = (config.include?('cache') and config['cache'].include?('memory') and config['cache']['memory']['thread_safe']) ? true : false
    make_cache unless defined?(@@c)
  end

  # Get key
  #
  def get(key)
    data, exp = @@c[key]
    return nil if exp.nil? or Time.now.to_i > exp
    data 
  end

  # Set key
  #
  def set(key, data, ttl)
    @@c[key] = [data, Time.now.to_i + ttl]
    true
  end

  # Delete key
  #
  def del(key)
    @@c.delete key
    true
  end
  
  # Flush cache
  def flush
    make_cache
    true
  end

  # Initialize the cache data structure
  #
  def make_cache
    if !@thread_safe 
      @@c = {}
    elsif defined?(ThreadSafe)
      @@c = ThreadSafe::Hash.new
    else
      raise 'ThreadSafe is required to use the Memory cache.'
    end    
  end
end
