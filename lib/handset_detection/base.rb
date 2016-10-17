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

require 'active_support/core_ext/object/blank'
require 'json'
require 'digest/md5'
require 'socket'
require 'tcp_timeout'
require 'uri'

DETECTIONV4_STANDARD = 0
DETECTIONV4_GENERIC = 1

class Base
  def initialize
    @config = {} 
    @api_base = '/apiv4/'
    @detected_rule_key = {} 
    @device_ua_filter = /[ _\\#\-,.\/:"']/
    @extra_ua_filter = /[ ]/
    @apikit = 'Ruby 4.0.0'
    @logger_host = 'logger.handsetdetection.com'
    @logger_port = 80
    @reply = {}
    @tree = {}
    @detection_config = { 
      'device-ua-order' => ['x-operamini-phone-ua', 'x-mobile-ua', 'device-stock-ua', 'user-agent', 'agent'],
      'platform-ua-order' => ['x-operamini-phone-ua', 'x-mobile-ua', 'device-stock-ua', 'user-agent', 'agent'],
      'browser-ua-order' => ['user-agent', 'agent', 'device-stock-ua'],
      'app-ua-order' => ['user-agent', 'agent', 'device-stock-ua'],
      'language-ua-order' => ['user-agent', 'agent', 'device-stock-ua'],
      'device-bi-order' => { 
        'android' => [ 
          ['ro.product.brand','ro.product.model'],
          ['ro.product.manufacturer','ro.product.model'],
          ['ro-product-brand','ro-product-model'],
          ['ro-product-manufacturer','ro-product-model'],
        ],
        'ios' => [ 
          ['utsname.brand','utsname.machine']
        ],
        'windows phone' => [ 
          ['devicemanufacturer','devicename']
        ]
      },
      'platform-bi-order' => {
        'android' => [ 
          ['ro.build.id', 'ro.build.version.release'],
          ['ro-build-id', 'ro-build-version-release'],
        ],
        'ios' => [ 
          ['uidevice.systemName','uidevice.systemversion']
        ],
        'windows phone' => [ 
          ['osname','osversion']
        ]
      },
      'browser-bi-order' => [],
      'app-bi-order' => [] 
    }
    @detection_languages = { 
      'af' => 'Afrikaans',
      'sq' => 'Albanian',
      'ar-dz' => 'Arabic (Algeria)',
      'ar-bh' => 'Arabic (Bahrain)',
      'ar-eg' => 'Arabic (Egypt)',
      'ar-iq' => 'Arabic (Iraq)',
      'ar-jo' => 'Arabic (Jordan)',
      'ar-kw' => 'Arabic (Kuwait)',
      'ar-lb' => 'Arabic (Lebanon)',
      'ar-ly' => 'Arabic (libya)',
      'ar-ma' => 'Arabic (Morocco)',
      'ar-om' => 'Arabic (Oman)',
      'ar-qa' => 'Arabic (Qatar)',
      'ar-sa' => 'Arabic (Saudi Arabia)',
      'ar-sy' => 'Arabic (Syria)',
      'ar-tn' => 'Arabic (Tunisia)',
      'ar-ae' => 'Arabic (U.A.E.)',
      'ar-ye' => 'Arabic (Yemen)',
      'ar' => 'Arabic',
      'hy' => 'Armenian',
      'as' => 'Assamese',
      'az' => 'Azeri',
      'eu' => 'Basque',
      'be' => 'Belarusian',
      'bn' => 'Bengali',
      'bg' => 'Bulgarian',
      'ca' => 'Catalan',
      'zh-cn' => 'Chinese (China)',
      'zh-hk' => 'Chinese (Hong Kong SAR)',
      'zh-mo' => 'Chinese (Macau SAR)',
      'zh-sg' => 'Chinese (Singapore)',
      'zh-tw' => 'Chinese (Taiwan)',
      'zh' => 'Chinese',
      'hr' => 'Croatian',
      'cs' => 'Czech',
      'da' => 'Danish',
      'da-dk' => 'Danish',
      'div' => 'Divehi',
      'nl-be' => 'Dutch (Belgium)',
      'nl' => 'Dutch (Netherlands)',
      'en-au' => 'English (Australia)',
      'en-bz' => 'English (Belize)',
      'en-ca' => 'English (Canada)',
      'en-ie' => 'English (Ireland)',
      'en-jm' => 'English (Jamaica)',
      'en-nz' => 'English (New Zealand)',
      'en-ph' => 'English (Philippines)',
      'en-za' => 'English (South Africa)',
      'en-tt' => 'English (Trinidad)',
      'en-gb' => 'English (United Kingdom)',
      'en-us' => 'English (United States)',
      'en-zw' => 'English (Zimbabwe)',
      'en' => 'English',
      'us' => 'English (United States)',
      'et' => 'Estonian',
      'fo' => 'Faeroese',
      'fa' => 'Farsi',
      'fi' => 'Finnish',
      'fr-be' => 'French (Belgium)',
      'fr-ca' => 'French (Canada)',
      'fr-lu' => 'French (Luxembourg)',
      'fr-mc' => 'French (Monaco)',
      'fr-ch' => 'French (Switzerland)',
      'fr' => 'French (France)',
      'mk' => 'FYRO Macedonian',
      'gd' => 'Gaelic',
      'ka' => 'Georgian',
      'de-at' => 'German (Austria)',
      'de-li' => 'German (Liechtenstein)',
      'de-lu' => 'German (Luxembourg)',
      'de-ch' => 'German (Switzerland)',
      'de-de' => 'German (Germany)',
      'de' => 'German (Germany)',
      'el' => 'Greek',
      'gu' => 'Gujarati',
      'he' => 'Hebrew',
      'hi' => 'Hindi',
      'hu' => 'Hungarian',
      'is' => 'Icelandic',
      'id' => 'Indonesian',
      'it-ch' => 'Italian (Switzerland)',
      'it' => 'Italian (Italy)',
      'it-it' => 'Italian (Italy)',
      'ja' => 'Japanese',
      'kn' => 'Kannada',
      'kk' => 'Kazakh',
      'kok' => 'Konkani',
      'ko' => 'Korean',
      'kz' => 'Kyrgyz',
      'lv' => 'Latvian',
      'lt' => 'Lithuanian',
      'ms' => 'Malay',
      'ml' => 'Malayalam',
      'mt' => 'Maltese',
      'mr' => 'Marathi',
      'mn' => 'Mongolian (Cyrillic)',
      'ne' => 'Nepali (India)',
      'nb-no' => 'Norwegian (Bokmal)',
      'nn-no' => 'Norwegian (Nynorsk)',
      'no' => 'Norwegian (Bokmal)',
      'or' => 'Oriya',
      'pl' => 'Polish',
      'pt-br' => 'Portuguese (Brazil)',
      'pt' => 'Portuguese (Portugal)',
      'pa' => 'Punjabi',
      'rm' => 'Rhaeto-Romanic',
      'ro-md' => 'Romanian (Moldova)',
      'ro' => 'Romanian',
      'ru-md' => 'Russian (Moldova)',
      'ru' => 'Russian',
      'sa' => 'Sanskrit',
      'sr' => 'Serbian',
      'sk' => 'Slovak',
      'ls' => 'Slovenian',
      'sb' => 'Sorbian',
      'es-ar' => 'Spanish (Argentina)',
      'es-bo' => 'Spanish (Bolivia)',
      'es-cl' => 'Spanish (Chile)',
      'es-co' => 'Spanish (Colombia)',
      'es-cr' => 'Spanish (Costa Rica)',
      'es-do' => 'Spanish (Dominican Republic)',
      'es-ec' => 'Spanish (Ecuador)',
      'es-sv' => 'Spanish (El Salvador)',
      'es-gt' => 'Spanish (Guatemala)',
      'es-hn' => 'Spanish (Honduras)',
      'es-mx' => 'Spanish (Mexico)',
      'es-ni' => 'Spanish (Nicaragua)',
      'es-pa' => 'Spanish (Panama)',
      'es-py' => 'Spanish (Paraguay)',
      'es-pe' => 'Spanish (Peru)',
      'es-pr' => 'Spanish (Puerto Rico)',
      'es-us' => 'Spanish (United States)',
      'es-uy' => 'Spanish (Uruguay)',
      'es-ve' => 'Spanish (Venezuela)',
      'es' => 'Spanish (Traditional Sort)',
      'es-es' => 'Spanish (Traditional Sort)',
      'sx' => 'Sutu',
      'sw' => 'Swahili',
      'sv-fi' => 'Swedish (Finland)',
      'sv' => 'Swedish',
      'syr' => 'Syriac',
      'ta' => 'Tamil',
      'tt' => 'Tatar',
      'te' => 'Telugu',
      'th' => 'Thai',
      'ts' => 'Tsonga',
      'tn' => 'Tswana',
      'tr' => 'Turkish',
      'uk' => 'Ukrainian',
      'ur' => 'Urdu',
      'uz' => 'Uzbek',
      'vi' => 'Vietnamese',
      'xh' => 'Xhosa',
      'yi' => 'Yiddish',
      'zu' => 'Zulu'
    }
  end

  # Get reply status
  #
  # +param+ void 
  # +return+ int error status, 0 is Ok, anything else is probably not Ok 
  #
  def get_status
    @reply['status']
  end

  # Get reply message
  # 
  # +param+ void
  # +return+ string A message
  #
  def get_message
    @reply['message']
  end

  # Get reply payload in array assoc format
  #
  # +param+ void
  # +return+ array
  #
  def get_reply
    @reply
  end

  # Set a reply payload
  #
  # +param+ array reply
  # +return+ void
  #
  def set_reply(reply)
    @reply = reply
  end 

  # Error handling helper. Sets a message and an error code.
  #
  # +param+ int status
  # +param+ string msg
  # +return+ true if no error, or false otherwise.
  #
  def set_error(status, msg)
    @error = msg
    @reply['status'] = status
    @reply['message'] = msg
    status == 0
  end 
  
  # String cleanse for extras matching.
  #
  # +param+ string str
  # +return+ string Cleansed string
  #
  def extra_clean_str(str)
    str = str.downcase.gsub @extra_ua_filter, ''
    str = str.gsub(/[^\x20-\x7F]/, '')
    str.strip
  end

  # Standard string cleanse for device matching
  #
  # +param+ string str
  # +return+ string cleansed string
  #
  def clean_str(str)
    str = str.downcase.gsub @device_ua_filter, ''
    str = str.gsub(/[^\x20-\x7F]/, '')
    str.strip
  end
  
  # Log function - User defined functions can be supplied in the 'logger' config variable.
  #
  def log(msg)
    Syslog.log(Syslog::LOG_NOTICE, "#{Time.now.to_f} #{msg}")
    if @config.key?('logger') and @config['logger'].is_a?(Proc)
      @config['logger'].call(msg)
    end
  end
  
  # Makes requests to the various web services of Handset Detection.
  #
  # Note : suburl - the url fragment of the web service eg site/detect/${site_id}
  #
  # +param+ string suburl
  # +param+ string data
  # +param+ string filetype
  # +param+ boolean auth_required - Is authentication required ?
  # +return+ bool true on success, false otherwise
  #
  def remote(suburl, data, filetype='json', auth_required=true)
    @reply = {} 
    @raw_reply = {} 
    set_error 0, ''

    if data.blank?
      data = [] 
    end

    url = @api_base + suburl
    attempts = @config['retries'] + 1
    trys = 0

    requestdata = JSON.generate(data) 

    success = false
    while (trys+=1) < attempts and success == false
      @raw_reply = post @config['api_server'], url, requestdata, auth_required
      if @raw_reply == false
        set_error 299, "Error : Connection to #{url} failed"
      elsif
        if filetype == 'json'
          @reply = JSON.parse @raw_reply

          if @reply.blank?
            set_error 299, "Error : Empty Reply."
          elsif not @reply.key? 'status'
            set_error 299, "Error : No status set in reply"
          elsif @reply['status'].to_i != 0
            set_error @reply['status'], @reply['message']
            trys = attempts + 1
          else
            success = true
          end
        else
          success = true
        end
      end
    end
    success
  end

  # Post data to remote server
  #
  # Modified version of PHP Post from From http://www.enyem.com/wiki/index.php/Send_POST_request_(PHP)
  # Thanks dude !
  #
  # +param+ string server Server name
  # +param+ string url URL name
  # +param+ string jsondata Data in json format
  # +param+ boolean auth_required Is suthentication reguired ?
  # +return+ false on failue (sets error), or string on success.
  #
  def post(server, url, jsondata, auth_required=true)
    host = server
    port = 80
    uri = URI.parse url.gsub(/ /, '%20')
    realm = @realm
    username =@config['username']
    nc = "00000001"
    snonce = @realm
    cnonce = Digest::MD5.hexdigest Time.now.to_i.to_s + @config['secret']
    qop = 'auth'

    if @config['use_proxy']
      host = @config['proxy_server']
      port = @config['proxy_port']
    end

    # AuthDigest Components
    # http://en.wikipedia.org/wiki/Digest_access_authentication
    ha1 = Digest::MD5.hexdigest username + ':' + realm + ':' + @config['secret']
    ha2 = Digest::MD5.hexdigest 'POST:' + uri.path
    response = Digest::MD5.hexdigest ha1 + ':' + snonce  + ':' + nc + ':' + cnonce + ':' + qop + ':' + ha2

    out = "POST #{url} HTTP/1.0\r\n"
    out += "Host: #{server}\r\n"
    if @config['use_proxy'] and not @config['proxy_user'].blank? and not @config['proxy_pass'].blank?
      out += "Proxy-Authorization:Basic " + base64_encode(@config['proxy_user'] + ':' + @config['proxy_pass']) + "\r\n"
    end
    out += "Content-Type: application/json\r\n"
    # Pre-computed auth credentials, saves waiting for the auth challenge hence makes things round trip time 50% faster.
    if auth_required
      out += 'Authorization: Digest ' +
        'username="' + username + '", ' +
        'realm="' + realm + '", ' +
        'nonce="' + snonce + '", ' +
        'uri="' + uri.path + '", ' +
        'qop=' + qop + ', ' +
        'nc=' + nc + ', ' + 
        'cnonce="' + cnonce + '", ' +
        'response="' + response + '", ' +
        'opaque="' + realm + '"' + 
        "\r\n"
    end
    out += "Content-length: " + jsondata.length.to_s + "\r\n\r\n"
    out += jsondata + "\r\n\r\n"

    socket = nil
    begin
      socket = TCPTimeout::TCPSocket.new(host, port, 
        connect_timeout: @config['timeout'], read_timeout: @config['timeout'], write_timeout: @config['timeout'])
      socket.write(out)
      reply = socket.read 1000000000 
    rescue SocketError => e
      return set_error 299, e.to_s 
    ensure
      socket.close unless socket.nil?
    end
    hunks = reply.split("\r\n\r\n")
    return set_error(299, "Error : Reply is too short.") if hunks.length < 2 
    # header = hunks[hunks.length - 2]
    # headers = header.split("\n")
    body = hunks[hunks.length - 1]
    return set_error(299, "Error : Reply body is empty.") if body.blank?
    body
  end

  # Helper for determining if a header has BiKeys
  #
  # +param+ hash header
  # +return+ platform name on success, false otherwise
  #
  def has_bi_keys(headers)
    bi_keys = @detection_config['device-bi-order']
    data_keys = {}
    headers.each { |k, v| data_keys[k.downcase] = v }

    # Fast check
    return false if headers.key? 'agent'
    return false if headers.key? 'user-agent'
    bi_keys.each do |platform, s|
      s.each do |tuple|
        count = 0
        total = tuple.length
        tuple.each do |item|
          count += 1 if data_keys.include? item
          return platform if count == total
        end
      end
    end
    false
  end

  # The heart of the detection process
  #
  # +param+ string header The type of header we're matching against - user-agent type headers use a sieve matching, all others are hash matching.
  # +param+ string newvalue The http header's value (could be a user-agent or some other x- header value)
  # +param+ string treetag The branch name eg : user-agent0, user-agent1, user-agentplatform, user-agentbrowser
  # +return+ int node (which is an id) on success, false otherwise
  #
  def get_match(header, value, subtree="0", actual_header='', cls='device')
    f = 0
    r = 0
    if cls == 'device'
      value = clean_str value
    else
      value = extra_clean_str value
    end
    treetag = "#{header}#{subtree}"

    return false if value.length < 4

    branch = get_branch treetag
    return false if branch.blank?
    if header == 'user-agent'
      # Sieve matching strategy
      branch.each do |order, filters|
        filters.each do |filter, matches|
          f += 1
          if value.include? filter
            matches.each do |match, node|
              r += 1
              if value.include? match
                @detected_rule_key[cls] = clean_str(header) + ':' + clean_str(filter) + ':' + clean_str(match)
                return node
              end
            end
          end
        end
      end
    else
      # Hash matching strategy
      unless branch[value].blank?
        node = branch[value]
        return node
      end
    end
    false
  end

  # Find a branch for the matching process
  #
  # +param+ string branch The name of the branch to find
  # +return+ an assoc array on success, false otherwise.
  #
  def get_branch(branch)
    return @tree[branch] unless @tree[branch].blank?
    tmp = @store.read branch
    if tmp != false
      @tree[branch] = tmp
      return tmp
    end
    false
  end

  # UDP Syslog via https://gist.github.com/troy/2220679 - Thanks Troy
  #
  # Send a message via UDP, used if log_unknown is set in config && running in Ultimate (local) mode.
  #
  # +param+ array $headers
  # +return+ void
  #
  def send_remote_syslog(headers)
    headers['version'] = RUBY_VERSION 
    headers['apikit'] = @apikit
    sock = UDPSocket.new(Socket::AF_INET)
    message = JSON.generate headers
    sock.send '<22> ' + message, 0, @logger_host, @logger_port
    sock.close
  end
end
