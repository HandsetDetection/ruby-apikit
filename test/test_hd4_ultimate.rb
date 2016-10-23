require 'minitest/autorun'
require 'minitest/hooks/test'
require 'handset_detection'
require 'fileutils'

class HD4UltimateTest < Minitest::Test 
  include Minitest::Hooks

  def before_all
    super
    @config = YAML::load_file 'hd4_ci_config.yml'
    Dir.mkdir '/tmp/hd4-ultimate-test' unless File.exist?('/tmp/hd4-ultimate-test')
    @config['filesdir'] = '/tmp/hd4-ultimate-test'
    @config['cache'] = {'prefix' => 'hd4-ultimate-test'}
    @config['use_local'] = true 
    hd = HD4.new @config
    hd.set_timeout 500
    Store::get_instance.purge
    hd.device_fetch_archive
  end

  def after_all
    super
    FileUtils.rm_r '/tmp/hd4-ultimate-test'
  end

  def setup 
    @hd = HD4.new @config
  end

  def teardown
    @hd.cache.purge
  end

  # Fetch Archive test
  #
  def test_fetch_archive
    data = File.read File.join(@hd.get_files_dir, "ultimate.zip") 
    assert data.length > 19000000  # Filesize greater than 19Mb (currently 28Mb).
  end

  # device vendors test
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_vendors
    result = @hd.device_vendors
    reply = @hd.get_reply

    assert result
    assert_equal 0, reply['status']
    assert_equal 'OK', reply['message']
    assert reply['vendor'].include? 'Nokia'
    assert reply['vendor'].include? 'Samsung'
  end

  # device models test
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_models
    reply = @hd.device_models 'Nokia'
    data = @hd.get_reply

    assert_equal reply, true
    assert data['model'].length > 700
    assert_equal 0, data['status']
    assert_equal 'OK', data['message']
  end

  # device view test
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_view
    devices = { 
      'NokiaN95' => { 
        'general_vendor' => 'Nokia',
        'general_model' => 'N95',
        'general_platform' => 'Symbian',
        'general_platform_version' => '9.2',
        'general_platform_version_max' => '',
        'general_browser' => '',
        'general_browser_version' => '',
        'general_image' => 'nokian95-1403496370-0.gif',
        'general_aliases' => [],
        'general_app' => '',
        'general_app_category' => '',
        'general_app_version' => '',
        'general_language' => '',
        'general_eusar' => '0.50',
        'general_battery' => ['Li-Ion 950 mAh', 'BL-5F'],
        'general_type' => 'Mobile',
        'general_cpu' => ['Dual ARM 11', '332Mhz'],
        'general_virtual' => 0,
        'design_formfactor' => 'Dual Slide',
        'design_dimensions' => '99 x 53 x 21',
        'design_weight' => '120',
        'design_antenna' => 'Internal',
        'design_keyboard' => 'Numeric',
        'design_softkeys' => '2',
        'design_sidekeys' => ['Volume', 'Camera'],
        'display_type' => 'TFT',
        'display_color' => 'Yes',
        'display_colors' => '16M',
        'display_css_screen_sizes' => ['240x320'],
        'display_size' => '2.6"',
        'display_x' => '240',
        'display_y' => '320',
        'display_other' => [],
        'display_pixel_ratio' => '1.0',
        'display_ppi' => 154,
        'memory_internal' => ['160MB', '64MB RAM', '256MB ROM'],
        'memory_slot' => ['microSD', '8GB', '128MB'],
        'network' => ['GSM850', 'GSM900', 'GSM1800', 'GSM1900', 'UMTS2100', 'HSDPA2100', 'Infrared', 'Bluetooth 2.0', '802.11b', '802.11g', 'GPRS Class 10', 'EDGE Class 32'],
        'media_camera' => ['5MP', '2592x1944'],
        'media_secondcamera' => ['QVGA'],
        'media_videocapture' => ['VGA@30fps'],
        'media_videoplayback' => ['MPEG4', 'H.263', 'H.264', '3GPP', 'RealVideo 8', 'RealVideo 9', 'RealVideo 10'],
        'media_audio' => ['MP3', 'AAC', 'AAC+', 'eAAC+', 'WMA'],
        'media_other' => ['Auto focus', 'Video stabilizer', 'Video calling', 'Carl Zeiss optics', 'LED Flash'],
        'features' => [ 
          'Unlimited entries', 'Multiple numbers per contact', 'Picture ID', 'Ring ID', 'Calendar', 'Alarm', 'To-Do', 'Document viewer',
          'Calculator', 'Notes', 'UPnP', 'Computer sync', 'VoIP', 'Music ringtones (MP3)', 'Vibration', 'Phone profiles', 'Speakerphone',
          'Accelerometer', 'Voice dialing', 'Voice commands', 'Voice recording', 'Push-to-Talk', 'SMS', 'MMS', 'Email', 'Instant Messaging',
          'Stereo FM radio', 'Visual radio', 'Dual slide design', 'Organizer', 'Word viewer', 'Excel viewer', 'PowerPoint viewer', 'PDF viewer',
          'Predictive text input', 'Push to talk', 'Voice memo', 'Games'
        ],
        'connectors' => ['USB', 'miniUSB', '3.5mm AUdio', 'TV Out'],
        'benchmark_max' => 0,
        'benchmark_min' => 0
      }
    }
    reply = @hd.device_view 'Nokia', 'N95'
    data = @hd.get_reply
    assert_equal reply, true
    assert_equal 0, data['status']
    assert_equal 'OK', data['message']
    data['device'] = data['device'].sort
    data['device'] = Hash[*data['device'][0].zip(data['device'][1]).flatten]
    devices['NokiaN95'] = devices['NokiaN95'].sort
    devices['NokiaN95'] = Hash[*devices['NokiaN95'][0].zip(devices['NokiaN95'][1]).flatten]

    assert_equal JSON.generate(devices['NokiaN95']).downcase, JSON.generate(data['device']).downcase
  end

  # device whatHas test
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_what_has
    reply = @hd.device_what_has 'design_dimensions', '101 x 44 x 16'
    data = @hd.get_reply
    assert_equal reply, true
    assert_equal 0, data['status']
    assert_equal 'OK', data['message']
    json_string = JSON.generate(data['devices'])
    assert(/Asus/.match(json_string))
    assert(/V80/.match(json_string))
    assert(/Spice/.match(json_string))
    assert(/S900/.match(json_string))
    assert(/Voxtel/.match(json_string))
    assert(/RX800/.match(json_string))
  end

  # Windows PC running Chrome
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_http_desktop
    headers = { 
      'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 0, reply['status']
    assert_equal 'OK', reply['message']
    assert_equal 'Computer', reply['hd_specs']['general_type']
  end

  # Junk user-agent
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_http_desktop_junk
    headers = { 
      'User-Agent' => 'aksjakdjkjdaiwdidjkjdkawjdijwidawjdiajwdkawdjiwjdiawjdwidjwakdjajdkad' + Time.now.to_i.to_s
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    refute result
    assert_equal 301, reply['status']
    assert_equal 'Not Found', reply['message']
  end

  # Wii
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_http_wii
    headers = { 
      'User-Agent' => 'Opera/9.30 (Nintendo Wii; U; ; 2047-7; es-Es)'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 0, reply['status']
    assert_equal 'OK', reply['message']
    assert_equal 'Console', reply['hd_specs']['general_type']
  end

  # iPhone
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_http
    headers = { 
      'User-Agent' => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3 like Mac OS X; en-gb) AppleWebKit/533.17.9 (KHTML, like Gecko)'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 0, reply['status']
    assert_equal 'OK', reply['message']
    assert_equal 'Mobile', reply['hd_specs']['general_type']
    assert_equal 'Apple', reply['hd_specs']['general_vendor']
    assert_equal 'iPhone', reply['hd_specs']['general_model']
    assert_equal 'iOS', reply['hd_specs']['general_platform']
    assert_equal '4.3', reply['hd_specs']['general_platform_version']
    assert_equal 'en-gb', reply['hd_specs']['general_language']
    assert_equal 'Mobile', reply['hd_specs']['general_type']
    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # iPhone - user-agent in random other header
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_http_other_header
    headers = { 
      'user-agent' => 'blahblahblah',
      'x-fish-header' => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3 like Mac OS X; en-gb) AppleWebKit/533.17.9 (KHTML, like Gecko)'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 0, reply['status']
    assert_equal 'OK', reply['message']
    assert_equal 'Mobile', reply['hd_specs']['general_type']
    assert_equal 'Apple', reply['hd_specs']['general_vendor']
    assert_equal 'iPhone', reply['hd_specs']['general_model']
    assert_equal 'iOS', reply['hd_specs']['general_platform']
    assert_equal '4.3', reply['hd_specs']['general_platform_version']
    assert_equal 'en-gb', reply['hd_specs']['general_language']
    assert_equal 'Mobile', reply['hd_specs']['general_type']
    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # iPhone 3GS (same UA as iPhone 3G, different x-local-hardwareinfo header)
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_http_hardware_info
    headers = { 
      'user-agent' => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_2_1 like Mac OS X; en-gb) AppleWebKit/533.17.9 (KHTML, like Gecko)',
      'x-local-hardwareinfo' => '320:480:100:100'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 'Apple', reply['hd_specs']['general_vendor']
    assert_equal 'iPhone 3GS', reply['hd_specs']['general_model']
    assert_equal 'iOS', reply['hd_specs']['general_platform']
    assert_equal '4.2.1', reply['hd_specs']['general_platform_version']
    assert_equal 'en-gb', reply['hd_specs']['general_language']
    assert_equal 'Mobile', reply['hd_specs']['general_type']
    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # iPhone 3G (same UA as iPhone 3GS, different x-local-hardwareinfo header)
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_http_hardware_info_b
    headers = { 
      'user-agent' => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_2_1 like Mac OS X; en-gb) AppleWebKit/533.17.9 (KHTML, like Gecko)',
      'x-local-hardwareinfo' => '320:480:100:72'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 'Apple', reply['hd_specs']['general_vendor']
    assert_equal 'iPhone 3G', reply['hd_specs']['general_model']
    assert_equal 'iOS', reply['hd_specs']['general_platform']
    assert_equal '4.2.1', reply['hd_specs']['general_platform_version']
    assert_equal 'en-gb', reply['hd_specs']['general_language']
    assert_equal 'Mobile', reply['hd_specs']['general_type']
    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # iPhone - Crazy benchmark (eg from emulated desktop) with outdated OS
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_http_hardware_info_c
    headers = { 
      'user-agent' => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 2_0 like Mac OS X; en-gb) AppleWebKit/533.17.9 (KHTML, like Gecko)',
      'x-local-hardwareinfo' => '320:480:200:1200',
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 'Apple', reply['hd_specs']['general_vendor']
    assert_equal 'iPhone 3G', reply['hd_specs']['general_model']
    assert_equal 'iOS', reply['hd_specs']['general_platform']
    assert_equal '2.0', reply['hd_specs']['general_platform_version']
    assert_equal 'en-gb', reply['hd_specs']['general_language']
    assert_equal 'Mobile', reply['hd_specs']['general_type']
    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # iPhone 5s running Facebook 9.0 app (hence no general_browser set).
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_http_fb_ios

    headers = { 
      'user-agent' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_1 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Mobile/11D201 [FBAN/FBIOS;FBAV/9.0.0.25.31;FBBV/2102024;FBDV/iPhone6,2;FBMD/iPhone;FBSN/iPhone OS;FBSV/7.1.1;FBSS/2; FBCR/vodafoneIE;FBID/phone;FBLC/en_US;FBOP/5]',
      'Accept-Language' => 'da, en-gb;q=0.8, en;q=0.7'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 'Apple', reply['hd_specs']['general_vendor']
    assert_equal 'iPhone 5S', reply['hd_specs']['general_model']
    assert_equal 'iOS', reply['hd_specs']['general_platform']
    assert_equal '7.1.1', reply['hd_specs']['general_platform_version']
    assert_equal 'da', reply['hd_specs']['general_language']
    assert_equal 'Danish', reply['hd_specs']['general_language_full']
    assert_equal 'Mobile', reply['hd_specs']['general_type']
    assert_equal 'Facebook', reply['hd_specs']['general_app']
    assert_equal '9.0', reply['hd_specs']['general_app_version']
    assert_equal '', reply['hd_specs']['general_browser']
    assert_equal '', reply['hd_specs']['general_browser_version']

    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # Samsung GT-I9500 Native - Note : Device shipped with Android 4.2.2, so this device has been updated.
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_bi_android
    build_info = { 
      'ro.build.PDA' => 'I9500XXUFNE7',
      'ro.build.changelist' => '699287',
      'ro.build.characteristics' => 'phone',
      'ro.build.date.utc' => '1401287026',
      'ro.build.date' => 'Wed May 28 23:23:46 KST 2014',
      'ro.build.description' => 'ja3gxx-user 4.4.2 KOT49H I9500XXUFNE7 release-keys',
      'ro.build.display.id' => 'KOT49H.I9500XXUFNE7',
      'ro.build.fingerprint' => 'samsung/ja3gxx/ja3g:4.4.2/KOT49H/I9500XXUFNE7:user/release-keys',
      'ro.build.hidden_ver' => 'I9500XXUFNE7',
      'ro.build.host' => 'SWDD5723',
      'ro.build.id' => 'KOT49H',
      'ro.build.product' => 'ja3g',
      'ro.build.tags' => 'release-keys',
      'ro.build.type' => 'user',
      'ro.build.user' => 'dpi',
      'ro.build.version.codename' => 'REL',
      'ro.build.version.incremental' => 'I9500XXUFNE7',
      'ro.build.version.release' => '4.4.2',
      'ro.build.version.sdk' => '19',
      'ro.product.board' => 'universal5410',
      'ro.product.brand' => 'samsung',
      'ro.product.cpu.abi2' => 'armeabi',
      'ro.product.cpu.abi' => 'armeabi-v7a',
      'ro.product.device' => 'ja3g',
      'ro.product.locale.language' => 'en',
      'ro.product.locale.region' => 'GB',
      'ro.product.manufacturer' => 'samsung',
      'ro.product.model' => 'GT-I9500',
      'ro.product.name' => 'ja3gxx',
      'ro.product_ship' => 'true'
    }

    @hd.device_detect(build_info)
    reply = @hd.get_reply

    assert_equal 'Samsung', reply['hd_specs']['general_vendor']
    assert_equal 'GT-I9500', reply['hd_specs']['general_model']
    assert_equal 'Android', reply['hd_specs']['general_platform']
    assert_equal 'Samsung Galaxy S4', reply['hd_specs']['general_aliases'][0]
    assert_equal 'Mobile', reply['hd_specs']['general_type']
  end

  # iPhone 4S Native
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_bi_ios
    build_info = { 
      'utsname.machine' => 'iphone4,1',
      'utsname.brand' => 'Apple'
    }

    @hd.device_detect(build_info)
    reply = @hd.get_reply

    assert_equal 'Apple', reply['hd_specs']['general_vendor']
    assert_equal 'iPhone 4S', reply['hd_specs']['general_model']
    assert_equal 'iOS', reply['hd_specs']['general_platform']
    # Note : Default shipped version in the absence of any version information
    assert_equal '5.0', reply['hd_specs']['general_platform_version']
    assert_equal 'Mobile', reply['hd_specs']['general_type']
  end

  # Windows Phone Native Nokia Lumia 1020
  # @depends test_fetchArchive
  # @group ultimate
  #
  def test_ultimate_device_detect_windows_phone
    build_info = { 
      'devicemanufacturer' => 'nokia',
      'devicename' => 'RM-875'
    }

    @hd.device_detect(build_info)
    reply = @hd.get_reply

    assert_equal 'Nokia', reply['hd_specs']['general_vendor']
    assert_equal 'Lumia 1020', reply['hd_specs']['general_model']
    assert_equal 'Windows Phone', reply['hd_specs']['general_platform']
    assert_equal 'Mobile', reply['hd_specs']['general_type']
    assert_equal 332, reply['hd_specs']['display_ppi']
  end
end
