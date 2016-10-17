Gem::Specification.new do |s|
  s.name        = 'handset_detection'
  s.version     = '0.1.1'
  s.date        = '2016-09-07'
  s.summary     = 'API kit for HandsetDetection.com'
  s.description = 'Use the HandsetDetection.com API from Ruby.'
  s.authors     = ['Handset Detection']
  s.email       = 'hello@handsetdetection.com'
  s.files       = ['lib/handset_detection.rb'] + Dir['lib/handset_detection/*'] + Dir['lib/handset_detection/cache/*']
  s.homepage    = 'https://github.com/HandsetDetection/ruby-apikit/'
  s.license     = 'MIT'
end
