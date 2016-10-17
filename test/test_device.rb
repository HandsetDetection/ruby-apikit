require 'minitest/autorun'
require 'minitest/hooks/test'
require 'handset_detection'
require 'fileutils'

# The device class performs the same functions as our Cloud API, but locally.
# It is only used when use_local is set to true in the config file.
# To perform tests we need to setup the environment by populating the the Storage layer with device specs.
# So install the latest community edition so there is something to work with.
#
class DeviceTest < Minitest::Test 
  include Minitest::Hooks

  # Setup community edition for tests. Takes 60s or so to download and install.
  #
  def before_all
    super
    config = YAML::load_file 'hd4_ci_config.yml'
    Dir.mkdir '/tmp/hd4-device-test' unless File.exist?('/tmp/hd4-device-test')
    config['filesdir'] = '/tmp/hd4-device-test' 
    config['cache'] = {'prefix' => 'hd4-device-test'}
    config['use_local'] = true 
    @hd4 = HD4.new config 
    @hd4.community_fetch_archive
  end

  def after_all
    super
    FileUtils.rm_r '/tmp/hd4-device-test'
  end

  def teardown
    @hd4.cache.purge
  end

  def test_is_helper_useful
    device = Device.new 

    headers = { 
      'User-Agent' => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3 like Mac OS X; en-gb) AppleWebKit/533.17.9 (KHTML, like Gecko)'
    }
    result = device.is_helper_useful headers
    assert result

    headers = { 
      'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
    }
    result = device.is_helper_useful headers
    refute result
  end
end
