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

class FileSystem
  # Construct a new File cache object.
  #
  # +param+  string dir
  #
  def initialize(config={})
    if config.include?('cache') and config['cache'].include?('file') and not config['cache']['file']['directory'].blank?
      dir = config['cache']['file']['directory']
    else
      dir = Dir.tmpdir
    end
    dir += File::SEPARATOR unless dir.match(/#{File::SEPARATOR}$/)
    raise 'Directory does not exist.' unless File.directory? dir
    raise 'Directory is not writable.' unless File.writable? dir
    @dir = dir
    @prefix = (config.include?('cache') and config['cache'].include?('prefix')) ? config['cache']['prefix'] : 'hd40'
  end

  # Get key
  #
  def get(key)
    fname = get_file_path key 
    return nil unless File.file? fname

    data = File.readlines fname 
    exp = data.shift.to_i
    return nil if Time.now.to_i > exp and exp != -1

    Marshal::load data.join('')
  end

  # Set key
  #
  def set(key, data, ttl)
    fname = get_file_path key 
    File.open(fname, 'w') { |f| f.write((Time.now.to_i + ttl).to_s + "\n" + Marshal::dump(data)) }
    true
  end

  # Delete key
  #
  def del(key)
    fname = get_file_path key 
    return true unless File.file? fname
    File.unlink fname
  end
  
  # Flush cache
  def flush
    files = Dir.glob @dir + @prefix + '*'
    files.each do |file|
      File.unlink file if File.file? file
    end
    true
  end

  # Get fully qualified path to file
  def get_file_path(key)
    @dir + key 
  end
end
