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
require 'handset_detection/store'
require 'handset_detection/extra'

class Device < Base
  def initialize(config={})
    @device = nil
    @platform = nil
    @browser = nil
    @app = nil
    @rating_result = nil
    @store = nil
    @extra = nil
    @config = nil
    super()
    set_config config
    @device_headers = {}
    @extra_headers = {}
  end

  # Set Config sets config vars
  #
  # +param+ hash config A config assoc array.
  # +return+ true on success, false otherwise
  #
  def set_config(config)
    config.each do |key, value|
      @config[key] = value
    end
    @store = Store::get_instance
    @store.set_config @config
    @extra = Extra.new config
  end

  # Find all device vendors
  #
  # +param+ void
  # +return+ bool true on success, false otherwise. Use getReply to inspect results on success.
  #
  def local_vendors
    @reply = {} 
    data = fetch_devices 
    return false if data.blank?

    tmp = []
    data['devices'].each do |item|
      tmp << item['Device']['hd_specs']['general_vendor']
    end 
    @reply['vendor'] = tmp.uniq 
    @reply['vendor'].sort!
    set_error 0, 'OK'
  end

  # Find all models for the sepecified vendor
  #
  # +param+ string vendor The device vendor
  # +return+ bool true on success, false otherwise. Use getReply to inspect results on success.
  #
  def local_models(vendor)
    @reply = {} 
    data = fetch_devices
    return false if data.blank?

    vendor = vendor.downcase
    tmp = [] 
    data['devices'].each do |item|
      if vendor == item['Device']['hd_specs']['general_vendor'].downcase
        tmp << item['Device']['hd_specs']['general_model']
      end
      key = vendor + " "
      unless item['Device']['hd_specs']['general_aliases'].blank?
        item['Device']['hd_specs']['general_aliases'].each do |alias_item|
          result = alias_item.downcase.index(key.downcase)
          tmp << alias_item.sub(key, '') if result === 0
        end 
      end
    end 
    tmp.sort!
    @reply['model'] = tmp.uniq
    set_error 0, 'OK'
  end

  # Finds all the specs for a specific device
  #
  # +param+ string vendor The device vendor
  # +param+ string model The device model
  # +return+ bool true on success, false otherwise. Use getReply to inspect results on success.
  #
  def local_view(vendor, model)
    @reply = {} 
    data = fetch_devices
    return false if data.blank?

    vendor = vendor.downcase
    model = model.downcase
    data['devices'].each do |item|
      if vendor == item['Device']['hd_specs']['general_vendor'].downcase and model == item['Device']['hd_specs']['general_model'].downcase
        @reply['device'] = item['Device']['hd_specs']
        return set_error 0, 'OK'
      end
    end
    set_error 301, 'Nothing found'
  end

  # Finds all devices that have a specific property
  #
  # +param+ string key
  # +param+ string value
  # +return+ bool true on success, false otherwise. Use getReply to inspect results on success.
  #
  def local_what_has(key, value)
    data = fetch_devices 
    return false if data.blank?

    tmp = []
    value = value.downcase
    data['devices'].each do |item|
      next if item['Device']['hd_specs'][key].blank?
      match = false
      if item['Device']['hd_specs'][key].is_a? Array
        item['Device']['hd_specs'][key].each do |check|
          if check.downcase.include? value.downcase 
            match = true
          end
        end
      elsif item['Device']['hd_specs'][key].downcase.include? value.downcase
        match = true
      end

      if match
        tmp << { 'id' => item['Device']['_id'],
          'general_vendor' => item['Device']['hd_specs']['general_vendor'],
          'general_model' => item['Device']['hd_specs']['general_model'] }
      end
    end
    @reply['devices'] = tmp
    set_error 0, 'OK'
  end

  # Perform a local detection
  #
  # +param+ array headers HTTP headers as an assoc array. keys are standard http header names eg user-agent, x-wap-profile
  # +return+ bool true on success, false otherwise
  #
  def local_detect(h)
    headers = {}
    # lowercase headers on the way in.
    h.each {|k, v| headers[k.downcase] = v}
    hardware_info = headers['x-local-hardwareinfo']
    headers.delete('x-local-hardwareinfo')

    # Is this a native detection or a HTTP detection ?
    if has_bi_keys headers
      return v4_match_build_info headers
    end
    v4_match_http_headers headers, hardware_info
  end

  # Returns the rating score for a device based on the passed values
  #
  # +param+ string deviceId : The ID of the device to check.
  # +param+ hash props Properties extracted from the device (display_x, display_y etc .. )
  # +return+ array of rating information. (which includes 'score' which is an int value that is a percentage.)
  #
  def find_rating(device_id, props)
    device = find_by_id(device_id)
    return nil if device['Device']['hd_specs'].blank?

    specs = device['Device']['hd_specs']

    total = 70
    result = {} 

    # Display Resolution - Worth 40 points if correct
    result['resolution'] = 0
    unless props['display_x'].blank? or props['display_y'].blank?
      p_max_res = [props['display_x'], props['display_y']].max.to_i
      p_min_res = [props['display_x'], props['display_y']].min.to_i
      s_max_res = [specs['display_x'], specs['display_y']].max.to_i
      s_min_res = [specs['display_x'], specs['display_y']].min.to_i
      if p_max_res == s_max_res and p_min_res == s_min_res
        # Check for native match first
        result['resolution'] = 40
      else
        # Check for css dimensions match.
        # css dimensions should be display_[xy] / display_pixel_ratio or others in other modes.
        # Devices can have multiple css display modes (eg. iPhone 6, iPhone 6+ Zoom mode)
        css_screen_sizes = specs['display_css_screen_sizes'].blank? ? [] : specs['display_css_screen_sizes']
        css_screen_sizes.each do |size|
          dimensions = size.split('x') 
          tmp_max_res = dimensions.max.to_i
          tmp_min_res = dimensions.min.to_i
          if p_max_res == tmp_max_res and p_min_res == tmp_min_res
            result['resolution'] = 40
            break
          end
        end
      end
    end

    # Display pixel ratio - 20 points
    result['display_pixel_ratio'] = 20
    unless props['display_pixel_ratio'].blank?
      # Note : display_pixel_ratio will be a string stored as 1.33 or 1.5 or 2, perhaps 2.0 ..
      if specs['display_pixel_ratio'].to_f.round(2) == (props['display_pixel_ratio'] / 100.to_f).round(2)
        result['display_pixel_ratio'] = 40
      end
    end

    # Benchmark - 10 points - Enough to tie break but not enough to overrule display or pixel ratio.
    result['benchmark'] = 0
    unless props['benchmark'].blank?
      unless specs['benchmark_min'].blank? or specs['benchmark_max'].blank?
        if props['benchmark'].to_i >= specs['benchmark_min'].to_i and props['benchmark'].to_i <= specs['benchmark_max'].to_i
          # Inside range
          result['benchmark'] = 10
        end
      end
    end

    result['score'] = result.values.inject(0){ |sum, x| sum + x }.to_i
    result['possible'] = total
    result['_id'] = device_id

    # Distance from mean used in tie breaking situations if two devices have the same score.
    result['distance'] = 100000
    unless specs['benchmark_min'].blank? or specs['benchmark_max'].blank? or props['benchmark'].blank?
      result['distance'] = ((specs['benchmark_min'] + specs['benchmark_max']) / 2 - props['benchmark']).abs.to_i
    end
    result
  end

  # Overlays specs onto a device
  #
  # +param+ string specsField : Either 'platform', 'browser', 'language'
  # +return+ void
  #
  def specs_overlay(specs_field, device, specs)
    if specs.include? 'hd_specs'
      if specs_field == 'platform'
          unless specs['hd_specs']['general_platform'].blank? or specs['hd_specs']['general_platform_version'].blank?
            device['Device']['hd_specs']['general_platform'] = specs['hd_specs']['general_platform']
            device['Device']['hd_specs']['general_platform_version'] = specs['hd_specs']['general_platform_version']
          else
            unless specs['hd_specs']['general_platform'].blank? or specs['hd_specs']['general_platform'] == device['Device']['hd_specs']['general_platform']
              device['Device']['hd_specs']['general_platform'] = specs['hd_specs']['general_platform']
              device['Device']['hd_specs']['general_platform_version'] = ''
            end
          end
      elsif specs_field == 'browser'
          unless specs['hd_specs']['general_browser'].blank?
            device['Device']['hd_specs']['general_browser'] = specs['hd_specs']['general_browser']
            device['Device']['hd_specs']['general_browser_version'] = specs['hd_specs']['general_browser_version']
          end
      elsif specs_field == 'app'
          unless specs['hd_specs']['general_app'].blank?
            device['Device']['hd_specs']['general_app'] = specs['hd_specs']['general_app']
            device['Device']['hd_specs']['general_app_version'] = specs['hd_specs']['general_app_version']
            device['Device']['hd_specs']['general_app_category'] = specs['hd_specs']['general_app_category']
          end
      elsif specs_field == 'language'
          unless specs['hd_specs']['general_language'].blank?
            device['Device']['hd_specs']['general_language'] = specs['hd_specs']['general_language']
            device['Device']['hd_specs']['general_language_full'] = specs['hd_specs']['general_language_full']
          end
      end
    end
    device
  end

  # Takes a string of onDeviceInformation and turns it into something that can be used for high accuracy checking.
  #
  # Strings a usually generated from cookies, but may also be supplied in headers.
  # The format is w;h;r;b where w is the display width, h is the display height, r is the pixel ratio and b is the benchmark.
  # display_x, display_y, display_pixel_ratio, general_benchmark
  #
  # +param+ string hardwareInfo String of light weight device property information, separated by ':'
  # +return+ array partial specs array of information we can use to improve detection accuracy
  #
  def info_string_to_hash(hardware_info)
    # Remove the header or cookie name from the string 'x-specs1a='
    if hardware_info.include?('=')
      tmp = hardware_info.split('=') 
      if tmp[1].blank?
         return {}
      else
        hardware_info = tmp[1]
      end
    end
    reply = {} 
    info = hardware_info.split(':')
    return {} if info.length != 4 
    reply['display_x'] = info[0].strip.to_i
    reply['display_y'] = info[1].strip.to_i
    reply['display_pixel_ratio'] = info[2].strip.to_i
    reply['benchmark'] = info[3].strip.to_i
    reply
  end

  # Overlays hardware info onto a device - Used in generic replys
  #
  # +param+ hash device
  # +param+ hardwareInfo
  # +return+ void
  #
  def hardware_info_overlay(device, info)
    unless info.blank?
      device['Device']['hd_specs']['display_x'] = info['display_x'] unless info['display_x'].blank?
      device['Device']['hd_specs']['display_y'] = info['display_y'] unless info['display_y'].blank?
      device['Device']['hd_specs']['display_pixel_ratio'] = info['display_pixel_ratio'] unless info['display_pixel_ratio'].blank?
    end
    device
  end

  # Device matching
  #
  # Plan of attack :
  #  1) Look for opera headers first - as they're definitive
  #  2) Try profile match - only devices which have unique profiles will match.
  #  3) Try user-agent match
  #  4) Try other x-headers
  #  5) Try all remaining headers
  #
  # +param+ void
  # +return+ array The matched device or null if not found
  #
  def match_device(headers)
    # Remember the agent for generic matching later.
    agent = ""
    # Opera mini sometimes puts the vendor # model in the header - nice! ... sometimes it puts ? # ? in as well
    if (not headers['x-operamini-phone'].blank?) and headers['x-operamini-phone'].strip != "? # ?"
      _id = get_match 'x-operamini-phone', headers['x-operamini-phone'], DETECTIONV4_STANDARD, 'x-operamini-phone', 'device'
      return find_by_id(_id) if _id
      agent = headers['x-operamini-phone']
      headers.delete('x-operamini-phone')
    end

    # Profile header matching
    unless headers['profile'].blank?
      _id = get_match 'profile', headers['profile'], DETECTIONV4_STANDARD, 'profile', 'device'
      return find_by_id _id if _id
      headers.delete('profile')
    end

    # Profile header matching
    unless headers['x-wap-profile'].blank?
      _id = get_match 'profile', headers['x-wap-profile'], DETECTIONV4_STANDARD, 'x-wap-profile', 'device'
      return find_by_id _id if _id
      headers.delete('x-wap-profile')
    end

    # Match nominated headers ahead of x- headers
    order = @detection_config['device-ua-order']
    headers.each do |key, value|
      order << key if (not order.include? key) and /^x-/i.match key
    end

    order.each do |item|
      unless headers[item].blank?
        # log "Trying user-agent match on header #{item}"
        _id = get_match 'user-agent', headers[item], DETECTIONV4_STANDARD, item, 'device'
        return find_by_id _id if _id
      end
    end

    # Generic matching - Match of last resort
    # log('Trying Generic Match')

    if headers.include? 'x-operamini-phone-ua'
      _id = get_match 'user-agent', headers['x-operamini-phone-ua'], DETECTIONV4_GENERIC, 'agent', 'device'
    end
    if _id.blank? and headers.include? 'agent'
      _id =get_match 'user-agent', headers['agent'], DETECTIONV4_GENERIC, 'agent', 'device'
    end
    if _id.blank? and headers.include? 'user-agent'
      _id = get_match 'user-agent', headers['user-agent'], DETECTIONV4_GENERIC, 'agent', 'device'
    end

    return find_by_id _id unless _id.blank?
    false
  end

  # Find a device by its id
  #
  # +param+ string _id
  # +return+ hash device on success, false otherwise
  #
  def find_by_id(_id)
    @store.read("Device_#{_id}")
  end

  # Internal helper for building a list of all devices.
  #
  # +param+ void
  # +return+ array List of all devices.
  #
  def fetch_devices
    result = @store.fetch_devices
    unless result
      return set_error 299, "Error : fetchDevices cannot read files from store."
    end
    result
  end

  # BuildInfo Matching
  #
  # Takes a set of buildInfo key/value pairs & works out what the device is
  #
  # +param+ hash buildInfo - Buildinfo key/value array
  # +return+ mixed device array on success, false otherwise
  #
  def v4_match_build_info(build_info)
    @device = nil
    @platform = nil
    @browser = nil
    @app = nil
    @detected_rule_key = nil
    @rating_result = nil
    @reply = {}

    # Nothing to check    
    return false if build_info.blank? 

    @build_info = build_info
    
    # Device Detection
    @device = v4_match_bi_helper build_info, 'device'
    return false if @device.blank?
    
    # Platform Detection
    @platform = v4_match_bi_helper build_info, 'platform'
    unless @platform.blank?
      @device = specs_overlay 'platform', @device, @platform['Extra']
    end

    @reply['hd_specs'] = @device['Device']['hd_specs']
    set_error 0, "OK"
  end
  
  # buildInfo Match helper - Does the build info match heavy lifting
  #
  # +param+ hash buildInfo A buildInfo key/value array
  # +param+ string category - 'device' or 'platform' (cant match browser or app with buildinfo)
  # +return+ device or extra on success, false otherwise
  #
  def v4_match_bi_helper(build_info, category='device')
    # ***** Device Detection *****
    conf_bi_keys = @detection_config["#{category}-bi-order"]
    return nil if conf_bi_keys.blank? or build_info.blank? 

    hints = [] 
    conf_bi_keys.each do |platform, set|
      set.each do |tuple|
        checking = true
        value = ''
        tuple.each do |item|
          if item == 'hd-platform'
            value += "|#{platform}"
          elsif not build_info.include?(item)
            checking = false
            break
          else
            value += '|' + build_info[item]
          end
        end
        if checking
          value.gsub!(/^[| \t\n\r\0\x0B]*/, '')
          value.gsub!(/[| \t\n\r\0\x0B]*$/, '')
          hints << value
          subtree = (category == 'device') ? DETECTIONV4_STANDARD : category
          _id = get_match 'buildinfo', value, subtree, 'buildinfo', category
          unless _id.blank?
            return (category == 'device') ? (find_by_id _id) : (@extra.find_by_id _id)
          end
        end
      end
    end
    # If we get this far then not found, so try generic.
    platform = has_bi_keys build_info
    unless platform.blank?
      try = ["generic|#{platform}", "#{platform}|generic"]
      try.each do |value|
        subtree = (category == 'device') ? DETECTIONV4_GENERIC : category
        _id = get_match 'buildinfo', value, subtree, 'buildinfo', category
        unless _id.blank?
          return (category == 'device') ? (find_by_id _id) : (@extra.find_by_id _id)
        end
      end
    end
    nil
  end
  
  # Find the best device match for a given set of headers and optional device properties.
  #
  # In 'all' mode all conflicted devces will be returned as a list.
  # In 'default' mode if there is a conflict then the detected device is returned only (backwards compatible with v3).
  # 
  # +param+ hash headers Set of sanitized http headers
  # +param+ string hardwareInfo Information about the hardware
  # +return+ array device specs. (device.hd_specs)
  #
  def v4_match_http_headers(headers, hardware_info=nil) 
    @device = nil
    @platform = nil
    @browser = nil
    @app = nil
    @rating_result = nil
    @detected_rule_key = {} 
    @reply = {}
    hw_props = nil
    
    # Nothing to check    
    return false if headers.blank?

    headers.delete('ip')
    headers.delete('host')

    # Sanitize headers & cleanup language
    headers.each do |key, value|
      key = key.downcase
      if key == 'accept-language' or key == 'content-language'
        key = 'language'
        tmp = value.downcase.gsub(/ /, '').split(/[,;]/)
        unless tmp[0].blank?
          value = tmp[0]
        else
          next
        end
      elsif key != 'profile' and key != 'x-wap-profile'
        # Handle strings that have had + substituted for a space
        if value.count(' ') == 0 and value.count('+') > 5 and value.length > 20
          value.gsub!('+', ' ')
        end
      end
      @device_headers[key] = clean_str value 
      @extra_headers[key] = @extra.extra_clean_str value
    end

    @device = match_device @device_headers
    return set_error 301, "Not Found" if @device.blank? 

    unless hardware_info.blank?
      hw_props = info_string_to_hash hardware_info
    end

    # Stop on detect set - Tidy up and return
    if @device['Device']['hd_ops']['stop_on_detect'] == 1
      # Check for hardwareInfo overlay
      unless @device['Device']['hd_ops']['overlay_result_specs'].blank?
        @device = hardware_info_overlay(@device, hw_props)
      end
      @reply['hd_specs'] = @device['Device']['hd_specs']
      return set_error 0, "OK"
    end

    # Get extra info
    @platform = @extra.match_extra 'platform', @extra_headers
    @browser = @extra.match_extra 'browser', @extra_headers
    @app = @extra.match_extra 'app', @extra_headers
    @language = @extra.match_language @extra_headers

    # Find out if there is any contention on the detected rule.
    device_list = get_high_accuracy_candidates
    unless device_list.blank? 

      # Resolve contention with OS check
      @extra.set @platform
      pass1_list = [] 
      device_list.each do |_id| 
        try_device = find_by_id _id
        if @extra.verify_platform try_device['Device']['hd_specs']
          pass1_list << _id
        end
      end
      # Contention still not resolved .. check hardware
      if pass1_list.length >= 2 and (not hw_props.blank?)

        # Score the list based on hardware
        result = [] 
        pass1_list.each do |_id|
          tmp = find_rating _id, hw_props
          unless tmp.blank?
            tmp['_id'] = _id
            result << tmp
          end
        end

        # Sort the results
        result.sort! do |d1, d2| case
          when d2['score'].to_i - d1['score'].to_i != 0
            d2['score'].to_i - d1['score'].to_i
          else
            d1['distance'].to_i - d2['distance'].to_i
          end
        end
        @rating_result = result
        # Take the first one
        if @rating_result[0]['score'] != 0
          device = find_by_id result[0]['_id']
          unless device.blank?
            @device = device
          end
        end
      end
    end
    # Overlay specs
    @device = specs_overlay 'platform', @device, @platform['Extra'] if @platform
    @device = specs_overlay 'browser', @device, @browser['Extra'] if @browser
    @device = specs_overlay 'app', @device, @app['Extra'] if @app
    @device = specs_overlay 'language', @device, @language['Extra'] if @language

    # Overlay hardware info result if required
    unless @device['Device']['hd_ops']['overlay_result_specs'].blank? or hardware_info.blank?
      @device = hardware_info_overlay @device, hw_props
    end

    @reply['hd_specs'] = @device['Device']['hd_specs']
    set_error 0, "OK"
  end

  # Determines if high accuracy checks are available on the device which was just detected
  #
  # +param+ void
  # +return+ array, a list of candidate devices which have this detection rule or false otherwise.
  #
  def get_high_accuracy_candidates
    branch = get_branch 'hachecks'
    rule_key = @detected_rule_key['device']
    unless branch[rule_key].blank?
      return branch[rule_key]
    end
    false
  end
  
  # Determines if hd4Helper would provide more accurate results.
  #
  # +param+ hash headers HTTP Headers
  # +return+ true if required, false otherwise
  #
  def is_helper_useful(headers)
    return false if headers.blank?

    headers.delete('ip')
    headers.delete('host')

    tmp = local_detect(headers)
    return false if tmp.blank?

    tmp = get_high_accuracy_candidates
    return false if tmp.blank?

    true
  end
end
