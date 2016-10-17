# Handset Detection - API call examples
 
require 'handset_detection'
require 'yaml'

config_file = 'hdconfig.yml'

# Ensure config file is set up.

unless File.exist? config_file
  abort 'Config file not found'
end

config = YAML::load_file config_file
if config['username'] == 'your_api_username'
  abort 'Please configure your username, secret and site_id'
end

hd = HD4.new config_file

# Vendors example: Get a list of all vendors

puts 'Vendors'
puts
if hd.device_vendors
  data = hd.get_reply
  p data
else
  p hd.get_error
end
puts

# Models example: Get a list of all models for a specific vendor

puts 'Nokia Models'
puts
if hd.device_models 'Nokia'
  data = hd.get_reply
  p data
else
  p hd.get_error
end
puts

# View information for a specific handset

puts 'Nokia N95 Properties'
puts
if hd.device_view 'Nokia', 'N95'
  data = hd.get_reply
  p data
else
  p hd.get_error
end
puts

# What handset has this attribute?

puts 'Handsets with Network CDMA'
puts
if hd.device_what_has 'network','CDMA'
  data = hd.get_reply
  p data
else
  p hd.get_error
end
puts

# This example sets the headers that a Nokia N95 would set.
# Other agents you also might like to try
# Mozilla/5.0 (BlackBerry; U; BlackBerry 9300; es) AppleWebKit/534.8+ (KHTML, like Gecko) Version/6.0.0.534 Mobile Safari/534.8+
# Mozilla/5.0 (SymbianOS/9.2; U; Series60/3.1 NokiaN95-3/20.2.011 Profile/MIDP-2.0 Configuration/CLDC-1.1 ) AppleWebKit/413
# Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5
 
puts 'Simple Detection - Setting Headers for an N95'
puts
hd.set_detect_var 'user-agent', 'Mozilla/5.0 (SymbianOS/9.2; U; Series60/3.1 NokiaN95-3/20.2.011 Profile/MIDP-2.0 Configuration/CLDC-1.1 ) AppleWebKit/413'
hd.set_detect_var 'x-wap-profile', 'http://nds1.nds.nokia.com/uaprof/NN95-1r100.xml'
if hd.device_detect
  data = hd.get_reply
  p data
else
  p hd.get_error
end
puts

# Query for some other information (remember, the N95 headers are still set).
# Add detection options to query for additional information, such as GeoIP information
# Note : We use 'ipaddress' to get the GeoIP location.

puts 'Simple Detection - Passing a different IP address'
puts
hd.set_detect_var 'ipaddress', '64.34.165.180'
if hd.device_detect({'options' => 'geoip,hd_specs'})
  data = hd.get_reply
  p data
else
  p hd.get_error
end
puts

# Ultimate customers can also download the ultimate database.

puts 'Archive Information'
puts
time_start = Time.now.to_f 
hd.set_timeout 500
if hd.device_fetch_archive
  data = hd.get_raw_reply
  puts "Downloaded #{data.length} bytes"
else
  p hd.get_error
  p hd.get_raw_reply
end
time_elapsed = Time.now.to_f - time_start
puts "Time elapsed: #{time_elapsed} sec"
puts
