require 'minitest/autorun'
require 'handset_detection'
require 'yaml'

class CacheNoneTest < Minitest::Test 

  def setup
    @volume_test = 10000
    @test_data = { 
      'roses' => 'red',
      'fish' => 'blue',
      'sugar' => 'sweet',
      'number' => 4
      }
    config = YAML::load_file 'hd4_ci_config.yml'
    config['cache'] = {}
    config['cache']['prefix'] = 'test-cache'
    config['cache']['none'] = {} 
    @cache = Cache.new(config)
  end

  def teardown
    @cache.purge
  end

  def test_basic
    now = Time.now.to_f

    # Test Write & Read
    @cache.write now.to_s, @test_data
    reply = @cache.read now.to_s
    refute reply

    # Test Flush
    reply = @cache.purge
    refute reply
    reply = @cache.read now.to_s
    refute reply
  end

  def test_volume
    time_now = Time.now.to_f

    for i in 0..@volume_test
      key = 'test' + time_now.to_s + i.to_s

      # Write
      reply = @cache.write key, @test_data
      refute reply

      # Read
      reply = @cache.read key
      refute reply

      # Delete
      reply = @cache.delete key
      refute reply

      # Read
      reply = @cache.read key
      refute reply
    end
  end
end
