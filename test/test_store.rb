require 'minitest/autorun'
require 'handset_detection'
require 'fileutils'

class StoreTest < Minitest::Test 
  def setup
    @test_data = { 
      'roses' => 'red',
      'fish' => 'blue',
      'sugar' => 'sweet',
      'number' => 4
    }
    @config = YAML::load_file 'hd4_ci_config.yml'
    @config['cache'] = {} unless @config.include? 'cache'
    @config['cache']['prefix'] = 'hd4-store-test'
    @config['filesdir'] = '/tmp/hd4-store-test'
    @store = Store::get_instance
    @store.set_config(@config, true)
  end

  def teardown
    cache = Cache.new @config 
    cache.purge
    FileUtils.rm_r '/tmp/hd4-store-test'
  end

  # Writes to store & cache
  def test_read_write
    key = 'storekey' + Time.now.to_f.to_s
    @store.write key, @test_data

    data = @store.read key
    assert_equal @test_data, data

    cache = Cache.new @config
    data = cache.read key
    assert_equal @test_data, data

    assert File.file? File.join(@store.directory, "#{key}.json")
  end

  # Writes to store & not cache
  def test_store_fetch
    key = 'storekey' + Time.now.to_f.to_s
    @store.store key, @test_data

    cache = Cache.new @config
    data = cache.read key
    assert_nil data

    data = @store.fetch key
    assert_equal @test_data, data

    assert File.file? File.join(@store.directory, "#{key}.json")
  end

  # Test purge
  def test_purge
    key = 'storekey' + Time.now.to_f.to_s
    @store.write key, @test_data

    files = Dir.glob File.join(@store.directory, '*.json')
    refute files.blank?
    
    @store.purge

    files = Dir.glob File.join(@store.directory, '*.json')
    assert files.blank?
  end

  # Reads all devices from Disk (Keys need to be in Device*json format)
  def test_fetch_devices
    key = 'Device' + Time.now.to_f.to_s
    @store.store key, @test_data

    devices = @store.fetch_devices
    assert_equal devices['devices'][0], @test_data
  end

  # Moves a file from disk into store (vanishes from previous location).
  def test_move_in_fetch
    tmp_data = '{"Device":{"_id":"3454","hd_ops":{"is_generic":0,"stop_on_detect":0,"overlay_result_specs":0},"hd_specs":{"general_vendor":"Sagem","general_model":"MyX5-2","general_platform":"","general_image":"","general_aliases":"","general_eusar":"","general_battery":"","general_type":"","general_cpu":"","design_formfactor":"","design_dimensions":"","design_weight":0,"design_antenna":"","design_keyboard":"","design_softkeys":"","design_sidekeys":"","display_type":"","display_color":"","display_colors":"","display_size":"","display_x":"128","display_y":"160","display_other":"","memory_internal":"","memory_slot":"","network":"","media_camera":"","media_secondcamera":"","media_videocapture":"","media_videoplayback":"","media_audio":"","media_other":"","features":"","connectors":"","general_platform_version":"","general_browser":"","general_browser_version":"","general_language":"","general_platform_version_max":"","general_app":"","general_app_version":"","display_ppi":0,"display_pixel_ratio":0,"benchmark_min":0,"benchmark_max":0,"general_app_category":"","general_virtual":0,"display_css_screen_sizes":""}}}'
    File.open('Device_3454.json', 'w') { |f| f.write(tmp_data) }
    @store.move_in 'Device_3454.json', 'Device_3454.json'
    refute File.file? 'Device_3454.json'
    assert File.file? File.join(@store.directory, 'Device_3454.json')

    tmp_data = '{"Device":{"_id":"3455","hd_ops":{"is_generic":0,"stop_on_detect":0,"overlay_result_specs":0},"hd_specs":{"general_aliases":"","display_x":"120","display_y":"120","general_vendor":"Sagem","general_model":"MY X55","general_platform":"","general_image":"","network":"","general_type":"","general_eusar":"","general_battery":"","general_cpu":"","design_formfactor":"","design_dimensions":"","design_weight":0,"design_antenna":"","design_keyboard":"","design_softkeys":"","design_sidekeys":"","display_type":"","display_color":"","display_colors":"","display_size":"","display_other":"","memory_internal":"","memory_slot":"","media_camera":"","media_secondcamera":"","media_videocapture":"","media_videoplayback":"","media_audio":"","media_other":"","features":"","connectors":"","general_platform_version":"","general_browser":"","general_browser_version":"","general_language":"","general_platform_version_max":"","general_app":"","general_app_version":"","display_ppi":0,"display_pixel_ratio":0,"benchmark_min":0,"benchmark_max":0,"general_app_category":"","general_virtual":0,"display_css_screen_sizes":""}}}'
    File.open('Device_3455.json', 'w') { |f| f.write(tmp_data) }
    @store.move_in 'Device_3455.json', 'Device_3455.json'

    tmp_data = '{"Device":{"_id":"3456","hd_ops":{"is_generic":0,"stop_on_detect":0,"overlay_result_specs":0},"hd_specs":{"general_vendor":"Sagem","general_model":"myX5-2v","general_platform":"","general_image":"","general_aliases":"","general_eusar":"","general_battery":"","general_type":"","general_cpu":"","design_formfactor":"","design_dimensions":"","design_weight":0,"design_antenna":"","design_keyboard":"","design_softkeys":"","design_sidekeys":"","display_type":"","display_color":"","display_colors":"","display_size":"","display_x":"128","display_y":"160","display_other":"","memory_internal":"","memory_slot":"","network":"","media_camera":"","media_secondcamera":"","media_videocapture":"","media_videoplayback":"","media_audio":"","media_other":"","features":"","connectors":"","general_platform_version":"","general_browser":"","general_browser_version":"","general_language":"","general_platform_version_max":"","general_app":"","general_app_version":"","display_ppi":0,"display_pixel_ratio":0,"benchmark_min":0,"benchmark_max":0,"general_app_category":"","general_virtual":0,"display_css_screen_sizes":""}}}'
    File.open('Device_3456.json', 'w') { |f| f.write(tmp_data) }
    @store.move_in 'Device_3456.json', 'Device_3456.json'

    devices = @store.fetch_devices
    assert_equal 3, devices['devices'].length
  end

# Test singleton'ship
  def test_singleton
    @store.set_config({'filesdir' => '/tmp/storetest'})

    other_store = Store::get_instance
    assert_equal other_store.directory, '/tmp/storetest/hd40store'
  end
end
