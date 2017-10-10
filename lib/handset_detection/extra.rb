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

require 'handset_detection/base'

class Extra < Base
  def initialize(config={})
    @data = nil
    @store = nil
    super()
    set_config config
  end

  # Set Config variables
  #
  # +param+ hash config A config hash
  # +return+ boolean true on success, false otherwise
  #
  def set_config(config)
    @store = Store::get_instance
    @store.set_config config
    true
  end

  def set(data)
    @data = data
  end

  # Matches all HTTP header extras - platform, browser and app
  #
  # +param+ string cls Is 'platform','browser' or 'app'
  # +return+ an Extra on success, false otherwise
  #
  def match_extra(cls, headers)
    headers.delete 'profile'
    order = @detection_config["#{cls}-ua-order"]

    headers.keys.each do |key|
      # Append any x- headers to the list of headers to check
      if (not order.include?(key)) and /^x-/i.match(key)
        order << key
      end
    end 
    order.each do |field|
      unless headers[field].blank?
        _id = get_match 'user-agent', headers[field], cls, field, cls
        if _id
          extra = find_by_id _id
          return extra
        end
      end
    end 
    false
  end

  # Find a device by its id
  #
  # +param+ string _id
  # +return+ hash device on success, false otherwise
  #
  def find_by_id(_id)
    @store.read "Extra_#{_id}"
  end

  # Can learn language from language header or agent
  #
  # +param+ hash headers A key => value hash of sanitized http headers
  # +return+ hash Extra on success, false otherwise
  #
  def match_language(headers)
    extra = { 'Extra' => { 'hd_specs' => {}} }

    # Mock up a fake Extra for merge into detection reply.
    extra['_id'] = 0.to_int
    extra['Extra']['hd_specs']['general_language'] = ''
    extra['Extra']['hd_specs']['general_language_full'] = ''

    # Try directly from http header first
    unless headers['language'].blank?
      candidate = headers['language']
      if @detection_languages.include?(candidate) and @detection_languages[candidate]
        extra['Extra']['hd_specs']['general_language'] = candidate
        extra['Extra']['hd_specs']['general_language_full'] = @detection_languages[candidate]
        return extra
      end
    end

    check_order = @detection_config['language-ua-order'] + headers.keys
    language_list = @detection_languages
    check_order.each do |header|
      if headers.include?(header) and not headers[header].blank?
        agent = headers[header]
        language_list.each do |code, full|
          if /[; \(]#{code}[; \)]/i.match(agent)
            extra['Extra']['hd_specs']['general_language'] = code
            extra['Extra']['hd_specs']['general_language_full'] = full
            return extra
          end
        end 
      end
    end 
    false
  end

  # Returns false if this device definitively cannot run this platform and platform version.
  # Returns true if its possible of if there is any doubt.
  #
  # Note : The detected platform must match the device platform. This is the stock OS as shipped
  # on the device. If someone is running a variant (eg CyanogenMod) then all bets are off.
  #
  # +param+ string specs The specs we want to check.
  # +return+ boolean false if these specs can not run the detected OS, true otherwise.
  #
  def verify_platform(specs=nil)
    platform = @data
    platform = {} unless platform
    if platform.include? 'Extra' and platform['Extra'].include? 'hd_specs'
      platform_name    = platform['Extra']['hd_specs']['general_platform']        .to_s.downcase.strip if platform['Extra']['hd_specs'].include? 'general_platform'
      platform_version = platform['Extra']['hd_specs']['general_platform_version'].to_s.downcase.strip if platform['Extra']['hd_specs'].include? 'general_platform_version'
    else
      platform_name = nil
      platform_version = nil
    end
    device_platform_name        = specs['general_platform']            .to_s.downcase.strip
    device_platform_version_min = specs['general_platform_version']    .to_s.downcase.strip
    device_platform_version_max = specs['general_platform_version_max'].to_s.downcase.strip

    # Its possible that we didnt pickup the platform correctly or the device has no platform info
    # Return true in this case because we cant give a concrete false (it might run this version).
    if platform.blank? or platform_name.blank? or device_platform_name.blank?
      return true
    end

    # Make sure device is running stock OS / Platform
    # Return true in this case because its possible the device can run a different OS (mods / hacks etc..)
    if platform_name != device_platform_name
      return true
    end

    # Detected version is lower than the min version - so definetly false.
    if not platform_version.blank? and not device_platform_version_min.blank? and compare_platform_versions(platform_version, device_platform_version_min) <= -1
      return false
    end

    # Detected version is greater than the max version - so definetly false.
    if not platform_version.blank? and not device_platform_version_max.blank? and compare_platform_versions(platform_version, device_platform_version_max) >= 1
      return false
    end

    # Maybe Ok ..
    true
  end

  # Breaks a version number apart into its Major, minor and point release numbers for comparison.
  #
  # Big Assumption : That version numbers separate their release bits by '.' !!!
  # might need to do some analysis on the string to rip it up right.
  #
  # +param+ string version_number
  # +return+ hash of ('major' => x, 'minor' => y and 'point' => z) on success, null otherwise
  #
  def break_version_apart(version_number)
    tmp = "#{version_number}.0.0.0".split('.', 4)
    reply = {}
    reply['major'] = tmp[0].blank? ? '0' : tmp[0]
    reply['minor'] = tmp[1].blank? ? '0' : tmp[1]
    reply['point'] = tmp[2].blank? ? '0' : tmp[2]
    reply
  end

  # Helper for comparing two strings (numerically if possible)
  #
  # +param+ string a Generally a number, but might be a string
  # +param+ string b Generally a number, but might be a string
  # +return+ int
  #
  def compare_smartly(a, b)
    begin
      return Integer(a) - Integer(b)
    rescue
      return a <=> b
    end
  end

  # Compares two platform version numbers
  #
  # +param+ string va Version A
  # +param+ string vb Version B
  # +return+ < 0 if a < b, 0 if a == b and > 0 if a > b : Also returns 0 if data is absent from either.
  #
  def compare_platform_versions(va, vb)
    return 0 if va.blank? or vb.blank?
    version_a = break_version_apart va
    version_b = break_version_apart vb
    major = compare_smartly version_a['major'], version_b['major']
    minor = compare_smartly version_a['minor'], version_b['minor']
    point = compare_smartly version_a['point'], version_b['point']
    return major if major != 0
    return minor if minor != 0
    return point if point != 0
    return 0
  end
end
