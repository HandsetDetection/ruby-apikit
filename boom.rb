require 'handset_detection'
require 'yaml'

config_file = 'hd4_ci_config.yml'

config = YAML::load_file config_file 
config['use_local'] = true
hd = HD4.new config
hd.set_timeout 500
hd.device_fetch_archive

File.readlines('test.txt').each do |line|

  hd.device_detect({'user-agent' => line})

end
