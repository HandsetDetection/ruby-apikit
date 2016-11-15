require 'minitest/autorun'
require 'minitest/hooks/test'
require 'handset_detection'
require 'fileutils'

class HD4CommunityTest < Minitest::Test
  include Minitest::Hooks

  def before_all
    super
    @config = YAML::load_file 'hd4_ci_config.yml'
    Dir.mkdir '/tmp/hd4-community-test' unless File.exist?('/tmp/hd4-community-test')
    @config['filesdir'] = '/tmp/hd4-community-test'
    @config['cache'] = {'prefix' => 'hd4-community-test'}
    @config['use_local'] = true
    hd = HD4.new @config
    hd.set_timeout 500
    Store::get_instance.purge
    hd.community_fetch_archive
  end

  def after_all
    super
    FileUtils.rm_r '/tmp/hd4-community-test'
  end

  def setup
    @hd = HD4.new @config
  end

  def teardown
    @hd.cache.purge
  end

  # Fetch Archive Test
  #
  # The community fetchArchive version contains a cut down version of the device specs.
  # It has general_vendor, general_model, display_x, display_y, general_platform, general_platform_version,
  # general_browser, general_browser_version, general_app, general_app_version, general_language,
  # general_language_full, benahmark_min & benchmark_max
  #
  # @group community
  #
  def test_ultimate_community_fetch_archive
    data = File.read File.join(@hd.get_files_dir, "communityultimate.zip")
    assert data.length > 9000000  # Filesize greater than 9Mb
  end

  # Windows PC running Chrome
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_http_desktop
    headers = {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 0, reply['status']
    assert_equal 'OK', reply['message']
    assert_equal '', reply['hd_specs']['general_type']
  end

  # Junk user-agent
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_http_desktop_junk
    headers = {
      'User-Agent' => 'aksjakdjkjdaiwdidjkjdkawjdijwidawjdiajwdkawdjiwjdiawjdwidjwakdjajdkad'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    refute result
    assert_equal 301, reply['status']
    assert_equal 'Not Found', reply['message']
  end

  # Wii
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_http_wii
    headers = {
      'User-Agent' => 'Opera/9.30 (Nintendo Wii; U; ; 2047-7; es-Es)'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 0, reply['status']
    assert_equal 'OK', reply['message']
    assert_equal '', reply['hd_specs']['general_type']
  end

  # iPhone
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_http
    headers = {
      'User-Agent' => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3 like Mac OS X; en-gb) AppleWebKit/533.17.9 (KHTML, like Gecko)'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 0, reply['status']
    assert_equal 'OK', reply['message']
    assert_equal '', reply['hd_specs']['general_type']
    assert_equal 'Apple', reply['hd_specs']['general_vendor']
    assert_equal 'iPhone', reply['hd_specs']['general_model']
    assert_equal 'iOS', reply['hd_specs']['general_platform']
    assert_equal '4.3', reply['hd_specs']['general_platform_version']
    assert_equal 'en-gb', reply['hd_specs']['general_language']
    assert_equal '', reply['hd_specs']['general_type']
    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # iPhone - user-agent in random other header
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_http_other_header
    headers = {
      'user-agent' => 'blahblahblah',
      'x-fish-header' => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3 like Mac OS X; en-gb) AppleWebKit/533.17.9 (KHTML, like Gecko)'
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 0, reply['status']
    assert_equal 'OK', reply['message']
    assert_equal '', reply['hd_specs']['general_type']
    assert_equal 'Apple', reply['hd_specs']['general_vendor']
    assert_equal 'iPhone', reply['hd_specs']['general_model']
    assert_equal 'iOS', reply['hd_specs']['general_platform']
    assert_equal '4.3', reply['hd_specs']['general_platform_version']
    assert_equal 'en-gb', reply['hd_specs']['general_language']
    assert_equal '', reply['hd_specs']['general_type']
    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # iPhone 3GS (same UA as iPhone 3G, different x-local-hardwareinfo header)
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_http_hardware_info
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
    assert_equal '', reply['hd_specs']['general_type']
    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # iPhone 3G (same UA as iPhone 3GS, different x-local-hardwareinfo header)
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_http_hardware_info_b
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
    assert_equal '', reply['hd_specs']['general_type']
    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # iPhone - Crazy benchmark (eg from emulated desktop) with outdated OS
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_http_hardware_info_c
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
    assert_equal '', reply['hd_specs']['general_type']
    assert reply['hd_specs'].include? 'display_pixel_ratio'
    assert reply['hd_specs'].include? 'display_ppi'
    assert reply['hd_specs'].include? 'benchmark_min'
    assert reply['hd_specs'].include? 'benchmark_max'
  end

  # Detection test user-agent has been encoded with plus for space.
  # @group community
  #
  def test_ultimate_community_device_detect_http_plus_for_space
    headers = {
      'user-agent' => 'Mozilla/5.0+(Linux;+Android+5.1.1;+SM-J110M+Build/LMY48B;+wv)+AppleWebKit/537.36+(KHTML,+like+Gecko)+Version/4.0+Chrome/47.0.2526.100+Mobile+Safari/537.36',
    }

    result = @hd.device_detect headers
    reply = @hd.get_reply
    assert result
    assert_equal 'Samsung', reply['hd_specs']['general_vendor']
    assert_equal 'SM-J110M', reply['hd_specs']['general_model']
    assert_equal 'Android', reply['hd_specs']['general_platform']
    assert_equal '5.1.1', reply['hd_specs']['general_platform_version']
    assert_equal '', reply['hd_specs']['general_type']
  end

  # iPhone 5s running Facebook 9.0 app (hence no general_browser set).
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_http_fb_ios
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
    assert_equal '', reply['hd_specs']['general_type']
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
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_bi_android
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
    assert_equal '', reply['hd_specs']['general_type']
  end

  # iPhone 4S Native
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_bi_ios
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
    assert_equal '', reply['hd_specs']['general_type']
  end

  # Windows Phone Native Nokia RM-875
  # @depends test_ultimate_community_fetchArchive
  # @group community
  #
  def test_ultimate_community_device_detect_windows_phone
    build_info = {
      'devicemanufacturer' => 'nokia',
      'devicename' => 'RM-875'
    }

    @hd.device_detect build_info
    reply = @hd.get_reply

    assert_equal 'Nokia', reply['hd_specs']['general_vendor']
    assert_equal 'RM-875', reply['hd_specs']['general_model']
    assert_equal 'Windows Phone', reply['hd_specs']['general_platform']
    assert_equal '', reply['hd_specs']['general_type']
    assert_equal 0, reply['hd_specs']['display_ppi']
  end
end
